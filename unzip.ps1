<#
.SYNOPSIS
    Unzip directory
.DESCRIPTION
    Extract zip archive to directory using 7zip, place directory together and return its full path
.PARAMETER src
    Source archive.
.EXAMPLE
    unzip .\samples\first.zip
    # extract zip archive .\samples\first.zip using 7z and returns full path to .\samples\first
#>

Param (
    [Parameter(Mandatory = $true)][string]$src
)

$path = Resolve-Path $src
$archive = $path.Path
$directory = $archive -replace "\.[A-Za-z0-9]*$", ""
Start-Process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "x -y -r -bso0 -bsp0 $archive -o$directory" -Wait -NoNewWindow
$directory
