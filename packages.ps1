<#
.SYNOPSIS
    Get list of all used npm packages in current repository
#>

$packages = @{}

gg 'package\.json' | % {
	$package = (file $_ | ConvertFrom-Json)

	@($package.dependencies, $package.devDependencies) `
		| ? { $_ -and $_.PSObject } `
		| % { $_.PSObject.Properties.Name } `
		| ? { $_.Length -gt 0 } `
		| % {
			$_ | % {
				$name = $_
				if (!$packages[$name]) { $packages[$name] = 0 }
				$packages[$name] ++
			}
		}
}

$packages.Keys | % {
	[PSCustomObject]@{ name = $_; usages = $packages[$_] }
} | Sort -Property @{ Expression = { $_.usages }; Descending = $true}, @{ Expression = { $_.name } }
