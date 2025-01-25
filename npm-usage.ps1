<#
.SYNOPSIS
    Checks package.json files for usage of particular NPM library
.PARAMETER name
	Repository name
.PARAMETER library
    If specified - check for changes in package.json files from this commit, otherwise check existence of package.json files at all
#>

Param (
    [string]$name,
    [Parameter(Mandatory = $true)][string]$library
)

$results = [System.Collections.ArrayList]@();

repo $name {
	(gg package.json "[ `t]*\`"$library\`": \`"(.*)\`"" -format json -value | ConvertFrom-Json) | ? { $_.lines } | % {
		$log_format = '{\"commit\": \""%H\"", \"date\": \""%ad\"", \"message\": \""%s\""}'
		$date = "format:%Y-%m-%d %H:%M:%S"
		$log = git log -n 1 --no-patch -L "$($_.lines.line):$($_.file)" --pretty=format:$log_format --date=$date | ConvertFrom-Json;

		[void]$results.Add([PSCustomObject]@{
			Repo = $repo;
			File = $_.file;
			Library = $library;
			Version = $_.lines.value;
			Date = $log.date;
			Commit = $log.commit;
			Message = $log.message;
		})
	}
}

$results | Format-Table
