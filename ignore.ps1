<#
.SYNOPSIS
    Ignore patch
.PARAMETER filename
    Which patch file to ignore
#>

Param (
    [Parameter(Mandatory = $true)][string]$filename
)

Import-Module $env:MODULES_ROOT\patch.ps1 -Force

$command = $null
$moveTo = ".ignored"
$patch = Patch -filename $filename -command $command -moveTo $moveTo
