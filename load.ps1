<#
.SYNOPSIS
    Load changes from git
.DESCRIPTION
    Pull current branch in repository
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Commit message
.PARAMETER quiet
    Whether to not output current repository and branch name
.PARAMETER nomerge
    Whether to suppress asking for merge with default branch
.EXAMPLE
    load 
    # load repository in the current directory
.EXAMPLE
    load this
    # load repository in the current directory
.EXAMPLE
    load this merge
    # load repository in the current directory and then merge default branch
.EXAMPLE
    load lib
    # load the repository "lib"
.EXAMPLE
    load all
    load each repository that can be found in $roots
#>

Param (
    [string]$name,
    [string]$message,
    [switch]$quiet,
    [switch]$nomerge = $true
)

Function Pull {
    $prev_commit = git rev-parse HEAD
    git fetch --tags -f
    git pull
    check-packages . $prev_commit
}

repo -name $name -quiet:$quiet -action {
    if ($nomerge) {
        Pull
    } else {
        if ($branch -ne $default_branch) {
            ChangeBranch $default_branch
        }

        Pull

        if ($branch -ne $default_branch) {
            ChangeBranch $branch
            Pull
            
            if ($message -eq "merge" -or (confirm "Do you want to merge {{$default_branch}} into {{$branch}}")) {
                git merge $default_branch
            }
        }
    }

    $(git branch --format "%(refname:short)") | ? {$_ -ne $branch -and $_ -ne $default_branch} | % {
        PrintBranch $_ -warn
    }
}
