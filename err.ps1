<#
.SYNOPSIS
    Output red message and exit 1
.PARAMETER exitCode
    Custom exit code
.PARAMETER keep
    Do not exit
#>

Param (
    [string]$text,
    [int]$exitCode = 1,
    [switch]$keep
)

out $text -ForegroundColor Red
if (!$keep) { exit $exitCode }
