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
    [Parameter(Mandatory = $true)][ScriptBlock]$action,
    $new_branch,
    [switch]$quiet
)

$depth = 2

$default_branches = @{
    default = "master"
}

($env:GIT_DEFAULT_BRANCHES | ConvertFrom-Json).PSObject.Properties | % {
    $branch_name = $_.Name

    $_.Value | % {
        $default_branches[$_] = $branch_name
    }
}

Function GetNewBranch ($branch, $quiet) {
    $branches = git branch --format "%(refname:short)" | grep -v "(HEAD detached at "

    if (!$quiet) { PrintBranch $branch }

    if ($new_branch -eq $null) {
        return $branch
    }

    if ($branches -is [string]) {
        return $branch
    }

    if ($new_branch -ne "") {
        $branches = $branches | grep -i $new_branch

        if ($branches -is [string]) {
            return $branches
        }

        if ($branches -eq $null) {
            $parsed_branch = git rev-parse $new_branch

            if ($parsed_branch) {
                return $parsed_branch
            } else {
                return $branch
            }
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
    $branch = git rev-parse --abbrev-ref HEAD
    $new_branch = GetNewBranch $branch
    $default_branch = $default_branches[$name]
    if (!$default_branch) { $default_branch = $default_branches.default }
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

if (Test-Path $env:GIT_ROOT) {
    Get-ChildItem -Path $env:GIT_ROOT -Filter ".git" -Recurse -Directory -Hidden:(!$env:WSL_ROOT) -Depth $depth | foreach {
        $norepo = Join-Path $_.Parent.FullName ".norepo"

        if (!(Test-Path $norepo)) {
            if ($name -eq "all") {
                InvokeRepo -repo $_.Parent.FullName -name $_.Parent.Name
            }
            
            if ($name -eq $_.Parent.Name) {
                InvokeRepo -repo $_.Parent.FullName -name $name
            }
        }
    }
}
