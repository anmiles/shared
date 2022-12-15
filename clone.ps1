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

$gitlab_group = $env:WORKSPACE_NAME
if ($private) { $gitlab_group = "anmiles_$gitlab_group" }
$source = "git@gitlab.com:$gitlab_group/$name.git"
$destination = Join-Path $env:GIT_ROOT $destination_name

out "Will clone {Green:$source} into {Green:$destination}"

if (!(Test-Path $destination -Type Container)) {
    out "{Yellow: > create directory $destination}"

    if ($env:WSL_ROOT) {
        sh "mkdir $env:WSL_ROOT/$destination_name"
    } else {
        [void](New-Item -Type Directory $destination -Force)
    }
}

Push-Location $destination

if (!(Test-Path (Join-Path $destination ".git") -Type Container)) {
    out "{Yellow: > initialize git directory}"
    git init

    if ($crlf) {
        out "{Yellow: > set core.autocrlf to true}"
        git config core.autocrlf true
    }
}

out "{Yellow: > get remote}"
$remote = git remote

if (!$remote -or !$remote.Contains("origin")) {
    out "{Yellow: > create remote}"
    git remote add origin $source
}

out "{Yellow: > fetch origin}"
$result = git fetch origin

if ($LastExitCode -ne 0) {
    out "{Red:Cannot access repository $name with error:}"
    out $result.err
    exit 1
}

out "{Yellow: > scan remote info}"
$repository = gitlab -scan $destination -get -private:$private

$remote_branches = git branch --remote --format "%(refname:short)" | % { $_.Replace("origin/", "") }
if ($remote_branches -and $remote_branches.Contains($repository.default_branch)) {
    out "{Yellow: > checkout}"
    "git checkout $($repository.default_branch)"
    git checkout $repository.default_branch
    out "{Yellow: > reset}"
    "git reset --quiet origin/$($repository.default_branch)"
    git reset --quiet origin/$repository.default_branch
} else {
    out "{Yellow: > switch to $($repository.default_branch)}"
    git switch -c $repository.default_branch
    out "{Yellow: > commit}"
    $message = "Initial commit"
    if ($env:GIT_DEFAULT_PROJECT) { $message = "$($env:GIT_DEFAULT_PROJECT)-0 $message" }
    git commit --allow-empty -m $message
    out "{Yellow: > push}"
    git push -u origin $repository.default_branch
}

[Environment]::SetEnvironmentVariable("RECENT_REPO", $destination_name, "Process")

out "{Yellow: > check packages}"
check-packages

out "{Yellow: > cd $name}"
goto it
