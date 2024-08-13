<#
.SYNOPSIS
	Show all merge requests for specified repository
.PARAMETER target
	Target branch. If not specified - all branches. "!" before branch name inverts selection
.PARAMETER scope
	Scope of merge requests to show (one of [created_by_me, assigned_to_me, all]). If not specified - show all merge requests
.PARAMETER state
	State of merge requests to show (one of [opened, closed, locked, merged, '']). If not specified - show all merge requests ('')
.PARAMETER quiet
	Whether to not output current repository and branch name
#>

Param (
	[string]$target = "",
	[ValidateSet('created_by_me', 'assigned_to_me', 'all')][string]$scope = "all",
	[ValidateSet('opened', 'closed', 'locked', 'merged', '')][string]$state = "",
	[switch]$quiet
)

# TODO: add github support
gitselect -github { throw "Github is not supported yet for 'mrs' script" }

repo -name this -quiet:$quiet -action {
	$all_mrs = gitservice -exec {
		$page = 1
		$limit = 100
		$all_mrs = @()

		do {
			$url = "https://$env:GITLAB_HOST/api/v4/projects/$repository_id/merge_requests?per_page=$limit&page=$page&scope=$scope"
			if ($state) {
				$url += "&state=$state"
			}
			$page ++
			Write-Host "Load $url " -NoNewline
			$data = Load-GitService $url
			if ($data) {
				$all_mrs += $data
			}
			Write-Host "($($all_mrs.Count))"
		} while ($data.Count -eq $limit)

		return $all_mrs
	}

	$all_mrs | Sort @{Expression={$_.id}; Descending=$true} | % {
		$mr = $_

		if ($target) {
			if ($target -match '^!(.*)') {
				if ($mr.target_branch -eq $matches[1]) {
					return
				}
			} else {
				if ($mr.target_branch -ne $target) {
					return
				}
			}
		}

		if ($mr.iid) { $iid = $mr.iid }
		if ($mr.created_at) { $created = [DateTime]::Parse($mr.created_at).ToString() }
		if ($mr.updated_at) { $updated = [DateTime]::Parse($mr.updated_at).ToString() }
		if ($mr.merged_at) { $merged = [DateTime]::Parse($mr.merged_at).ToString() }

		[PsCustomObject]@{
			Color = switch($mr.state) {
				"opened" { "37" }
				"closed" { "31" }
				"locked" { "33" }
				"merged" { "32" }
				default { "38" }
			};
			State = $mr.state;
			ID = $mr.reference;
			Source = $mr.source_branch;
			Target = $mr.target_branch;
			Draft = if ($mr.draft) { "draft" } else { "" }
			Author = $mr.author.username;
			Created = $created;
			Updated = $updated;
			Merged = $merged;
		}
	} | Format-Table -Property @(
		@{Label = "State"; Expression = {[char]27 + "[" + $_.Color + "m" + $_.State}},
		@{Label = "ID"; Expression = {$_.ID}},
		@{Label = "Source"; Expression = {$_.Source}},
		@{Label = "Target"; Expression = {$_.Target}},
		@{Label = "Draft"; Expression = {$_.Draft}},
		@{Label = "Author"; Expression = {$_.Author}},
		@{Label = "Created"; Expression = {$_.Created}},
		@{Label = "Updated"; Expression = {$_.Updated}},
		@{Label = "Merged"; Expression = {$_.Merged + [char]27 + "[0m"}}
	)
}
