<#
.DESCRIPTION
    Make window always on top
.PARAMETER title
    Window title
.PARAMETER position
    Window position as array @($left, $top, $width, $height)
#>

Param (
    [string]$title,
    [int[]]$position = @()
)

$handle = window $title

if ($handle -ne 0) {
    if ($position.Count -eq 4) {
        [User32]::SetWindowPos([System.IntPtr]$handle, -1, $position[0], $position[1], $position[2], $position[3], 0x0)
    } else {
        [User32]::SetWindowPos([System.IntPtr]$handle, -1, 0, 0, 0, 0, 0x53)
    }
    exit 0
} else {
    exit 1
}
