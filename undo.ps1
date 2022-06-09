<#
.SYNOPSIS
    Restore patch
.PARAMETER filename
    Which file to restore patch from
.PARAMETER keep
    Whether to not move processed file
#>

Param (
    [Parameter(Mandatory = $true)][string]$filename,
    [switch]$keep
)

Import-Module $env:MODULES_ROOT\patch.ps1 -Force

$command = "git apply -R"
if (!$keep) { $moveTo = ".restored" }
$patch = Patch -filename $filename -command $command -moveTo $moveTo
