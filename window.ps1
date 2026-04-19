<#
.DESCRIPTION
	Get window handle by title
.PARAMETER title
	Window title
#>

Param (
    [string]$title
)

user32
$handle = [User32]::FindWindow([IntPtr]::Zero, $title)
$handle
