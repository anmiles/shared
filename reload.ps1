<#
.SYNOPSIS
    Discard changes and load from git
.PARAMETER name
    Repository name (using "this" if not specified)
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$name = "this",
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    discard -quiet
    load -quiet
}
