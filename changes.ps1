<#
.SYNOPSIS
    Get all changes in current branch except merges from other branches
.PARAMETER from
    Commit hash from which (non-inclusive) to collect changes
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [Parameter(Mandatory = $true)][string]$from,
    [switch]$quiet
)

repo -name this -quiet:$quiet -action {
    $commits = iex "git log --reverse $from..HEAD --pretty=format:%H"
    git checkout $from
    $commits | % { git cherry-pick --mainline 1 --no-commit $_ }
    git diff HEAD
}
