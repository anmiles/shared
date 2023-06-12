<#
.SYNOPSIS
    Restart processes
.DESCRIPTION
    Restart all instances of process of selected name
.PARAMETER name
    Process name
.EXAMPLE
    restart explorer
#>

Param (
    [Parameter(Mandatory = $true)][string[]]$name
)

Get-Process -Name $name | % {
	Write-Host $_.Id
	Stop-Process $_.Id;
	schtasks /create /sc once /tn RestartTask /tr "'$($_.Path)'" /sd 9999/12/31 /st "00:00" /ri 0 /et "00:01" /z
	schtasks /run /tn RestartTask
	schtasks /delete /tn RestartTask /f
}
