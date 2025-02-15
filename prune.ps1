<#
.SYNOPSIS
    Delete all merged branches
.PARAMETER name
    Name of the repository. If not specified - clean up the current repository
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    prune
    # delete all branches except default branch and current branch from the current repository
.EXAMPLE
    prune this
    # delete all branches except default branch and current branch from the current repository
.EXAMPLE
    prune lib
    # delete all branches except default branch and current branch from the repository "lib"
.EXAMPLE
    prune all
    # delete all branches except default branch and current branch from each repository that can be found in $roots
#>

Param (
    [string]$name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    $switch = $false
    if ($branch -ne $default_branch) {
        $switch = $true
        ChangeBranch $default_branch
    }
    git pull
    if (!$?) { exit 1 }
    git remote update --prune
    $locals = git branch --format "%(refname:short)"
    $remotes = git branch --remote --format  "%(refname:short)"
    $locals | % {
        if (!($remotes | grep "origin/$_") -and (confirm "Delete local-only branch {{$_}}")) {
            git branch -D $_

            if ($_ -eq $branch) {
                $switch = $false
            }
        }
    }

    if ($switch) {
        ChangeBranch $branch
    }
}
