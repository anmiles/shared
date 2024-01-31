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

    gitselect -github {
        if (!$repository.public) {
            out "{DarkYellow:Managing protected branches is not allowed on non-public github repositories}"
            exit
        }

        $data = @{
            lock_branch = $true
            restrictions = $null
            enforce_admins = $false
            required_conversation_resolution = $true
            required_status_checks = @{
                strict = $true
                contexts = @()
            }
            required_pull_request_reviews = @{
                dismiss_stale_reviews = $true
                require_code_owner_reviews = $true
                required_approving_review_count = 1
                require_last_push_approval  = $true
            }
        }

        $url = "https://api.github.com/repos/$env:GITHUB_USER/$name/branches/$branch_name/protection"
        gitservice -load $url -method PUT -token admin -data $data | Out-Null
    } -gitlab {
        $data = "push_access_level=40&merge_access_level=40&unprotect_access_level=40"
        $url = "https://gitlab.com/api/v4/projects/$repository_id/protected_branches?name=$branch_name&$data"
        gitservice -load $url -method POST -token admin | Out-Null
    }
}
