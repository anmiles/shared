<#
.SYNOPSIS
	Show recent jobs of the pipelines for specified repository
.PARAMETER job
	Name of the job. If not specified - show all jobs
.PARAMETER scope
	Scope of jobs to show (one or or an array of [created, pending, running, failed, success, canceled, skipped, waiting_for_resource, manual]). If not specified - show all jobs
.PARAMETER count
	Maximum count of fetched jobs
.PARAMETER quiet
	Whether to not output current repository and branch name
#>

Param (
	[string]$job,
	[ValidateSet('created', 'pending', 'running', 'failed', 'success', 'canceled', 'skipped', 'waiting_for_resource', 'manual')][string[]]$scopes,
	$count = 20,
	[switch]$quiet
)

# TODO: add github support
gitselect -github { throw "Github is not supported yet for 'jobs' script" }

repo -name this -quiet:$quiet -action {
	$all_jobs = gitservice -exec {
		if ($scopes.Count) { $scopes = "&" + (($scopes | % { "scope[]=$_" }) -join "&") }
		else {$scopes = "" }
		$page = 1
		$all_jobs = @()

		do {
			$url = "https://$env:GITLAB_HOST/api/v4/projects/$repository_id/jobs?per_page=100&page=$page" + $scopes
			$page ++
			Write-Host "Load $url " -NoNewline
			$data = Load-GitService $url
			if ($data) {
				$jobs = $data | ? { !$job -or $job -eq $_.name }
				$all_jobs += $jobs
			}
			Write-Host "($($all_jobs.Count) of $count)"
		} while ($all_jobs.Count -lt $count)

		return $all_jobs
	}

	$all_jobs | Sort name, id | % {
		$job = $_
		$job.pipeline.ref -match 'refs/merge-requests/(\d+)' | Out-Null

		if ($job.created_at) { $created = [DateTime]::Parse($job.created_at).ToString() }
		if ($job.started_at) { $started = [DateTime]::Parse($job.started_at).ToString() }
		if ($job.finished_at) { $finished = [DateTime]::Parse($job.finished_at).ToString() }

		[PsCustomObject]@{
			Color = switch($job.status) {
				"created" { "33;1" }
				"pending" { "33;1" }
				"running" { "33" }
				"failed" { "31" }
				"success" { "32" }
				"canceled" { "37" }
				"skipped" { "37" }
				default { "38" }
			};
			Status = $job.status.ToUpper();
			Name = $job.name;
			ID = $job.id.toString();
			Duration = "$([int]$job.duration)";
			Author = $job.user.username;
			Pipeline = $job.pipeline.id.toString();
			MR = $matches[1];
			Created = $created;
			Started = $started;
			Finished = $finished
		}
	} | Format-Table -Property @(
		@{Label = "Status"; Expression = {[char]27 + "[" + $_.Color + "m" + $_.Status}},
		@{Label = "Name"; Expression = {$_.Name}},
		@{Label = "ID"; Expression = {$_.ID}},
		@{Label = "Duration"; Expression = {$_.Duration}},
		@{Label = "Author"; Expression = {$_.Author}},
		@{Label = "Pipeline"; Expression = {$_.Pipeline}},
		@{Label = "MR"; Expression = {$_.MR}},
		@{Label = "Created"; Expression = {$_.Created}},
		@{Label = "Started"; Expression = {$_.Started}},
		@{Label = "Finished"; Expression = {$_.Finished + [char]27 + "[0m"}}
	)
}
