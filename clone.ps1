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
.PARAMETER test
    Only show calculated repository url
.EXAMPLE
    clone eslint-config
    # clone eslint-config repository from the preferred git server
.EXAMPLE
    clone lib/downloader
    # clone downloader repository from the lib namespace from the preferred git server
.EXAMPLE
    clone https://github.com/username/repo
    clone https://gitlab.com/group/repo
    clone https://custom.gitlab.com/group/repo
    # clone repository by its web url
.EXAMPLE
    clone https://github.com/username/repo.git
    clone https://gitlab.com/group/repo.git
    clone https://custom.gitlab.com/group/repo.git
    # clone repository by its https url
.EXAMPLE
    clone git@github.com:username/repo.git
    clone git@gitlab.com:username/repo.git
    clone git@custom.gitlab.com:username/repo.git
    # clone repository by its ssh url
#>

Param (
    [Parameter(Mandatory = $true)][string]$name,
    [switch]$private,
    [switch]$crlf,
    [switch]$test
)

$git_default_host = gitselect -github {
    "github.com"
} -gitlab {
    if ($env:GITLAB_HOST) {
        $env:GITLAB_HOST
    } else {
        "gitlab.com"
    }
}

$git_default_user = gitselect -github {
    $env:GITHUB_USER
} -gitlab {
    if ($private) {
        $env:GITLAB_USER
    } else {
        $env:GITLAB_GROUP
    }
}

Function Normalize($name) {
    if ($name -match '^https?://(.+?)/(.+?)/(.+?)(\.git)?$') {
        $git_host = $matches[1]
        $git_user = $matches[2]
        $destination_name = $matches[3]

        $source = if ($git_host -eq $git_default_host) {
            "git@$($git_host):$git_user/$destination_name.git"
        } else {
            if ($matches[4]) {
                $name
            } else {
                "$name.git"
    }
    }

        return @($destination_name, $source)
    }

    if ($name -match '^git@(.+?):(.+?)/(.+?)\.git$') {
        $destination_name = $matches[3]
        $source = $name
        return @($destination_name, $source)
    }

    $destination_name = $name
    $source = "git@$($git_default_host):$git_default_user/$name.git"
    return @($destination_name, $source)
}

$destination_name, $source = Normalize $name
$name = ($destination_name -split "/") | Select -Last 1

if ($test) {
    @($name, $destination_name, $source)
    exit
}

$destination = Join-Path $env:GIT_ROOT $destination_name

out "Will clone {Green:$source} into {Green:$destination}"

if (!(Test-Path $destination -Type Container)) {
    out "{Yellow: > create directory $destination}"

    if ($env:WSL_ROOT) {
        sh "mkdir -p $env:WSL_ROOT/$destination_name"
    } else {
        [void](New-Item -Type Directory $destination -Force)
        takeown /f $destination | Out-Null
    }
}

Push-Location $destination

if (!(Test-Path (Join-Path $destination ".git") -Type Container)) {
    out "{Yellow: > initialize git directory}"
    git init

    if (!$env:WSL_ROOT) {
        takeown /f (Join-Path $destination .git) | Out-Null
    }

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
$repository = gitservice -scan $destination -get -private:$private

$remote_branches = git branch --remote --format "%(refname:short)" | % { $_.Replace("origin/", "") }
if ($remote_branches -and $remote_branches.Contains($repository.default_branch)) {
    out "{Yellow: > checkout}"
    "git checkout $($repository.default_branch)"
    git checkout $repository.default_branch
    out "{Yellow: > reset}"
    "git reset --quiet origin/$($repository.default_branch)"
    git reset --quiet "origin/$($repository.default_branch)"
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

[Environment]::SetEnvironmentVariable("RECENT_REPO", ($destination_name.Split("/") | Select -Last 1), "Process")

out "{Yellow: > check packages}"
check-packages

out "{Yellow: > cd $name}"
goto it
