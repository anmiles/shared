<#
.SYNOPSIS
    Cuts the video
.PARAMETER source
    File to convert. If multiple files is matched (according to "*") then use "concat" mode and ignore "start", "end" and "prefix" parameters and set "timestamp" to true
.PARAMETER start
    Start of cut (may be in format "ss", "mm:ss" or "hh:mm:ss"). Ignored if concat mode (see "source" parameter)
.PARAMETER end
    End of cut (may be in format "ss", "mm:ss" or "hh:mm:ss"). Ignored if concat mode (see "source" parameter)
.PARAMETER height
    Target height
.PARAMETER prefix
    Prefix to add before converted filename. Ignored if concat mode (see "source" parameter)
.PARAMETER ext
    Target extension
.PARAMETER rate
    Speed up or slow down
.PARAMETER filters
    Video filters
.PARAMETER audio
    Select audio stream to copy. By default - skip selecting
.PARAMETER timestamp
    Whether to use current time to generate target filename rather than re-using source filename with adding prefix before it. Always true if concat mode (see "source" parameter)
.PARAMETER mute
    Whether to not include audio stream
.PARAMETER vcopy
    Whether to keep original video codecs
.PARAMETER acopy
    Whether to keep original audio codecs
.PARAMETER colorize
    Apply predefined set of filters to make video more colorized
.PARAMETER colorize2
    Even more colorized
.PARAMETER crop
    Whether to crop video
.EXAMPLE
    cut "D:\video.avi" 32 1:42
    # cuts video D:\video.avi from 32 seconds to 1 minute 42 seconds and sets output filename the source filename with prefix "converted-" and extension "ext"
#>

Param (
    [Parameter(Mandatory = $true)][string]$source,
    [string]$start,
    [string]$end,
    [int]$height = 0,
    [string]$prefix = "converted-",
    [string]$ext,
    [float]$rate = 1,
    [string]$filters = "",
    [int]$audio = 0,
    [switch]$crop,
    [switch]$timestamp,
    [switch]$mute,
    [switch]$vcopy,
    [switch]$acopy,
    [switch]$colorize,
    [switch]$colorize2
)

Function GetTimeSpan {
    param ([string]$str, [int]$default)

    if ($str -eq $null -or $str.Length -eq 0) { return New-TimeSpan -Seconds $default }

    switch (($str -split ":").Length) {
        1 { return New-TimeSpan -Seconds $str }
        2 { return New-TimeSpan -Start "0:0:0" -End "0:$str" }
        3 { return New-TimeSpan -Start "0:0:0" -End $str }
        default { throw "Expected formats: '%d', '%d:%d', '%d:%d:%d', found $str with $parts parts"}
    }
}

Function GetStamp($int) {
    Write-Host ($int % 60)
}

$framerate = [Math]::Floor(25 * $rate)

$exts = @{
    ".mp3" = ".mp3"
    default = ".mp4"
}

$inputs = Get-Item $source
if (!$inputs) { $inputs = Get-Item -LiteralPath $source -Force }

switch ($inputs.Count) {
    0 {
        out "{Red:There are no files matched to $source}"
        exit 1
    }
    1 {
        $input = $inputs[0]
        $input_filename = $input.FullName
        $output_filename = $input_filename

        if (!$ext) {
            $filename_ext = [System.IO.Path]::GetExtension($input)
            $ext = $exts[$filename_ext]

            if (!$ext) {
                $ext = $exts.default
            }
        }

        $ffprobe = $(ffprobe -v error -show_entries stream=width,height,duration -of csv=s=,:p=0 $input_filename) | ? { $_ -ne "N/A" } | Sort
        $duration = [int]($ffprobe | ? {$_ -notmatch ","})
        $width_original = [int]((($ffprobe | ? {$_ -match ","}) -split ",")[0])
        $height_original = [int]((($ffprobe | ? {$_ -match ","}) -split ",")[1])

        $start_timespan = GetTimeSpan -str $start -default 0
        $end_timespan = GetTimeSpan -str $end -default $duration
        $length = $end_timespan - $start_timespan

        if ($timestamp) {
            $output_filename = $output_filename.Replace($input.Name, $prefix + $input.LastWriteTime.ToString("yyyy.MM.dd_HH.mm.ss.fff"))
        } else {
            $output_filename = $output_filename.Replace($input.Name, $prefix + $input.Name)
            $output_filename = $output_filename.Replace($input.Extension, "")
        }
    }
    default {
        $ext = $exts.default
        $start_timespan = $null
        $length = $null
        $concat = $true
        $output_dir = Split-Path $inputs[0] -Parent
        $cwd = (Get-Item .).FullName
        $input_filename = Join-Path $output_dir "ffmpeg.txt"
        $input_content = ($inputs | % { "file $($_.FullName.Replace($cwd, '').Replace('\', '/') -replace '^\/', '')" }) -join "`n"
        Write-Host $input_content
        file $input_filename $input_content
        $output_filename = Join-Path $output_dir (Get-Date).ToString("yyyy.MM.dd_HH.mm.ss.fff")
    }
}

$output_filename = $output_filename + $ext

while (Test-Path $output_filename) {
    $output_filename = [Regex]::Replace($output_filename, '(\((\d+)\))?(\.\w+)$', { param($match) "($([Math]::max(2, [int]$match.Groups[2].Value + 1)))$($match.Groups[3].Value)" })
}

$scale = "scale=iw:ih"
if ($height) { $scale = "scale=-2:$height" }

$default_filters_array = @()

if (!$vcopy) {
    $default_filters_array += "pad=ceil(iw/2)*2:ceil(ih/2)*2"
    $default_filters_array += $scale
    $default_filters_array += "setpts=PTS/$rate"
}

$filters_array = $filters.Split(",")
if ($colorize) { $filters_array += @("eq=saturation=1.3:gamma_b=1.2:gamma_r=1.1") }
if ($colorize2) { $filters_array += @("eq=saturation=1.5:gamma_b=1.4:gamma_r=1.3") }

if ($crop) { $filters_array += @("crop=$(crop $width_original $height_original)") }

$filters = (($default_filters_array + $filters_array) | ? { $_}) -join ","

$params = @()
if ($start_timespan) { $params += @("-ss", $start_timespan) }
if ($concat) { $params += @("-f", "concat", "-safe", "0") }
$params += @("-i", "`"$input_filename`"")
if ($vcopy) { $params += @("-vcodec", "copy") }
    else { $params += @("-vcodec", "h264") }
if ($acopy) { $params += @("-acodec", "copy") }
    else { $params += @("-acodec", "mp3") }
$params += @("-b:a", "320k", "-ar", "44100")
if ($audio) { $params += @("-map", "0:v:0", "-map", "0:a:$audio") }
if ($mute) { $params += "-an" }
if ($filters) { $params += "-vf $filters" }
$params += @("-pix_fmt", "yuv420p")
if ($length) { $params += @("-t", $length) }
$params += "`"$output_filename`""

Write-Host "ffmpeg $params" -ForegroundColor Yellow
Write-Host "$input_filename => $output_filename" -ForegroundColor Green
Start-Process cmd -ArgumentList "/c ffmpeg $params" -NoNewWindow -Wait
if ($concat) { Remove-Item $input_filename }
Write-Host $output_filename -ForegroundColor Green
