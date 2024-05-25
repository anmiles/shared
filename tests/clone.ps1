Function Test {
    Param (
        [Parameter(Mandatory = $true)][string]$data
    )

	$service, $name = $data -split " "
	$env_backup = $env:GIT_SERVICE, $env:GITHUB_USER, $env:GITLAB_USER, $env:GITLAB_HOST

	try {
		$env:GIT_SERVICE = $service
		$env:GITHUB_USER = "github_user"
		$env:GITLAB_USER = "gitlab_user"
		$env:GITLAB_HOST = "custom.gitlab.com"

		$result = clone $name -test
	} catch {
		throw $_
	} finally {
		$env:GIT_SERVICE, $env:GITHUB_USER, $env:GITLAB_USER, $env:GITLAB_HOST = $env_backup
	}

    return $result
}

@(
    @{ Input = "github repo"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
    @{ Input = "gitlab repo"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }

	@{ Input = "github custom_user/repo"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab custom_group/repo"; Expected = "repo | custom_group/repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab custom_group/child/repo"; Expected = "repo | custom_group/child/repo | git@custom.gitlab.com:custom_group/child/repo.git" }

	@{ Input = "github https://github.com/github_user/repo"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
	@{ Input = "github https://github.com/custom_user/repo"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/gitlab_user/repo"; Expected = "repo | repo | git@gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/repo"; Expected = "repo | custom_group/repo | git@gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/child/repo"; Expected = "repo | custom_group/child/repo | git@gitlab.com:custom_group/child/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/gitlab_user/repo"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/repo"; Expected = "repo | custom_group/repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/child/repo"; Expected = "repo | custom_group/child/repo | git@custom.gitlab.com:custom_group/child/repo.git" }

	@{ Input = "github https://github.com/github_user/repo.git"; Expected = "repo | repo | https://github.com/github_user/repo.git" }
	@{ Input = "github https://github.com/custom_user/repo.git"; Expected = "repo | repo | https://github.com/custom_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/gitlab_user/repo.git"; Expected = "repo | repo | https://gitlab.com/gitlab_user/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/repo.git"; Expected = "repo | custom_group/repo | https://gitlab.com/custom_group/repo.git" }
    @{ Input = "gitlab https://gitlab.com/custom_group/child/repo.git"; Expected = "repo | custom_group/child/repo | https://gitlab.com/custom_group/child/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/gitlab_user/repo.git"; Expected = "repo | repo | https://custom.gitlab.com/gitlab_user/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/repo.git"; Expected = "repo | custom_group/repo | https://custom.gitlab.com/custom_group/repo.git" }
    @{ Input = "gitlab https://custom.gitlab.com/custom_group/child/repo.git"; Expected = "repo | custom_group/child/repo | https://custom.gitlab.com/custom_group/child/repo.git" }

	@{ Input = "github git@github.com:github_user/repo.git"; Expected = "repo | repo | git@github.com:github_user/repo.git" }
	@{ Input = "github git@github.com:custom_user/repo.git"; Expected = "repo | repo | git@github.com:custom_user/repo.git" }
    @{ Input = "gitlab git@gitlab.com:gitlab_user/repo.git"; Expected = "repo | repo | git@gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab git@gitlab.com:custom_group/repo.git"; Expected = "repo | custom_group/repo | git@gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab git@gitlab.com:custom_group/child/repo.git"; Expected = "repo | custom_group/child/repo | git@gitlab.com:custom_group/child/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:gitlab_user/repo.git"; Expected = "repo | repo | git@custom.gitlab.com:gitlab_user/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:custom_group/repo.git"; Expected = "repo | custom_group/repo | git@custom.gitlab.com:custom_group/repo.git" }
    @{ Input = "gitlab git@custom.gitlab.com:custom_group/child/repo.git"; Expected = "repo | custom_group/child/repo | git@custom.gitlab.com:custom_group/child/repo.git" }
)
