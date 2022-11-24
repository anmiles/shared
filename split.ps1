<#
.SYNOPSIS
    Apply only part of patch
.PARAMETER filename
    Which file to split patch from
.PARAMETER keep
    Whether to not move processed file
#>

Param (
    [Parameter(Mandatory = $true)][string]$filename,
    [switch]$keep
)

Import-Module $env:MODULES_ROOT\patch.ps1 -Force

$command = "git apply"
$moveTo = $null
$result = Patch -filename $filename -command $command -moveTo $moveTo

$file = Join-Path $patch_root $filename
(Get-Content $file)[0] -match 'diff \-\-git (a|b)\/(.*) (b|a)\/(.*)' | Out-Null
$target = $matches[4]
$temp = AltPatchName -filename $filename -dirname ".temp"
$modified = AltPatchName -filename $filename -dirname ".modified"

out "Modify file {Yellow:$target} and press {White:ENTER} to apply it again > " -NoNewLine

repo -name this -quiet -action {
    Copy-Item $target $temp
    Read-Host
    $temp_sh = shpath $temp -native -resolve
    $file_sh = shpath $file -native -resolve
    sh "git diff $target > $modified; git diff --no-index $target $temp_sh > $file_sh; sed -i 's|b$temp_sh|b/$target|g' $file_sh"
}
