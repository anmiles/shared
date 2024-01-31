<#
.SYNOPSIS
    Unprotect branch in gitlab
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER branch
    Branch name to unprotect
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$name,
    [string]$branch_name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    Write-Host "Unprotecting branch '$branch_name'..."

    gitselect -github {
        if (!$repository.public) {
            out "{DarkYellow:Managing protected branches is not allowed on non-public github repositories}"
            exit
        }

        $url = "https://api.github.com/repos/$env:GITHUB_USER/$name/branches/$branch_name/protection"
        gitservice -load $url -method DELETE -token admin | Out-Null
    } -gitlab {
        $url = "https://gitlab.com/api/v4/projects/$repository_id/protected_branches/$branch_name"
        gitservice -load $url -method DELETE -token admin | Out-Null
    }
}
