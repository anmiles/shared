<#
.SYNOPSIS
    Install all packages
.DESCRIPTION
	Search for projects that have package.json and run npm install on them
.PARAMETER path
	Optional path where to search projects in
.PARAMETER link
	Whether to link package to global modules
#>

Param (
    [string]$path = ".",
    [switch]$link
)

Get-ChildItem $path -Directory | % {
	$package_json = Join-Path $_.FullName "package.json"

	if (Test-Path $package_json) {
		Write-Host "> $($_.Name)" -ForegroundColor Yellow
		Start-Process npm install -WorkingDirectory $_.FullName -Wait -NoNewWindow
		Start-Process npm outdated -WorkingDirectory $_.FullName -Wait -NoNewWindow
		if ($link) { Start-Process npm link -WorkingDirectory $_.FullName -Wait -NoNewWindow }
	}
}
