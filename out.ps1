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
    Write-Host (fmt $text $ForegroundColor) -NoNewline

    if ($underline) {
        Write-Host ""
        Write-Host ""
        Write-Host (fmt ("-" * $length) $ForegroundColor)
    }
}

Write-Host "" -NoNewline:$NoNewline
