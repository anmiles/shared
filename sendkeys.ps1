<#
.SYNOPSIS
    Maximize window with specified title
.PARAMETER title
    Window title
.PARAMETER keys
    Keys to send
#>

Param (
    [string]$title,
    [string]$keys
)

$wShell = New-Object -ComObject WScript.Shell
$handle = window $title

if ($handle -ne 0) {
    $wShell.AppActivate($title)
    $wShell.SendKeys($keys)
    exit 0
} else {
    exit 1
}
