<#
.SYNOPSIS
    Cherry-pick most recent commit
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [switch]$quiet
)

repo -name this -quiet:$quiet -action {
    $hash = [Environment]::GetEnvironmentVariable("RECENT_COMMIT", "Process")
	if (!$hash) { out "{Red:There was no recent commit}"; exit 1 }
	git cherry-pick $hash
}
