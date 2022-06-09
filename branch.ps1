<#
.SYNOPSIS
    Create branch
.DESCRIPTION
    Cleanup branch name and create appropriate branch then push it
.PARAMETER name
    Branch name
.PARAMETER d
    Whether to delete branch
.PARAMETER force
    Whether to not confirm creating of new branch
.EXAMPLE
    branch New feature
    # creates branch feature/New-feature
#>

Param (
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$name,
    [switch]$d,
    [switch]$force
)

while (!$name) {
    $name = ask -new "Enter branch name"
}

$branch_name = $name -Join "-"

if ($branch_name -notmatch "^[a-z]+\/") {
    $branch_name = $name -Join " " -replace "[^A-Za-z0-9_\-]+", "-"
    $branch_name = "feature/$branch_name"
}

$current_branch_name = $(git rev-parse --abbrev-ref HEAD)

if ($d) {
    if (confirm "Do you really want to delete branch {Green:$branch_name}") {
        if ($branch_name -eq $current_branch_name) {
            discard
            ch -next
        }

        git branch -D $branch_name
        git push origin -d $branch_name
    }
    exit
}

if (!$force -and !(confirm "Do you really want to create new branch {{$branch_name}} from {{$current_branch_name}}")) { exit }

git branch $branch_name
git checkout $branch_name
git push --set-upstream origin $branch_name
