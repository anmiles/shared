<#
.SYNOPSIS
	Non-blocking MessageBox
.PARAMETER message
	Message to send
.PARAMETER title
	Optional title
.PARAMETER icon
	MessageBox icon
#>

Param (
	[Parameter(Mandatory = $true)][string]$message,
	[string]$title,
	[ValidateSet('OK', 'OKCancel', 'YesNoCancel', 'YesNo')][string]$buttons = "OK",
	[ValidateSet('info', 'warning', 'error')][string]$icon = "info"
)

Add-Type -AssemblyName PresentationFramework

$runspace = [RunspaceFactory]::CreateRunspace()
$runspace.Open()

$ps = [powershell]::Create().AddScript({
	Param ($message, $title, $buttons, $icon)
	[System.Windows.MessageBox]::Show($message, $title, $buttons, $icon)
}).AddArgument($message).AddArgument($title).AddArgument($buttons).AddArgument($icon)

$ps.Runspace = $runspace
[void]$ps.BeginInvoke()
