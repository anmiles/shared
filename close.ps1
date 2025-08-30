<#
.SYNOPSIS
    Close window with specified title
#>

Param (
    [string]$title
)

$wShell = New-Object -ComObject WScript.Shell
$handle = window $title

if ($handle -ne 0) {
    $wShell.AppActivate($title)
    $wShell.SendKeys('%{F4}')
    exit 0
} else {
    exit 1
}
