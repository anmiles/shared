<#
.DESCRIPTION
	Get window handle by title
.PARAMETER title
	Window title
#>

Param (
    [string]$title
)

Add-Type @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class User32 {
    [DllImport("user32.dll", CharSet = CharSet.Unicode)]
    public static extern IntPtr FindWindow(IntPtr sClassName, String sAppName);

	[DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X,int Y, int cx, int cy, uint uFlags);
}
"@

$handle = [User32]::FindWindow([IntPtr]::Zero, $title)
$handle
