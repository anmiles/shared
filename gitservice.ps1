<#
.SYNOPSIS
	Updates gitservice (gitlab or github) information for current repository
.PARAMETER scan
	Scan for repositories and update all repositories info
.PARAMETER get
	Get particular repository from local json
.PARAMETER repo
	Full path to local repository. If empty - perform action for all repositories
.PARAMETER load
	Perform request to gitservice API. Works only with a service specified as $env:GIT_SERVICE
.PARAMETER token
	Type of token to use for requests
.PARAMETER exec
	Execute batch callback using current context. Works only with a service specified as $env:GIT_SERVICE
.PARAMETER method
	Method to perform GET request to gitservice API (default - GET)
.PARAMETER data
	Data to send with request
.PARAMETER private
	Whether to scan private repositories only. If false - scan repositories with membership only. If not specified - scan both.
.EXAMPLE
	gitservice -scan all
	# scan all repositories
.EXAMPLE
	gitservice -scan D:\src\scripts
	# scan repository scripts
.EXAMPLE
	gitservice -get D:\src\scripts
	# get information about repository scripts
.EXAMPLE
	gitservice -scan -get D:\src\scripts
	# scan repository scripts and get information about it
.EXAMPLE
	gitservice -scan -get all
	# scan all repositories and get information about them
.EXAMPLE
	gitservice -load https://$env:GITLAB_HOST/api/something
	# perform get request to https://$env:GITLAB_HOST/api/something
	# works only if $env:GIT_SERVICE = "gitlab"
.EXAMPLE
	gitservice -load https://api.github.com/change_something -method PUT -data @{key = "value"}
	# perform put request to https://api.github.com/change_something with setting key to value
	# works only if $env:GIT_SERVICE = "github"
