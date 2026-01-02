<#
.SYNOPSIS
	Non-blocking MessageBox
.PARAMETER message
	Message to send
.PARAMETER title
	Optional title
.PARAMETER icon
	MessageBox icon
.PARAMETER delay
	Wait n milliseconds before showing a message
#>

Param (
	[Parameter(Mandatory = $true)][string]$message,
	[string]$title,
	[ValidateSet('OK', 'OKCancel', 'YesNoCancel', 'YesNo')][string]$buttons = "OK",
	[ValidateSet('info', 'warning', 'error')][string]$icon = "info",
	[int]$delay = 0
)

Add-Type -AssemblyName PresentationFramework

if ($delay) {
	Start-Sleep -Milliseconds $delay
}

$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.Open()

$ps = [powershell]::Create().AddScript({
	Param ($message, $title, $buttons, $icon)
	[System.Windows.MessageBox]::Show($message, $title, $buttons, $icon)
}).AddArgument($message).AddArgument($title).AddArgument($buttons).AddArgument($icon)

$ps.Runspace = $runspace
[void]$ps.BeginInvoke()
