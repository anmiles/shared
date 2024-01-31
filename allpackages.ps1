<#
.SYNOPSIS
    Get list of all used npm packages across all repositories
#>

$packages = @{}

repo all -quiet {
	packages | % {
		if (!$packages[$_.name]) { $packages[$_.name] = 0 }
		$packages[$_.name] += $_.usages
	}
}

$packages.Keys | % {
	[PSCustomObject]@{ name = $_; usages = $packages[$_] }
} | Sort -Property @{ Expression = { $_.usages }; Descending = $true}, @{ Expression = { $_.name } }
