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

if ($text -and ($text.Trim() -or $NoNewline)) {
    Write-Host (fmt $text $ForegroundColor -parse) -NoNewline

    if ($underline) {
        Write-Host ""
        Write-Host ""
        Write-Host (fmt ("-" * [console]::WindowWidth) $ForegroundColor -parse)
    }
}

Write-Host "" -NoNewline:$NoNewline
