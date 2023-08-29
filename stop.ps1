<#
.SYNOPSIS
    Stop process with specified name
#>

Param (
    [string]$name
)

taskkill /f /im "$name.exe"
