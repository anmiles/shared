<#
.SYNOPSIS
    Checks package.json files in the current directory and its children and proposes to re-install if any changes detected
.PARAMETER path
    Path of the directory to check
.PARAMETER commit
    If specified - check for changes in package.json files from this commit, otherwise check existence of package.json files at all
#>

Param (
    [string]$path = ".",
    [string]$commit
)

$package_json = "package.json"
$yarn_lock = "yarn.lock"

if ($commit) {
    $packages = git -C $path diff --name-only $commit
    $detected = "changed"
} else {
    $packages = git -C $path grep -e . --name-only -I --untracked --exclude-standard
    $detected = "created"
}

$packages | ? { $_ -eq $package_json -or $_.EndsWith("/$package_json") } | % {
    $parent = Join-Path $path $_ | Resolve-Path | Split-Path -Parent
    yarn --cwd $parent workspaces info 2>&1 | Out-Null
    $yarn_detected = $? -or (Join-Path $parent $yarn_lock | Test-Path)
    $action = switch ($yarn_detected) { $true { "yarn install" } $false { "npm install" } }
    out "Package.json $detected in {Yellow:$parent}. Consider to {Yellow:$action}" -ForegroundColor Magenta
}
