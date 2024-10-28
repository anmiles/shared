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
.PARAMETER hsplit
    Split video into 2 videos horizontally using selected ratio. Ignores parameters: colorize, crop, scale, rate.
.PARAMETER vsplit
    Split video into 2 videos vertically using selected ratio. Ignores parameters: colorize, crop, scale, rate.
.PARAMETER hstack
    Stack video horizontally with another video. Ignores all other parameters.
.PARAMETER vstack
    Stack video vertically with another video. Ignores all other parameters.
.PARAMETER timestamp
    Whether to use current time to generate target filename rather than re-using source filename with adding prefix before it.
.PARAMETER novideo
    Whether to not include video stream
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
.PARAMETER silent
    Less verbose output
.EXAMPLE
    cut "D:\video.avi" 32 1:42
    # cuts video D:\video.avi from 32 seconds to 1 minute 42 seconds and sets output filename the source filename without prefix and with extension "ext"
.EXAMPLE
    cut "D:\video.avi" -hsplit 2:1
    # splits video D:\video.avi horizontally into 2 videos: left video of 2x width and right video of 1x width
#>

Param (
    [Parameter(Mandatory = $true)][string]$source,
    [string]$start,
    [string]$end,
    [int]$height = 0,
    [string]$prefix,
    [string]$ext,
    [float]$rate = 1,
    [string]$filters = "",
    [int]$audio = 0,
    [string]$hsplit,
    [string]$vsplit,
    [string]$hstack,
    [string]$vstack,
    [switch]$crop,
    [switch]$timestamp,
    [switch]$novideo,
    [switch]$mute,
    [switch]$vcopy,
    [switch]$acopy,
    [switch]$colorize,
    [switch]$colorize2,
    [switch]$silent
)

Function GetTimeSpan {
    param ([string]$str, [int]$default)

    if ($str -eq $null -or $str.Length -eq 0) { return New-TimeSpan -Seconds $default }

    switch (($str -split ":").Length) {
        1 { return New-TimeSpan -Start "0:0:0" -End "0:0:$str" }
        2 { return New-TimeSpan -Start "0:0:0" -End "0:$str" }
        3 { return New-TimeSpan -Start "0:0:0" -End $str }
        default { throw "Expected formats: '%d', '%d:%d', '%d:%d:%d', found $str with $parts parts"}
    }
}

Function GetStamp($int) {
    Write-Host ($int % 60)
}

$framerate = [Math]::Floor(25 * $rate)

$exts_audio = @(".aac", ".am4", ".cda", ".flac", ".m4a", ".mp3", ".ogg", ".wav", ".wma")
$ext_default_video = ".mp4"
$ext_default_audio = ".mp3"

$inputs = Get-Item $source
if (!$inputs) { $inputs = Get-Item -LiteralPath $source -Force }

if (!$ext -and $inputs.Count -gt 0) {
    $ext = $ext_default_video
    $filename_ext = [System.IO.Path]::GetExtension($inputs[0])

    if ($exts_audio.Contains($filename_ext)) {
        $novideo = $true
    }

    if ($novideo) {
        $ext = $ext_default_audio
    }
}

if ($inputs.Count -eq 0) {
    out "{Red:There are no files matched to $source}"
    exit 1
}

$concat = $inputs.Count -gt 1

$input = $inputs[0]
$input_filename = $input.FullName
$output_filename = $input.FullName

if ($concat) {
    $start_timespan = $null
    $length = $null

    $cwd = Split-Path $input_filename -Parent
    $list_filename = $input_filename.Replace($input.Name, "ffmpeg.txt")
    $input_content = ($inputs | Sort { [regex]::Replace($_, '\d+', { $args[0].Value.PadLeft(20) }) } | % { "file $($_.FullName.Replace($cwd, '').Replace('\', '/') -replace '^\/', '')" }) -join "`n"
    file $list_filename $input_content
} else {
    $ffprobe = $(ffprobe -v error -show_entries stream=width,height,duration -of csv=s=,:p=0 $input_filename) | ? { $_ -ne "N/A" } | Sort
    $duration = [int]($ffprobe | ? { $_ -match "^\d+(\.\d+)?$" })
    if (!$duration) { $duration = [int]((($ffprobe | ? {$_ -match ","}) -split ",")[2]) }
    $width_original = [int]((($ffprobe | ? {$_ -match ","}) -split ",")[0])
    $height_original = [int]((($ffprobe | ? {$_ -match ","}) -split ",")[1])

    $start_timespan = GetTimeSpan -str $start -default 0
    $end_timespan = GetTimeSpan -str $end -default $duration
    $length = $end_timespan - $start_timespan
}

