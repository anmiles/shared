<#
.SYNOPSIS
    Invoke an action on sinlge repo or multiple repos
.DESCRIPTION
    There should be GIT_ROOT environment variable that is point to where to search the repositories. Example: D:\src
.PARAMETER name
    Apply script only for specified repository name
    { all } - apply for all repositories that can be found in $roots
    { it } - apply script for repository that was metioned in previous script call
    If not specified - apply script only for current working directory
.PARAMETER action
    Script block.
.PARAMETER new_branch
    Name of new branch to make the action
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    repo -action {git push} -name repo
    # push selected repository
#>

Param (
    [string]$name,
    [ScriptBlock]$action = {},
    $new_branch,
    [switch]$quiet
)

$default_branches = $env:GIT_DEFAULT_BRANCHES | ConvertFrom-Json

Function GetNewBranches ($branch, $branches, $quiet) {
    $branches = git branch --format "%(refname:short)" | grep -v "(HEAD detached at "

    if ($new_branch -eq $null) {
        return @($branch)
    }

    if ($branches -is [string]) {
        return @($branch)
    }

    if ($new_branch -ne "") {
        $branches = $branches | grep -i $new_branch
    }

    if ($branches -is [string]) {
        return @($branches)
    }

    if ($branches -eq $null) {
        $parsed_branch = git rev-parse $new_branch

        if ($parsed_branch) {
            return @($parsed_branch)
        } else {
            return @($branch)
        }
    }

    return $branches
}

Function PrintBranch {
    Param (
        [Parameter(Mandatory = $true)][string]$name,
        [switch]$next,
        [switch]$other,
        [switch]$warn
    )

    $color = switch($true) {
        $next { [ConsoleColor]::DarkYellow }
        $other { [ConsoleColor]::Cyan }
        $warn { [ConsoleColor]::Magenta }
        default { [ConsoleColor]::DarkGreen }
    }

    $symbol = switch($true) {
        $next { ">" }
        $other { "#" }
        $warn { "?" }
        default { "*" }
    }

    if (!$quiet) { out "$symbol {$($color):$name}" }
}

Function ChangeBranch($name, [switch]$quiet) {
    if (!$quiet) { PrintBranch $name -next }
    $branch = git rev-parse --abbrev-ref HEAD
    if ($branch -eq $name) { return }
    git checkout $name
}

Function InvokeRepo($repo, $name) {
    if (!$quiet) { Write-Host $repo -ForegroundColor Yellow }
    Push-Location $repo
    $default_branch = $default_branches.$name
    if (!$default_branch) { $default_branch = $default_branches.default }
    $branch = git rev-parse --abbrev-ref HEAD
    if (!$quiet) { PrintBranch $branch }

    if ($new_branch -ne $null) {
        $new_branches = GetNewBranches -branch $branch
        $new_branch = $new_branches[0]
    }

    Invoke-Command $action
    Pop-Location
}

if (!$name -or $name -eq "this") {
    $fullpath = git rev-parse --show-toplevel
    if (!$fullpath) { exit }
    $name = Split-Path $fullpath -Leaf
}

if ($name -eq "it") {
    $name = [Environment]::GetEnvironmentVariable("RECENT_REPO", "Process")

    if (!$name) {
        Write-Host "There was no previous call of repo" -ForegroundColor Red
        exit 1
    }
}

if ($name -and $name -ne "all" -and $name -ne "it") {
    [Environment]::SetEnvironmentVariable("RECENT_REPO", $name, "Process")
}

$repositories= @{}
$i = 0

($env:REPOSITORIES | ConvertFrom-Json) | % {
    $this_repo = Join-Path $env:GIT_ROOT $_
    $this_name = Split-Path $this_repo -Leaf

    $repositories[$this_name] = @{
        Name = $this_name
        Repo = $this_repo
        Index = $i++
    }
}

$repositories.Values | Sort { $_.Index } | % {
    if ($name -eq "all" -or $name -eq $_.Name) {
        $found = $true
        InvokeRepo -repo $_.Repo -name $_.Name
    }
}

if (!$found) {
    Import-Module $env:MODULES_ROOT\levenshtein.ps1 -Force
    $closest = GetClosest $name ($repositories.Values | % { $_.Name })
    if ($closest -is [Array]) { $closest = $closest[0] }

    if (confirm "Did you mean {Green:$closest}") {
        InvokeRepo -repo $repositories[$closest].Repo -name $closest
    }
}
