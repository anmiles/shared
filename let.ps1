<#
.SYNOPSIS
    Creates process-wide environment variable
.EXAMPLE
	let.ps1 VAR1=value1 VAR2=value2 npm run command
#>

$cmd = @()
$envars = @()
$new_envars = @()
$existing_envars = $env:ENVARS -split ","
$existing_variables = [Environment]::GetEnvironmentVariables()

$args | % {
	$match = [Regex]::Match($_, '^([A-Z0-9_]+)\s*=\s*(.*?)\s*$')

	if ($match.Success) {
		$name = $match.Groups[1].Value
		$value = $match.Groups[2].Value
		[Environment]::SetEnvironmentVariable($name, $value, "Process")
		$new_envars += @($name)
	} else {
		$cmd += $_
	}
}

$envars = ($existing_envars + $new_envars) | Get-Unique

[Environment]::SetEnvironmentVariable("ENVARS", ($envars -join ","), "Process")

sh ($cmd -join " ")

[Environment]::SetEnvironmentVariable("ENVARS", ($existing_envars -join ","), "Process")

$new_envars | % {
	$name = $_
	[Environment]::SetEnvironmentVariable($name, ($existing_variables | ? { $_.Name -eq $name }).Value, "Process")
}
