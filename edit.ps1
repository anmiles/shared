<#
.SYNOPSIS
    Edit respository
.DESCRIPTION
    Open VSCode with a project that match specified name
.PARAMETER name
    Project name that needs to be opened
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    edit
    # edit project for the current repository
.EXAMPLE
    edit this
    # edit project for the current repository
.EXAMPLE
    edit lib
    # edit project for the repository "lib"
.EXAMPLE
    edit all
    # edit projects for each repository that can be found in $roots
#>

Param (
    [string]$name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    if ($env:WSL_ROOT) {
        sh -shell wsl -command "code ."
    } else {
        code .
    }
}
