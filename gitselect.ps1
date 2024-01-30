<#
.SYNOPSIS
	Perform one of specified actions depend on pre-selected git service. Return name of the git service if no actions specified
.PARAMETER github
	Action to perform in $env:GIT_SERVICE -eq "github"
.PARAMETER gitlab
	Action to perform in $env:GIT_SERVICE -eq "gitlab"
.EXAMPLE
	gitselect -github { "This is github" } -gitlab { Write-Host $env:GITLAB_USER }
	# return "This is github" if git service is github
	# output gitlab user if git service is gitlab
.EXAMPLE
	$service = gitselect
	# perform nothing
	# set $service to the name of the git service
#>

Param (
	[ScriptBlock]$github,
	[ScriptBlock]$gitlab
)

$service = $env:GIT_SERVICE

if (!$github -and !$gitlab) {
	$service
	exit
}

if ($service -ne "github" -and $service -ne "gitlab") {
	throw "`$env:SERVICE is '$($env:SERVICE)', expected one of ('github', 'gitlab')"
}

if ($service -eq "github" -and $github) {
	Invoke-Command -ScriptBlock $github
}

if ($service -eq "gitlab" -and $gitlab) {
	Invoke-Command -ScriptBlock $gitlab
}
