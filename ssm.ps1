<#
.SYNOPSIS
    Put SSM parameter
.PARAMETER name
    Parameter name
.PARAMETER value
    Parameter value
#>

Param (
    [Parameter(Mandatory = $true)][string]$name,
    [Parameter(Mandatory = $true)][string]$value
)

aws ssm put-parameter --type SecureString --name $name --value $value
