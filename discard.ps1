<#
.SYNOPSIS
    Clean repository
.DESCRIPTION
    Remove files from staged or unstaged areas
.PARAMETER filename
    File to affect. If not specified - affect any files
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$filename,
    [switch]$quiet
)

repo -name this -quiet:$quiet -action {
    if ($filename) {
        git reset --quiet -- $filename
        git restore $filename
        git clean -fd -- $filename
    } else {
        git reset --quiet
        git restore .
        git clean -fd
    }
}
