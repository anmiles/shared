<#
.SYNOPSIS
    Creates process-wide environment variable
.EXAMPLE
	export.ps1 VAR=value
#>

Param (
    [Parameter(Mandatory = $true)][string]$expression
)

$match = [Regex]::Match($expression, '^([^=]+)\s*=\s*(.*?)\s*$')

if (!$match.Success) {
	throw "Expected format: export VAR=value"
}

$name = $match.Groups[1]
$value = $match.Groups[2]

[Environment]::SetEnvironmentVariable($name, $value, "Process")

$envars = $env:ENVARS -split ","
$envars = $envars | ? { $_ -ne $name }

if ($value.Length -gt 0) {
	$envars += @($name)
}

[Environment]::SetEnvironmentVariable("ENVARS", ($envars -join ","), "Process")
