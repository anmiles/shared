<#
.SYNOPSIS
    Fix commit message
.DESCRIPTION
    Unprotect branch, amend last commit message, force push and protect branch
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Right commit message
.PARAMETER empty
    Whether to just force push without creating commit
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    amend
    # fix commit message for last commit in the current repository asking new commit message
.EXAMPLE
    amend this
    # fix commit message for last commit in the current repository asking new commit message
.EXAMPLE
    amend lib
    # fix commit message for last commit in the repository "lib" asking new commit message
.EXAMPLE
    amend repo "Right commit message"
    # fix commit message for last commit in the repository "repo"
.EXAMPLE
    amend all
    # fix commit message in each repository that can be found in $roots
#>

Param (
    [string]$name,
    [string]$message,
    [switch]$empty,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    if (!$empty -and !$delete) {
        $prev_message = $(git log -n 1 --first-parent $branch --pretty=format:%B)

        while (!$message -or $message -eq "diff" -or $message -eq "difftool" -or $message -eq "?" -or $message -eq "??") {
            $message = ask -value $prev_message -old "Wrong commit message" -new "Right commit message" -append

            if ($message -eq "diff" -or $message -eq "?") {
                git diff HEAD
            }

            if ($message -eq "difftool" -or $message -eq "??") {
                git difftool -d HEAD
            }
        }
    }

    if ($message -ne "skip" -and $message -ne "-" -and $message -ne "merge") {
        if ($message) {
            git commit --amend -m ($message -replace '"', "'" -replace '\$', '\$')
        }

        unprotect $name $branch -quiet

        Write-Host "Force pushing..."
        git push --force origin HEAD:refs/heads/$branch

        protect $name $branch -quiet
    }
}
