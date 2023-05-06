<#
.SYNOPSIS
    Rename default branch to main
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$name,
    [switch]$quiet
)

$main_branch = "main"

repo -name $name -quiet:$quiet -action {
	if ($default_branch -eq $main_branch) {
		throw "Default branch is already '$main_branch'"
	}

	if (git branch --format "%(refname:short)" | grep $main_branch) {
		throw "Branch '$main_branch' already exists as non-default branch"
	}

	$gitlab_file = ".gitlab-ci.yml"
	$gitlab_branch_regex = "\- $default_branch"
	if ((Test-Path $gitlab_file) -and (grep $gitlab_branch_regex $gitlab_file)) {
		out "{Yellow:Replace $default_branch to $main_branch in $gitlab_file}"
		$content = file $gitlab_file
		$content = $content -replace $gitlab_branch_regex, "- $main_branch" 
		file $gitlab_file $content
	}

	out "{Yellow:Save changes}"
	save -push -quiet

	out "{Yellow:Checkout $default_branch}"
	git checkout $default_branch

	out "{Yellow:Rename $default_branch to $main_branch}"
	git branch -m $default_branch $main_branch

	out "{Yellow:Push $main_branch}"
	git push -u origin $main_branch

	out "{Yellow:Set $main_branch default}"
	gitlab -load "https://gitlab.com/api/v4/projects/$repository_id" -method PUT -data @{default_branch = $main_branch} | Out-Null
	
	out "{Yellow:Protect $main_branch}"
	protect $name $main_branch -quiet

	out "{Yellow:Unprotect $default_branch}"
	unprotect $name $default_branch -quiet

	out "{Yellow:Delete $default_branch}"
	git push --force origin --delete $default_branch

	out "{Yellow:Scan repository}"
	gitlab -scan $repo

	save -push -message diff
}
