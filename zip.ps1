<#
.SYNOPSIS
    Zip directory
.DESCRIPTION
    Create zip archive from directory using 7zip, place archive together and return its full path
.PARAMETER src
    Source directory. If not specified, current working directory used
.PARAMETER dst
    Archive. If not specified, current working directory + ".zip"
.EXAMPLE
    zip 
    # create zip archive $directoryname.zip using 7z where $directoryname is name of current working directory and returns full path to $directoryname.zip
.EXAMPLE
    zip .\samples\first
    # create zip archive .\samples\first.zip using 7z and returns full path to .\samples\first.zip 
#>

Param (
    [string]$src,
    [string]$dst
)

$path = switch($src){ "" { $PWD } default { Resolve-Path $src }}

$directory = $path.Path
if (!$dst) { $dst = "$directory.zip" }

Push-Location $directory
Start-Process -FilePath "C:\ProgramData\chocolatey\bin\7z.exe" -ArgumentList "a -y -r -bso0 -bsp0 -mx=0 $dst ." -Wait -NoNewWindow
Pop-Location
$archive
