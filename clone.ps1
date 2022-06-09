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

$remote = git remote

if (!$remote -or !$remote.Contains("origin")) {
    git remote add origin $source
}

$env_json_file = Join-Path $env:GIT_ROOT env.json
$env_json = ConvertFrom-Json (file $env_json_file)

$result = git fetch origin

if ($LastExitCode -eq 0) {
    if ($env_json.GIT_DEFAULT_BRANCHES.$name) {
        $default_branch = $env_json.GIT_DEFAULT_BRANCHES.$name
    } else {
        $default_branch = git remote show origin | grep -h "HEAD branch:" | % {$_.Trim().Replace('HEAD branch: ', '')}
        if ($default_branch -ne $env_json.GIT_DEFAULT_BRANCHES.default) {
            $env_json.GIT_DEFAULT_BRANCHES | Add-Member -NotePropertyName $name -NotePropertyValue $default_branch
            Copy-Item $env_json_file "$env_json_file.bak" -Force
            file $env_json_file ($env_json | ConvertTo-Json)
            [Environment]::SetEnvironmentVariable("GIT_DEFAULT_BRANCHES", ($env_json.GIT_DEFAULT_BRANCHES | ConvertTo-Json), "Process")
        }
    }
    
    git checkout $default_branch
    git reset --quiet origin/$default_branch
} else {
    out "{Red:Cannot access repository $name with error:}"
    out $result.err

    if (confirm "Do you want to create repository $name") {
        $default_branch = $env_json.GIT_DEFAULT_BRANCHES.default
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
