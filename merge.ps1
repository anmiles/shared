<#
.SYNOPSIS
    Merge with another branch
.PARAMETER new_branch
    Name of new branch to merge from
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    merge master
    # merge with master
.EXAMPLE
    merge use
    # merger branch "use" or first found branch that contains "use" (case-insensitive)
#>

Param (
    [Parameter(Mandatory = $true)][string]$new_branch,
    [switch]$quiet
)

repo -name this -new_branch $new_branch -quiet:$quiet -action {
    out "{Yellow:> Merge with $new_branch}"
    git merge $new_branch
}
