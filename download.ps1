<#
.SYNOPSIS
    Download file by url specified
.PARAMETER urlfile
    Text file containing all download URLs separated by line break
.PARAMETER directory
    Directory where to download files
#>

Param (
    [Parameter(Mandatory = $true)][string]$urlfile,
    [Parameter(Mandatory = $true)][string]$directory
)

Import-Module $env:MODULES_ROOT\progress.ps1 -Force

$invalidFilenameChars = [Regex]::new("/[<>:`"/\|?*]*/", [System.Text.RegularExpressions.RegexOptions]::Compiled)
$urls = Get-Content $urlfile | ? { ![string]::IsNullOrWhiteSpace($_) } | % { $_.Trim()}
$progress = Start-Progress -count $urls.Length -title "Download"
$i = 0

$options = @{
    replaceAll = $false
    skipAll = $false
}

$urls | % {
    $i ++
    $url = $_
    $progress.Tick()
    $url
    [console]::SetCursorPosition([console]::CursorLeft, [console]::CursorTop - 1)
    $outFile = Join-Path $directory $invalidFilenameChars.Replace([System.Web.HttpUtility]::UrlDecode($_.Split('/')[-1]), "-").Replace('[', '(').Replace(']', ')');

    if (Test-Path $outFile) {
        if ($options.replaceAll) {
            Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
        } else {
            if (!$options.skipAll) {
                $answer = confirm "File $outFile already exists, overwrite" -extended

                if ($answer.result) {
                    Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
                }

                if ($answer.all) {
                    $options.replaceAll = $answer.result
                    $options.skipAll = !$answer.result
                }
            }
        }
    } else {
        Invoke-WebRequest -Uri $url -OutFile $outFile -UseBasicParsing
    }
}

out "{Green:Done!}"
