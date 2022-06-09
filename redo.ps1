<#
.SYNOPSIS
    Restore patch, than let edit it and apply again
.PARAMETER filename
    Which file to redo patch from
.PARAMETER keep
    Whether to not move processed file
#>

Param (
    [Parameter(Mandatory = $true)][string]$filename,
    [switch]$keep
)

Import-Module $env:MODULES_ROOT\patch.ps1 -Force

$command = "git apply -R"
$moveTo = $null
$result = Patch -filename $filename -command $command -moveTo $moveTo

code $filename
out "Fix patch {Yellow:$filename} and press {White:ENTER} to apply it again > " -NoNewLine
Read-Host

$command = "git apply"
if (!$keep) { $moveTo = ".modified" }
$patch = Patch -filename $filename -command $command -moveTo $moveTo
