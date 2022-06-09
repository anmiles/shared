<#
.SYNOPSIS
    Zip directory
.DESCRIPTION
    Create zip archive from directory using 7zip, place archive together and return its full path
.PARAMETER src
    Source directory. If not specified, current working directory used
.EXAMPLE
    zip 
    # create zip archive $directoryname.zip using 7z where $directoryname is name of current working directory and returns full path to $directoryname.zip
.EXAMPLE
    zip .\samples\first
    # create zip archive .\samples\first.zip using 7z and returns full path to .\samples\first.zip 
#>

Param (
    [string]$src
)

if ($src) {
    $src = Resolve-Path $src
} else {
    $src = $PWD
}

$directory = $src.Path
$archive = "$directory.zip"

$location = Get-Location
Set-Location $directory
Start-Process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "a -y -r -bso0 -bsp0 -mx=0 $archive ." -Wait -NoNewWindow
Set-Location $location
$archive