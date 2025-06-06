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

$repositories = gitservice -get all
$current = @{}

Function InGit {
    if (!$pwd.Path.StartsWith($env:GIT_ROOT)) { return $false }
    $relativePath = shpath $pwd.Path.Replace("$env:GIT_ROOT\", "")
    return $repositories | ? { $relativePath.StartsWith($_.local) }
}

Function UpdateCurrent {
    If (InGit) {
        $current.branch, $current.branches, $current.fullPath = batch @(
            "git rev-parse --abbrev-ref HEAD",
            "git branch --format '%(refname:short)' | grep -v '(HEAD detached at '",
            "git rev-parse --show-toplevel"
        )
        $current.branches = $current.branches -split "`n"
    }
}

if ($name -ne "all") {
    UpdateCurrent
} else {
    $current.branch, $current.branches, $current.fullPath = @($null, @(), $null)
}

Function GetNewBranches ($branch, $branches, $quiet) {
    if ($new_branch -eq $null) {
        return ,@($branch)
    }

    if ($branches -is [string]) {
        return ,@($branch)
    }

    if ($new_branch -ne "") {
        $branches = $branches | grep -i $new_branch
    }

    if ($branches -ne $null) {
        return ,@($branches)
    }

    if ($branches -is [array]) {
        return $branches
    }

    $parsed_branch = git rev-parse $new_branch 2>&1
    if ($?) {
        return ,@($parsed_branch)
    }

    out "{Red:Unknown branch '$new_branch'}"
    exit 1
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
    if ($current.branch -eq $name) { return }
    git checkout $name
    $current.branch = $name
}

Function InvokeRepo($repository) {
    $repository_id = $repository.id
    $name = $repository.name
    $local = $repository.local
    $remote = $repositoty.remote
    $default_branch = $repository.default_branch

    $repo = Join-Path $env:GIT_ROOT $repository.local
    if (!$quiet) { Write-Host $repo -ForegroundColor Yellow }

    if (!(Test-Path $repo)) {
        Write-Host "$repo does not exist" -ForegroundColor DarkYellow
        return
    }

    Push-Location $repo
    $shrepo = shpath -native:(!!$env:WSL_ROOT) $repo

    if ($shrepo -ne $current.fullPath) {
        $current.branch = git rev-parse --abbrev-ref HEAD
    }

    if (!$quiet) { PrintBranch $current.branch }

    if ($new_branch -ne $null) {
        $new_branches = GetNewBranches -branch $current.branch -branches $current.branches
        $new_branch = $new_branches[0]
    }

    try {
        $branch = $current.branch
        $branches = $current.branches
        $fullPath = $current.fullPath
        Invoke-Command $action
    } catch {
        throw $_
    } finally {
        Pop-Location
    }
}

if (!$name -or $name -eq "this") {
    if (!$current.fullPath) { exit }
    $name = Split-Path $current.fullPath -Leaf
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

$found = $false

$repositories | % {
    if ($name -eq "all" -or $name -eq $_.name) {
        $found = $true
        UpdateCurrent
        InvokeRepo $_
    }
}

Function GetCandidates($name) {
    $startsWith = @($repositories | ? { $_.name.Contains($name) })
    if ($startsWith.Count -gt 0) {
        return $startsWith
    }

    Import-Module $env:MODULES_ROOT\levenshtein.ps1 -Force
    return [Array](GetAllClosest $name $repositories "name")
}

if (!$found) {
    $candidates = [Array](GetCandidates -name $name)

    $candidate = if ($candidates.Length -eq 1) {
        $candidates[0]
    } else {
        $i = 0
        $selected = $null

        do {
            if (confirm "Did you mean {Green:$($candidates[$i].name)}") {
                $selected = $candidates[$i]
                break
            }

            $i++
            $i = $i % $candidates.Length
        } while ($true)

        $selected
    }

    [Environment]::SetEnvironmentVariable("RECENT_REPO", $candidate.name, "Process")
    InvokeRepo $candidate
}
