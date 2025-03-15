<#
.DESCRIPTION
    Output message in yellow and wait any key for continue
.PARAMETER message
    Wait message
#>

Param (
    [Parameter(Mandatory = $true)][string]$message
)

out $message Yellow -NoNewline
[void](Read-Host)
