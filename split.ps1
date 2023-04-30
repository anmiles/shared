<#
.SYNOPSIS
    Apply only part of patch
.PARAMETER filename
    Which file to split patch from
.PARAMETER R
    Whether to work with undo path (if false - work with fix path)
#>

Param (
    [Parameter(Mandatory = $true)][string]$filename,
    [switch]$R
)

Import-Module $env:MODULES_ROOT\patch.ps1 -Force

$sh_r = switch($R) { $true {"-R"} $false {""} }
$command = switch($R) { $true {"git apply --unsafe-paths -R"} $false {"git apply --unsafe-paths"} }
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
    $modified_sh = shpath $modified -native -resolve
    $file_sh = shpath $file -native -resolve
    $applied_sh = switch($R){ $true {$file_sh} $false {$modified_sh} }
    $postponed_sh = switch($R){ $true {$modified_sh} $false {$file_sh} }
    "git diff $sh_r $target > $applied_sh; git diff --no-index $target $temp_sh > $postponed_sh; sed -i 's|b$temp_sh|b/$target|g' $postponed_sh"
    sh "git diff $sh_r $target > $applied_sh; git diff --no-index $target $temp_sh > $postponed_sh; sed -i 's|b$temp_sh|b/$target|g' $postponed_sh"
}
