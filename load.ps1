<#
.SYNOPSIS
    Load changes from git
.DESCRIPTION
    Pull current branch in repository
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Commit message
.PARAMETER merge
    Whether to pull changes from default branch and ask to merge: "none" - never; "mine" - if current branch is mine; "all" - always
.PARAMETER quiet
    Whether to not output current repository and branch name
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
    [ValidateSet('none', 'mine', 'all')][string]$merge = "mine",
    [switch]$quiet
)

Function Pull {
    $prev_commit = git rev-parse HEAD
    git fetch --tags -f
    git pull
    check-packages . $prev_commit
}

$username = $(git config --get user.name)

repo -name $name -quiet:$quiet -action {
    $branches = git branch --format "%(refname:short)"

    if (($merge -eq "none") -or ($merge -eq "mine" -and !(git for-each-ref --format='%(authorname) %09 %(refname)' | grep "origin/$branch" | grep $username))) {
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

    $branches | ? {$_ -ne $branch -and $_ -ne $default_branch} | % {
        PrintBranch $_ -warn
    }
}
