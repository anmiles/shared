<#
.SYNOPSIS
    Add record to the changelog
.PARAMETER mode
    Mode for `npm version` command
.PARAMETER added
    What was added
.PARAMETER changed
    What was changed
.PARAMETER removed
    What was removed
.EXAMPLE
    changelog minor -added "Add feature1" "Add feature2" -changed "Change feature3" -removed "Removed feature4"
#>

Param (
    [Parameter(Mandatory = $true)][string]$mode,
    [string]$name = "this",
    [string[]]$added,
    [string[]]$changed,
    [string[]]$removed
)

$modes = @("major", "minor", "patch")

if (!($modes.Contains($mode))) {
	throw "Expected `$mode to be one of [ $modes ], received '$mode'";
}

repo -name $name -quiet -action {
	$filename = "CHANGELOG.md"
	$file = Join-Path $repo $filename

	if (!(Test-Path $file)) {
		"No $filename in $repo"
	}

	$contents = file $filename
	$parts = $contents -split '(\n## \[\d+\.\d+\.\d+\])'
	$parts[1] -match '\[(\d+)\.(\d+)\.(\d+)\]' | Out-Null

	$last_version = @{
		major = [int]$matches[1]
		minor = [int]$matches[2]
		patch = [int]$matches[3]
	}

	$last_version[$mode] = $last_version[$mode] + 1

	for ($i = $modes.indexOf($mode) + 1; $i -lt $modes.Length; $i ++) {
		$last_version[$modes[$i]] = 0
	}

	$last_version_string = "$($last_version.major).$($last_version.minor).$($last_version.patch)"
	$date_string = (Get-Date).ToString("yyyy-MM-dd")

	$new_part = @()
	$new_part += "## [$last_version_string](../../tags/v$last_version_string) - $date_string"

	if ($added) {
		$new_part += "### Added"
		$added | % { $new_part += "- $_" }
	}

	if ($changed) {
		$new_part += "### Changed"
		$changed | % { $new_part += "- $_" }
	}

	if ($removed) {
		$new_part += "### Removed"
		$removed | % { $new_part += "- $_" }
	}

	$head, $all_parts = $parts
	$output = ($head, ($new_part -Join "`n"), ($all_parts -Join "")) -Join "`n"
	file $filename $output
}
