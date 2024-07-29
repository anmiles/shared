<#
.DESCRIPTION
	Create gpx map from photo geotags
.PARAMETER path
	Optional path where to get photos from

#>

Param (
	[string]$path
)

if ($path) { Push-Location $path }

exiftool -r -p $PSScriptRoot\gpx.fmt . > points.gpx

out "{Green:Done!}"
if ($path) { Pop-Location }
