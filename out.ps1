<#
.SYNOPSIS
    Outputs colored text
.PARAMETER NoNewline
    Do not end the line
.PARAMETER underline
    Draw underline
.PARAMETER ForegroundColor
    Default foreground color
.EXAMPLE
    out "{Red:FAILED} {Yellow:$url} : redirect is {Red:circular} but expected {Green:$redirect}" -ForegroundColor Cyan
#>

Param (
    [string]$text,
    [switch]$NoNewline,
    [switch]$underline,
    [ConsoleColor]$ForegroundColor = "Gray"
)

$length = 0

if ($text -and ($text.Trim() -or $NoNewline)) {
    $text -split "(\{[A-Za-z]+:[^\}]*\})" | % {
        if ($_ -match "\{([A-Za-z]+):([^\}]*)\}") {
            $length += $matches[2].Length
            Write-Host $matches[2] -NoNewLine -ForegroundColor $matches[1]
        } else {
            $length += $_.Length
            Write-Host $_ -NoNewLine -ForegroundColor $ForegroundColor
        }
    }

    if ($underline) {
        Write-Host ""
        Write-Host ""
        Write-Host ("-" * $length) -ForegroundColor $ForegroundColor -NoNewline:$NoNewline
    }
}

Write-Host "" -NoNewline:$NoNewline
