<#
.SYNOPSIS
    Fix commit message
.DESCRIPTION
    Unprotect branch, amend last commit message, force push and protect branch
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Right commit message
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
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    $protected_branches_url = "https://gitlab.com/api/v4/projects/$repository_id/protected_branches"

    try {
        $protected_branch = (gitlab -load $protect_branch_url) | ? { $_.name -eq $branch }
    } catch {}

    $uncommitted_list = $(git status --short --untracked-files --renames)

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

    if ($message -ne "skip" -and $message -ne "-" -and $message -ne "merge") {
        if ($message) {
            git commit --amend -m ($message -replace '"', "'" -replace '\$', '\$')
        }

        if ($protected_branch) {
            Write-Host "Unprotecting branch..."
            $unprotect_branch_url = "$protected_branches_url/$branch"
            gitlab -load $unprotect_branch_url -method Delete | Out-Null
        }

        Write-Host "Force pushing..."
        git push --force origin HEAD:refs/heads/$branch

        if ($protected_branch) {
            Write-Host "Protecting branch..."
            $protect_branch_url = "$($protected_branches_url)?name=$branch&push_access_level=40&merge_access_level=40&unprotect_access_level=40"
            gitlab -load $protect_branch_url -method Post | Out-Null
        }
    }
}
