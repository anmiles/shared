<#
.SYNOPSIS
    Clone specified repository
.PARAMETER name
    Name of the repository
.PARAMETER destination
    Local directory for repository
.PARAMETER private
    Whether to get repository from private group rather than primary
.PARAMETER crlf
    Whether to set autocrlf=true for repository to let it have Windows-style line breaks
#>

Param (
    [Parameter(Mandatory = $true)][string]$name,
    [string]$destination_name = $name,
    [switch]$private,
    [switch]$crlf
)

$gitlab_host = $env:GIT_REMOTE_PREFIX + "gitlab.com"
$gitlab_group = Split-Path $env:GIT_ROOT -Leaf
if ($private) { $gitlab_group = "anmiles_$gitlab_group" }
$source = "git@$($gitlab_host):$gitlab_group/$name.git"
$destination = Join-Path $env:GIT_ROOT $destination_name

out "Will clone {Green:$source} into {Green:$destination}"

if (!(Test-Path $destination -Type Container)) {
    [void](New-Item -Type Directory $destination -Force)
}

Push-Location $destination

if (!(Test-Path (Join-Path $destination ".git") -Type Container)) {
    git init
    if ($crlf) { git config core.autocrlf true }
}

if (!$(git remote) -or !$(git remote).Contains("origin")) {
    git remote add origin $source
}

$result = exec git fetch origin

if ($result.exitCode -eq 0) {
    $default_branch = $(git branch --show-current)
    git checkout $default_branch
    git reset origin/$default_branch
} else {
    out "{Red:Cannot access repository $name with error:}"
    out $result.err

    if (confirm "Do you want to create repository $name") {
        $default_branch = "master"
        git switch -c $default_branch
        New-Item -Type File .gitignore
        git add .
        git commit -m "Initial commit"
        git push -u origin $default_branch
    } else {
        exit 1
    }
}

[Environment]::SetEnvironmentVariable("RECENT_REPO", $destination_name, "Process")
check-packages
goto it
