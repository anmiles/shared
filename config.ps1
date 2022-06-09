<#
.SYNOPSIS
    Edit config file
.DESCRIPTION
    Open notepad++ for editing .git/config file
.PARAMETER name
    Project name that's config file needs to be edited
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    config 
    # edit .git/config file of the repository in the current working directory
.EXAMPLE
    config this
    # edit .git/config file of the repository in the current working directory    
.EXAMPLE
    config lib 
    # edit .git/config file for the repository "lib"
.EXAMPLE
    config all
    # edit .git/config file for each repository that can be found in $roots
#>

Param (
    [string]$name,
    [switch]$quiet
)

repo -name $name -quiet:$quiet -action {
    code .git/config
}
