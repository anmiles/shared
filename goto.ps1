<#
.SYNOPSIS
    Goto specified repository and show its status
.PARAMETER name
    Name of the repository. If not specified - shows the current repository
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    goto
    # goto the current repository and show its status
.EXAMPLE
    goto this
    # goto the current repository and show its status
.EXAMPLE
    goto lib
    # goto the repository "lib" and show its status
.EXAMPLE
    goto all
    # goto through each repository that can be found in $roots and show their statuses
#>

Param (
    [string]$name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    Push-Location (Get-Location)
    git status

    $(git branch --format "%(refname:short)") | ? {$_ -ne $branch} | % {
        PrintBranch $_ -other
    }
}
