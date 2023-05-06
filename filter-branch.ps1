<#
.DESCRIPTION
	Extract specified directory from repository and filter history just for this one
.PARAMETER name
	Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified	
.PARAMETER path
	Relative path to directory from repository root
.PARAMETER quiet
	Whether to not output current repository and branch name
#>

Param (
	[string]$name,
	[Parameter(Mandatory = $true)][string]$path,
	[switch]$quiet
)

repo -name $name -quiet:$quiet -action {
	if (!(Test-Path $path)) {
		throw "Path $path doesn't exist in repository $repo"
	}

	git filter-branch --subdirectory-filter $path -- --all
	amend -empty -quiet
}

