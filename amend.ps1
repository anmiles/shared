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
    $remote = git config --get remote.origin.url
    if ($env:GIT_REMOTE_PREFIX) { $remote = $remote.Replace($env:GIT_REMOTE_PREFIX, "") }

    $remote_name = (Split-Path $remote -Leaf).Replace(".git", "")

    [System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
    Write-Host "Getting access token..."
    vars -op $env:OP_USER -aws $env:AWS_PROFILE -names "gitlab_access_token_amend_$($env:WORKSPACE_NAME)" -silent
    $headers = @{"PRIVATE-TOKEN" = (Get-Variable -Name "gitlab_access_token_amend_$($env:WORKSPACE_NAME)" -Value) }

    $projects_all = @()

    Write-Host "Searching for project..."

    @("visibility=private", "membership=true") | % {
        $page = 1
        $search_url = "https://gitlab.com/api/v4/projects?$_&per_page=100&search=$remote_name"

        do {
            $projects = (Invoke-WebRequest -Headers $headers "$search_url&page=$page").Content | ConvertFrom-Json
            $projects_all += $projects
            $page ++
        }
        while ($projects.Length -gt 0)
    }

    $projects_all | ? { $_.path -eq $remote_name -and $_.ssh_url_to_repo -eq $remote -or $_.http_url_to_repo -eq $remote } | % {
        $protected_branches_url = "https://gitlab.com/api/v4/projects/$($_.id)/protected_branches"

        try {
            $protected_branch = (Invoke-WebRequest -Headers $headers $protected_branches_url).Content | ConvertFrom-Json | ? {$_.name -eq $branch}
        } catch {}

        $uncommitted_list = $(git status --short --untracked-files --renames)

        if ($uncommitted_list.Count) {
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
                git commit --amend -m ($message -replace '"', "'")
            }

            if ($protected_branch) {
                Write-Host "Unprotecting branch..."
                $unprotect_branch_url = "$protected_branches_url/$branch"
                $result = Invoke-WebRequest -Method Delete -Headers $headers $unprotect_branch_url
            }

            Write-Host "Force pushing..."
            git push --force origin HEAD:refs/heads/$branch
            
            if ($protected_branch) {
                Write-Host "Protecting branch..."
                $protect_branch_url = "$($protected_branches_url)?name=$branch&push_access_level=40&merge_access_level=40&unprotect_access_level=40"
                $result = Invoke-WebRequest -Method Post -Headers $headers $protect_branch_url
            }
        }
    }
}
