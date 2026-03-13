<#
.DESCRIPTION
	Shows readable report on npm audit
.PARAMETER name
	Apply script only for specified repository name or for current working directory if nothing specified
.PARAMETER quiet
	Whether to not output current repository and branch name
#>

Param (
	[string]$name,
	[switch]$quiet
)

Import-Module $env:MODULES_ROOT\npm.ps1 -Force

$severity_colors = @{
	critical = "Red"
	high     = "DarkYellow"
	moderate = "Yellow"
	low      = "Green"
	info     = "Cyan"
}

repo -name $name -quiet:$quiet -action {
	$json = npm audit --json | ConvertFrom-Json

	if (-not $json.vulnerabilities) {
		out "{Green:No vulnerabilities found}"
		exit
	}

	$found = $false

	$json.vulnerabilities.PSObject.Properties | % {
		$name = $_.Name
		$range = $_.Value.range
		$severity = $_.Value.severity
		$color = $severity_colors[$severity]
		$fix_label = if ($_.Value.fixAvailable) { "[fix available]"} else { "" }
		$found = $true

		out "{$($color):[$severity] $name} {DarkGray:is vulnerable in} {$($color):$range} {Magenta:$fix_label}"

		FindDependencyUsages $repo $name $range | % {
			out "    {White:$($_.version)} {DarkGray:from} $($_.name)"
		}
	}

	if (!$found) {
		out "{Green:No vulnerabilities}"
	}
}
