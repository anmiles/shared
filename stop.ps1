<#
.SYNOPSIS
    Stop process with specified name
#>

Param (
    [string]$name
)

$process = Get-Process | ? { $_.ProcessName -eq $name }

if ($process) {
    taskkill /f /im "$name.exe"
    exit 0
} else {
    exit 1
}
