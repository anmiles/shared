<#
.SYNOPSIS
    Show all paths in PATH environment variable
.PARAMETER grep
    Whether to grep by specified expression
#>

Param (
    [string]$grep = "."
)

$prev_root = ""
$prev_dir = ""
$colors = @(2, 4, 6, 3, 5)
$root_color_index = 0
$dir_color = $false

"----------------------------------------"
$env:PATH -split ";" | Sort | ? { $_ } | grep -i $grep | % {
	$root = ($_ -split '\\' | Select -First 2) -join "\"
	$dir = ($_ -split '\\' | Select -First 3) -join "\"

	if ($prev_root -and $prev_root -ne $root) {
		$root_color_index ++
		$dir_color = $false
	}

	if ($prev_dir -ne $dir) {
		$dir_color = !$dir_color
	}

	$prev_root = $root
	$prev_dir = $dir
	$root_color = $colors[$root_color_index % $colors.Length]
	if ($dir_color) { $root_color += 8 }

	Write-Host $_ -ForegroundColor $root_color
}
"----------------------------------------"
