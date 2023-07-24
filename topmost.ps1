<#
.SYNOPSIS
    Make window always on top
.PARAMETER process
    Process id
.PARAMETER handle
    Window handle
.PARAMETER title
    Window title
#>

Param (
    [int]$handle,
    [int]$process,
    [string]$title
)

$user32Lib = @"
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(IntPtr sClassName, String sAppName);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);
"@

$user32 = Add-Type -Namespace User32Functions -Name User32Functions -MemberDefinition $user32Lib -PassThru

if (!$handle) {
    if (!$process -and !$title) {
        throw "Expected either handle or process or title set"
    }

    if ($process) {
        $handle = (Get-Process -Id $process).MainWindowHandle
    }

    if ($title) {
        $handle = $user32::FindWindow([IntPtr]::Zero, $title)
    }
}

[void]$user32::SetWindowPos([System.IntPtr]$handle, -1, 0, 0, 0, 0, 0x53)
