<#
.SYNOPSIS
    Perform operation with file
.DESCRIPTION
    Shortcut to reading/writing from files using ut8 without BOM
.PARAMETER filename
    Path to file
.PARAMETER content
	Content (if write or append)
.PARAMETER append
    Whether to append
.PARAMETER bytes
    Whether to read/write bytes instead of text
.PARAMETER lines
    Whether to read/write lines instead of text
.EXAMPLE
    file list.txt
    # read content of list.txt
.EXAMPLE
    file list.txt test
    # write "test" to list.txt
.EXAMPLE
    file list.txt test -append 
    # append "test" to list.txt
.EXAMPLE
    file list.txt -bytes
    # read bytes from list.txt
.EXAMPLE
    file list.txt -bytes test
    # write bytes from "test" to list.txt
.EXAMPLE
    file list.txt -lines
    # read -lines from list.txt
.EXAMPLE
    file list.txt -lines test
    # write -lines from "test" to list.txt
#>

Param (
	[Parameter(Mandatory = $true)][string]$filename,
	$content,
	[switch]$append,
	[switch]$bytes,
	[switch]$lines
)

if ($bytes -and $lines) {
	throw "Cannot specify both -bytes and -lines"
}

if (![System.IO.Path]::IsPathRooted($filename)) {
	$filename = Join-Path $pwd.Path $filename
}

$utf8 = New-Object System.Text.UTF8Encoding $false

switch ($true) {
	$bytes {
		if ($content -ne $null) {
			if ($append) {
				$content = $utf8.GetString($content)
				[System.IO.File]::AppendAllText($filename, $content, $utf8)
			} else {
				[System.IO.File]::WriteAllBytes($filename, $content)
			}
		} else {
			[System.IO.File]::ReadAllBytes($filename)
		}
	}

	$lines {
		if ($content -ne $null) {
			if ($append) {
				$content = ($content -join "`r`n") + "`r`n"
				[System.IO.File]::AppendAllText($filename, $content, $utf8)
			} else {
				[System.IO.File]::WriteAllLines($filename, $content, $utf8)
			}
		} else {
			[System.IO.File]::ReadAllLines($filename, $utf8)
		}
	}

	default {
		if ($content -ne $null) {
			if ($append) {
				[System.IO.File]::AppendAllText($filename, $content, $utf8)
			} else {
				[System.IO.File]::WriteAllText($filename, $content, $utf8)
			}
		} else {
			[System.IO.File]::ReadAllText($filename, $utf8)
		}
	}
}
