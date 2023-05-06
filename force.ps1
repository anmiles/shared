<#
.SYNOPSIS
    Perform forced operations on protected branches
.DESCRIPTION
    Unprotect branch, perform forced operartion and protect branch again
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$name,
    [switch]$quiet,
    [ScriptBlock]$action
)

$force_action = $action

repo -name $name -quiet:$quiet -action {
    $protected_branches_url = "https://gitlab.com/api/v4/projects/$repository_id/protected_branches"

    try {
        $protected_branch = (gitlab -load $protected_branches_url) | ? { $_.name -eq $branch }
    } catch {}

    if ($protected_branch) {
        Write-Host "Unprotecting branch..."
        $unprotect_branch_url = "$protected_branches_url/$branch"
        gitlab -load $unprotect_branch_url -method Delete | Out-Null
    }

    Invoke-Command $force_action

    if ($protected_branch) {
        Write-Host "Protecting branch..."
        $protect_branch_url = "$($protected_branches_url)?name=$branch&push_access_level=40&merge_access_level=40&unprotect_access_level=40"
        gitlab -load $protect_branch_url -method Post | Out-Null
    }
}
