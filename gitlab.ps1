<#
.SYNOPSIS
	Updates gitlab information for current repository
.PARAMETER scan
	Scan for repositories and update all repositories info
.PARAMETER get
	Get particular repository from local json
.PARAMETER repo
	Full path to local repository. If empty - perform action for all repositories
.PARAMETER load
	Perform request to gitlab API
.PARAMETER exec
	Execute batch callback using current context
.PARAMETER method
	Method to perform GET request to gitlab API (default - GET)
.PARAMETER data
	Data to send with request
.PARAMETER private
	Whether to scan private repositories only. If false - scan repositories with membership only. If not specified - scan both.
.EXAMPLE
	gitlab -scan all
	# scan all repositories
.EXAMPLE
	gitlab -scan D:\src\scripts
	# scan repository scripts
.EXAMPLE
	gitlab -get D:\src\scripts
	# get information about repository scripts
.EXAMPLE
	gitlab -scan -get D:\src\scripts
	# scan repository scripts and get information about it
.EXAMPLE
	gitlab -scan -get all
	# scan all repositories and get information about them
.EXAMPLE
	gitlab -load https://gitlab.com/api/something
	# perform get request to https://gitlab.com/api/something
.EXAMPLE
	gitlab -load https://gitlab.com/api/change_something -method PUT -data "key=value"
	# perform put request to https://gitlab.com/api/change_something with setting key to value
.EXAMPLE
	gitlab -exec { Load-GitlabData https://gitlab.com/api/something; Load-GitlabData https://gitlab.com/api/something2;  }
	# perform 2 get requests using 1 token
#>

Param (
	[switch]$scan,
	[switch]$get,
	[string]$repo,
	[string]$load,
	[ScriptBlock]$exec,
	[string]$method = "GET",
	[Hashtable]$data = @{},
	[nullable[bool]]$private = $null
)

$json = $null
if (Test-Path $env:ENV_REPOSITORIES_FILE) {
	$json = [System.Collections.ArrayList](file $env:ENV_REPOSITORIES_FILE | ConvertFrom-Json)
}

if (!$json) { $json = [System.Collections.ArrayList]@() }

if ($scan -or $get) {
	if (!$repo) {
		throw "Please specify local `$repo or 'all'"
	}
}

if ($scan -or $load -or $exec) {
	[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	Write-Host "Getting access token..."
	vars -op $env:OP_USER -aws $env:AWS_PROFILE -names "gitlab_access_token_amend_$($env:WORKSPACE_NAME)" -silent
	$headers = @{"PRIVATE-TOKEN" = (Get-Variable -Name "gitlab_access_token_amend_$($env:WORKSPACE_NAME)" -Value) }
}

Function Load-GitlabData($url, $method = "GET") {
	if ($data.Keys.Length) { $body = $data | ConvertTo-Json -Compress }
	return (Invoke-WebRequest -Headers $headers -Method $method -Body $body -ContentType "application/json" $url -UseBasicParsing).Content | ConvertFrom-Json
}

Function Get-Local($this_repo) {
	if ($this_repo -eq "all") { return $null }
	return $this_repo.Replace($env:GIT_ROOT, "").Replace("\", "/").Trim("/")
}

$shared_repositories = $env:SHARED_REPOSITORIES | ConvertFrom-Json

if ($scan) {
	if ($repo -eq "all") {
		$json.Clear()
	}

	Write-Host "Scanning repositories..."
	$repositories_all = @{}

	if ($repo -eq "all") {
		$shared_repositories | % {
			$repository = Load-GitlabData "https://gitlab.com/api/v4/projects/$_"
			$repositories_all[$repository.id] = $repository
		}
	}

	$options = @()
	if ($private -ne $true) { $options += "membership=true" }
	if ($private -ne $false) { $options += "visibility=private" }

	$options | % {
		$page = 1
		$search_url = "https://gitlab.com/api/v4/projects?$_&per_page=100"

		do {
			$repositories = Load-GitlabData "$search_url&page=$page"

			$repositories | % {
				if ($shared_repositories.Contains($_.id)) { return }
				$repositories_all[$_.id] = $_
			}

			$page ++
		}
		while ($repositories.Length -gt 0)
	}

	Write-Host "Serializing..."

	$directories = switch ($repo) {
		"all" { Get-ChildItem -Path $env:GIT_ROOT -Filter ".git" -Recurse -Force -Depth $env:GIT_DEPTH }
		default { Get-ChildItem -Path $repo -Filter ".git" -Force }
	}

	if ($directories.GetType().BaseType -ne [System.Array]) { $directories = @($directories) }

	$directories | % {
		$this_repo = Split-Path $_.FullName -Parent
		$this_name = Split-Path $this_repo -Leaf
		$this_local = Get-Local $this_repo
		$this_remote = git -C $this_repo config --get remote.origin.url

		$existing = $json | ? { $_.local -eq $this_local }
		$existing | % { $json.Remove($_) }

		$repositories_all.Values | ? { $_.ssh_url_to_repo -eq $this_remote } | % {
			$json.Add([PSCustomObject]@{
				id = $_.id
				name = $this_name
				local = $this_local
				remote = $this_remote
				default_branch = $_.default_branch
			}) | Out-Null
		}
	}

	$json = $json | Sort { !$shared_repositories.Contains($_.id) }, local
	$content = $json | ConvertTo-Json
	if ($content) { file $env:ENV_REPOSITORIES_FILE $content }
	Write-Host "Done!"
}

if ($get) {
	$local = Get-Local $repo
	$json | ? { !$local -or $_.local -eq $local }
}

if ($load) {
	Load-GitlabData -url $load -method $method
}

if ($exec) {
	Invoke-Command $exec
}
