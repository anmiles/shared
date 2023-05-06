<#
.SYNOPSIS
    Protect branch in gitlab
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER branch
    Branch name to protect
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$name,
    [string]$branch_name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    Write-Host "Protecting branch '$branch_name'..."
    $protect_branch_url = "https://gitlab.com/api/v4/projects/$repository_id/protected_branches?name=$branch_name&push_access_level=40&merge_access_level=40&unprotect_access_level=40"
    gitlab -load $protect_branch_url -method Post | Out-Null
}
