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
    [switch]$quiet = $true
)

repo -name $name -quiet:$quiet -action {
    $switch = $false
    ChangeBranch $default_branch
    git pull
    git remote update --prune

    git branch --format "%(refname:short)" | % {
        git show "remotes/origin/$_" 2>&1 | Out-Null
        if (!$? -and (confirm "Delete merged branch {{$_}}")) {
            git branch -D $_

            if ($_ -eq $branch) {
                $switch = $true
            }
        }
    }

    if (!$switch) {
        ChangeBranch $branch
    }
}