if ($timestamp) {
    $output_filename = $output_filename.Replace($input.Name, $prefix + $input.LastWriteTime.ToString("yyyy.MM.dd_HH.mm.ss.fff"))
} else {
    $output_filename = $output_filename.Replace($input.Name, $prefix + $input.Name)
    $output_filename = $output_filename.Replace($input.Extension, "")
}

$output_filename = $output_filename + $ext

while (Test-Path -LiteralPath $output_filename) {
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

if ($hstack) {
    $params += @("-i", "`"$input_filename`"")
    $params += @("-i", "`"$hstack`"")
    $params += @("-filter_complex", "hstack=inputs=2")
}

if ($vstack) {
    $params += @("-i", "`"$input_filename`"")
    $params += @("-i", "`"$vstack`"")
    $params += @("-filter_complex", "vstack=inputs=2")
}

if (!$hstack -and !$vstack) {
    if ($start_timespan) { $params += @("-ss", $start_timespan) }
    if ($concat) { $params += @("-f", "concat", "-safe", "0", "-i", "`"$list_filename`"") }
    else { $params += @("-i", "`"$input_filename`"") }

    if ($audio) { $params += @("-map", "0:v:0", "-map", "0:a:$audio") }

    if ($novideo) {
        $params += "-vn"
    } else {
        if ($vcopy) { $params += @("-vcodec", "copy") }
        else { $params += @("-vcodec", "h264") }

        if ($filters -and !$hsplit -and !$vsplit) { $params += "-vf $filters" }
        $params += @("-pix_fmt", "yuv420p")
    }

    if ($mute) {
        $params += "-an"
    } else {
        if ($acopy) { $params += @("-acodec", "copy") }
        else { $params += @("-acodec", "aac", "-b:a", "320k", "-ar", "44100") }
    }

    if ($length) { $params += @("-t", $length) }
}

if ($hsplit) {
    $splits = $hsplit -split ":"
    $ratio0 = "$($splits[0])/$([float]$splits[0] + [float]$splits[1])"
    $ratio1 = "$($splits[1])/$([float]$splits[0] + [float]$splits[1])"
    $filter_complex = "[0]crop=iw*$($ratio0):ih:0:0[left];[0]crop=iw*$($ratio1):ih:ow:0[right]"
    $output_filename_0 = $output_filename.Replace($ext, "_left" + $ext)
    $output_filename_1 = $output_filename.Replace($ext, "_right" + $ext)
    $params += @("-filter_complex", $filter_complex, "-map", "[left]", "`"$output_filename_0`"", "-map", "[right]", "`"$output_filename_1`"")
}

if ($vsplit) {
    $splits = $vsplit -split ":"
    $ratio0 = "$($splits[0])/$([float]$splits[0] + [float]$splits[1])"
    $ratio1 = "$($splits[1])/$([float]$splits[0] + [float]$splits[1])"
    $filter_complex = "[0]crop=iw:ih*$($ratio0):0:0[top];[0]crop=iw:ih*$($ratio1):0:oh[bottom]"
    $output_filename_0 = $output_filename.Replace($ext, "_top" + $ext)
    $output_filename_1 = $output_filename.Replace($ext, "_bottom" + $ext)
    $params += @("-filter_complex", $filter_complex, "-map", "[top]", "`"$output_filename_0`"", "-map", "[bottom]", "`"$output_filename_1`"")
}

if ($silent) {
    $params += @("-loglevel", "error")
}

if (!$hsplit -and !$vsplit) {
    $params += "`"$output_filename`""
}

if (!$silent) {
    Write-Host "ffmpeg $params" -ForegroundColor Yellow
    Write-Host "$input_filename => $output_filename" -ForegroundColor Green
}

Start-Process cmd -ArgumentList "/c ffmpeg $params" -NoNewWindow -Wait
# if ($concat) { Remove-Item $input_filename }

if (!$silent) {
    Write-Host $output_filename -ForegroundColor Green
}
