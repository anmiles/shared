<#
.SYNOPSIS
    Launch standard npm commands in separate Conemu terminals
.PARAMETER noExit
    Do not exit on pass
#>

Param (
    [switch]$noExit
)

$commands = @(
	@{ name = "build"; console= "s1T50H"; },
	@{ name = "lint";  console= "s1T75V"; },
	@{ name = "test";  console= "s2T75V"; }
)

$commands| % {
	iex "powershell { `
		Write-Host `"$($_.name.ToUpper())`n--------------------------------`" -ForegroundColor Yellow `
		$env:GIT_ROOT\env.ps1; `
		npm run $($_.name); `
		if (`$LastExitCode -eq 0) { `
			Write-Host `"--------------------------------`n$($_.name.ToUpper()) PASSED`" -ForegroundColor Green `
			if (`$noExit) { Read-Host } `
		} else { `
			Write-Host `"--------------------------------`n$($_.name.ToUpper()) FAILED`" -ForegroundColor Red `
			Read-Host `
		} `
	} -new_console:$($_.console):n:t:$($_.name)"
}
