<#
.SYNOPSIS
    Show all symlinks
.PARAMETER path
    Path to directory
.PARAMETER recurse
    Whether to recurse into subdirectories
#>

Param (
    [string]$path = ".",
    [switch]$recurse
)

$path = $path.TrimEnd('/', '\')

Function ToUpperCamelCase($str) {
    return $str.SubString(0, 1).ToUpper() + $str.SubString(1)
}

$path = ToUpperCamelCase($path)

Get-ChildItem $path -Recurse:$recurse | ? {
    $_.Attributes -band [IO.FileAttributes]::ReparsePoint
} | Format-Table @(
    "LinkType",
    @{ Label = "Path";   Expression = { ToUpperCamelCase($_.FullName).Replace($path, "") } },
    @{ Label = "Target"; Expression = { ToUpperCamelCase($_.Target[0]) } }
)
