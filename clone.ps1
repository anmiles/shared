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

out "{Yellow: > get default branches}"
$env_json_file = Join-Path $env:GIT_ROOT env.json
$env_json = ConvertFrom-Json (file $env_json_file)
$env_json_changed = $false

out "{Yellow: > fetch origin}"
$result = git fetch origin

if ($LastExitCode -eq 0) {
    $default_branch_exists = $true

    if ($env_json.GIT_DEFAULT_BRANCHES.$name) {
        $default_branch = $env_json.GIT_DEFAULT_BRANCHES.$name
    } else {
        out "{Yellow: > get default branch}"
        $default_branch = git remote show origin | grep -h "HEAD branch:" | % {$_.Trim().Replace('HEAD branch: ', '')}

        if ($default_branch -eq "(unknown)") {
            $default_branch_exists = $false
            $default_branch = $env_json.GIT_DEFAULT_BRANCHES.default
        }

        if ($default_branch -ne $env_json.GIT_DEFAULT_BRANCHES.default) {
            $env_json.GIT_DEFAULT_BRANCHES | Add-Member -NotePropertyName $name -NotePropertyValue $default_branch
            $env_json_changed = $true
            [Environment]::SetEnvironmentVariable("GIT_DEFAULT_BRANCHES", ($env_json.GIT_DEFAULT_BRANCHES | ConvertTo-Json), "Process")
        }
    }

    if ($default_branch_exists) {
        out "{Yellow: > checkout}"
        "git checkout $default_branch"
        git checkout $default_branch
        out "{Yellow: > reset}"
        "git reset --quiet origin/$default_branch"
        git reset --quiet origin/$default_branch
    } else {
        out "{Yellow: > switch to $default_branch}"
        git switch -c $default_branch
        out "{Yellow: > commit}"
        git commit --allow-empty -m "Initial commit"
        out "{Yellow: > push}"
        git push -u origin $default_branch
    }
} else {
    out "{Red:Cannot access repository $name with error:}"
    out $result.err

    if (confirm "Do you want to create repository $name") {
        $default_branch = $env_json.GIT_DEFAULT_BRANCHES.default
        out "{Yellow: > switch to $default_branch}"
        git switch -c $default_branch
        New-Item -Type File .gitignore
        out "{Yellow: > add files}"
        git add .
        out "{Yellow: > commit}"
        git commit -m "Initial commit"
        out "{Yellow: > push}"
        git push -u origin $default_branch
    } else {
        exit 1
    }
}

if (!$env_json.REPOSITORIES.Contains($name)) {
    $env_json.REPOSITORIES += $name
    $repositories = $env_json.REPOSITORIES | % { [PSCustomObject]@{Name = $_; Order = -$_.StartsWith("scripts/") } } | Sort Order, Name | % { $_.Name }
    [Environment]::SetEnvironmentVariable("REPOSITORIES", $repositories, "Process")
    $env_json_changed = $true
}

if ($env_json_changed) {
    Copy-Item $env_json_file "$env_json_file.bak" -Force
    file $env_json_file ($env_json | ConvertTo-Json)
}

[Environment]::SetEnvironmentVariable("RECENT_REPO", $destination_name, "Process")
out "{Yellow: > check packages}"

check-packages
goto it
