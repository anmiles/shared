Function Test {
    Param (
        [Parameter(Mandatory = $true)][string]$data
    )

	$service, $name = $data -split " "
    $service, $private = $service -split ":"
    $private = $private -eq "private"
	$env_backup = $env:GIT_SERVICE, $env:GITHUB_USER, $env:GITLAB_USER, $env:GITLAB_HOST

	try {
		$env:GIT_SERVICE = $service
		$env:GITHUB_USER = "github_user"
		$env:GITLAB_USER = "gitlab_user"
		$env:GITLAB_GROUP = "gitlab_group"
		$env:GITLAB_HOST = "custom.gitlab.com"

		$result = clone $name -test -private:$private
	} catch {
		throw $_
	} finally {
		$env:GIT_SERVICE, $env:GITHUB_USER, $env:GITLAB_USER, $env:GITLAB_GROUP, $env:GITLAB_HOST = $env_backup
	}

    return $result
}

@(
    @{ Input = "github repo"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
    @{ Input = "gitlab repo"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_group/repo.git" }
    @{ Input = "gitlab:private repo"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }

    @{ Input = "gitlab parent/repo"; Expected = "repo | parent/repo | git@custom.gitlab.com:gitlab_group/parent/repo.git" }
    @{ Input = "gitlab:private parent/repo"; Expected = "repo | parent/repo | git@custom.gitlab.com:gitlab_user/parent/repo.git" }

	@{ Input = "github https://github.com/github_user/repo"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
	@{ Input = "github https://github.com/custom_user/repo"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/gitlab_user/repo"; Expected = "repo | repo | https://gitlab.com/gitlab_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/repo"; Expected = "repo | repo | https://gitlab.com/custom_group/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/parent/repo"; Expected = "repo | parent/repo | https://gitlab.com/custom_group/parent/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/gitlab_user/repo"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/repo"; Expected = "repo | repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/parent/repo"; Expected = "repo | parent/repo | git@custom.gitlab.com:custom_group/parent/repo.git" }

	@{ Input = "github https://github.com/github_user/repo.git"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
	@{ Input = "github https://github.com/custom_user/repo.git"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/gitlab_user/repo.git"; Expected = "repo | repo | https://gitlab.com/gitlab_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/repo.git"; Expected = "repo | repo | https://gitlab.com/custom_group/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/parent/repo.git"; Expected = "repo | parent/repo | https://gitlab.com/custom_group/parent/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/gitlab_user/repo.git"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/repo.git"; Expected = "repo | repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/parent/repo.git"; Expected = "repo | parent/repo | git@custom.gitlab.com:custom_group/parent/repo.git" }

	@{ Input = "github git@github.com:github_user/repo.git"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
	@{ Input = "github git@github.com:custom_user/repo.git"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab git@gitlab.com:gitlab_user/repo.git"; Expected = "repo | repo | git@gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab git@gitlab.com:custom_group/repo.git"; Expected = "repo | repo | git@gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab git@gitlab.com:custom_group/parent/repo.git"; Expected = "repo | parent/repo | git@gitlab.com:custom_group/parent/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:gitlab_user/repo.git"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:custom_group/repo.git"; Expected = "repo | repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:custom_group/parent/repo.git"; Expected = "repo | parent/repo | git@custom.gitlab.com:custom_group/parent/repo.git" }
)