.EXAMPLE
	gitservice -exec { Load-GitService https://$env:GITLAB_HOST/api/something; Load-GitService https://$env:GITLAB_HOST/api/something2;  }
	# perform 2 get requests using 1 token
	# works only if $env:GIT_SERVICE = "gitlab"
#>

Param (
	[switch]$scan,
	[switch]$get,
	[string]$repo,
	[string]$load,
	[string]$token = "repos",
	[ScriptBlock]$exec,
	[string]$method = "GET",
	[Hashtable]$data = @{},
	[nullable[bool]]$private = $null
)

$default_remote_name = "origin"
$service = gitselect
$user = [Environment]::GetEnvironmentVariable("$($service)_USER")

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

$git_default_host = gitselect -github {
    "api.github.com"
} -gitlab {
    if ($env:GITLAB_HOST) {
        $env:GITLAB_HOST
    } else {
        "gitlab.com"
    }
}

if ($scan -or $load -or $exec) {
	[System.Net.ServicePointManager]::SecurityProtocol = 'Tls12'
	Write-Host "Getting access token..."

	$token_suffix = if ($env:GIT_SERVICE -eq "gitlab" -and $env:GITLAB_HOST) {
		"_$($env:GITLAB_HOST -split '[^A-Za-z0-9]+' -join '_')"
	} else {
		""
	}

	$token_variable = "$($service)_token_$($token)_$($user)$($token_suffix)"
	vars -op $env:OP_USER -aws $env:AWS_PROFILE -names $token_variable -silent
	$token_value = Get-Variable -Name $token_variable -Value
	if (!$token_value) { throw "$token_variable missing" }

	$headers = gitselect -github { @{
		"Accept" = "application/vnd.github+json"
		"Authorization" = "Bearer $token_value"
		"X-GitHub-Api-Version" = "2022-11-28"
	} } -gitlab { @{
		"PRIVATE-TOKEN" = $token_value
	} }
}

Function Load-GitService($url, $method = "GET", $data = @{}) {
	# Write-Host "url = $url"
	# Write-Host "data = $($data | ConvertTo-Json)"

	if ($data.Keys.Length) {
		if ($method -eq "GET") {
			$data.Keys | % {
				$symbol = if ($url.Contains("?")) { "&" } else { "?" }
				$url += "$($symbol)$($_)=$($data[$_])"
			}
		} else {
			$body = $data | ConvertTo-Json -Compress
		}
	} else {
		$body = $null
	}

	# Write-Host "Invoke-WebRequest -Method $method -Body $body $url -UseBasicParsing"
	$response = Invoke-WebRequest -Headers $headers -Method $method -Body $body -ContentType "application/json" $url -UseBasicParsing

	if ($response.Headers["Content-Type"].StartsWith("application/json")) {
		return $response.Content | ConvertFrom-Json
	} else {
		return $response.Content
	}
}

Function Get-Local($this_repo) {
	if ($this_repo -eq "all") { return $null }
	return $this_repo.Replace($env:GIT_ROOT, "").Replace("\", "/").Trim("/")
}

Function Get-Remote($this_repo) {
	if (git -C $this_repo branch) {
		$branch = git -C $this_repo rev-parse --abbrev-ref HEAD
		$remote_name = git -C $this_repo config "branch.$branch.remote"

		if (!$remote_name) {
			$remote_line = $(git -C $this_repo config --list) -match 'remote\.(.*)\.url='

			if ($remote_line -match 'remote\.(.*)\.url=') {
				$remote_name = $matches[1]
			} else {
				$remote_name = $default_remote_name
			}
		}
	} else {
		$remote_name = $default_remote_name
	}

	$remote = git -C $this_repo config --get "remote.$remote_name.url"

	if (!$remote) {
		out "No remote detected for this_repo = {Yellow:$this_repo} and branch = '{Yellow:$branch}' and remote_name = '{Yellow:$remote_name}'"
	}

	return $remote
}

$shared_repositories = $env:SHARED_REPOSITORIES | ConvertFrom-Json

if ($scan) {
	if ($repo -eq "all") {
		$json.Clear()
	}

	$repositories_all = @{}

	if ($env:LOCAL_REPOSITORIES_ROOT) {
		Write-Host "Scanning local repositories..."

		Get-ChildItem $env:LOCAL_REPOSITORIES_ROOT -Directory | % {
			$id = shpath $_.FullName -native
			$default_branch = git -C $_.FullName rev-parse --abbrev-ref HEAD

			$repositories_all[$id] = @{
				id = $id
				url = $id
				public = $false
				default_branch = $default_branch
			}
		}
	}

	if ($shared_repositories) {
		Write-Host "Scanning shared repositories..."

		if ($repo -eq "all") {
			$shared_repositories | % {
				$repository = gitselect -github {
					Load-GitService "https://$git_default_host/repos/$user/$_"
				} -gitlab {
					Load-GitService "https://$git_default_host/api/v4/projects/$_"
				}

				$repository.url = gitselect -github { $repository.ssh_url } -gitlab { $repository.ssh_url_to_repo }
				$repositories_all[$repository.id] = $repository
			}
		}
	}

	Write-Host "Scanning remote repositories..."

	$options = gitselect -github { "" } -gitlab {
		$options = @()
		if ($private -ne $true) { $options += "membership=true" }
		if ($private -ne $false) { $options += "visibility=private" }
		return $options
	}

	$options | % {
		$page = 1

		do {
			$repositories = gitselect -github {
				Load-GitService "https://$git_default_host/user/repos" -data @{ per_page = 100; page = $page }
			} -gitlab {
				Load-GitService "https://$git_default_host/api/v4/projects?$_&per_page=100&page=$page"
			}

			$repositories | % {
				$repository = $_
				$identifier = gitselect -github { $repository.name } -gitlab { $repository.id }
				if ($shared_repositories.Contains($identifier)) { return }

				$url = gitselect -github { $repository.ssh_url } -gitlab { $repository.ssh_url_to_repo }
				Add-Member -InputObject $repository -NotePropertyName "url" -NotePropertyValue $url -Force

				$repositories_all[$repository.id] = $repository
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
		$this_remote = Get-Remote $this_repo

		if (!$this_remote) { return }

		$existing = $json | ? { $_.local -eq $this_local }
		$existing | % { $json.Remove($_) }

		$repositories_match = $repositories_all.Values | ? { $_.url -eq $this_remote }

		if ($repositories_match) {
			$repositories_match | % {
				$json.Add([PSCustomObject]@{
					id = $_.id
					name = $this_name
					local = $this_local
					remote = $this_remote
					public = ($_.visibility -eq "public")
					default_branch = $_.default_branch
				}) | Out-Null
			}
		} else {
			out "No remote matched for this_repo = {Yellow:$this_repo} and this_remote = '{Yellow:$this_remote}'"
		}
	}

	if (Test-Path $env:ENV_ORDER_REPOSITORIES_FILE) {
		$order_json =  [System.Collections.ArrayList](file $env:ENV_ORDER_REPOSITORIES_FILE | ConvertFrom-Json)
		$ordered_names = $order_json | % { $_.name }
		$json = $json | Sort { $ordered_names.IndexOf($_.name) }
	} else {
		$json = $json | Sort {
			$item = $_;
			return !$shared_repositories.Contains((gitselect -github { $item.name } -gitlab { $item.id }))
		}, local
	}

	$content = $json | ConvertTo-Json
	if ($content) { file $env:ENV_REPOSITORIES_FILE $content }
	Write-Host "Done!"
}

if ($get) {
	$local = Get-Local $repo
	$json | ? { !$local -or $_.local -eq $local }
}

if ($load) {
	Load-GitService -url $load -method $method -data $data
}

if ($exec) {
	Invoke-Command $exec
}
