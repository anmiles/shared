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
	@{ name = "test"; console= "s1T33H"; },
	@{ name = "build";  console= "s1T50H"; },
	@{ name = "lint";  console= "s50V"; }
)

$commands| % {
	iex "powershell { `
		Write-Host `"$($_.name.ToUpper())`n--------------------------------`" -ForegroundColor Yellow `
		$env:GIT_ROOT\env.ps1; `
		npm run $($_.name); `
		`$result = `$LastExitCode -eq 0
		`$resultText = if (`$result) { `"PASSED`" } else { `"FAILED`" }
		`$resultColor = if (`$result) { `"Green`" } else { `"Red`" }
		Write-Host `"--------------------------------`n$($_.name.ToUpper()) `$resultText`" -ForegroundColor `$resultColor`
		Read-Host
	} $( if ($_.console) { "-new_console:$($_.console):n:t:$($_.name)" })"
}
