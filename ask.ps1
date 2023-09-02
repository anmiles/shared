<#
.SYNOPSIS
    Ask for new value
.DESCRIPTION
    Show prompt with asking new value of existing string.
    If ENTER has pressed - just leaves string as is. Returns new value
.PARAMETER default_new_value
    Which value is set if emptiness has been input. By default it equals to old value
.PARAMETER append
    Whether consider asterisk (*) as need to append this to previous value
.PARAMETER silent
    Whether to not output anything, never ask new_value even if it's empty
.EXAMPLE
    ask -value "Another commit" -old "Old commit message" -new "New commit message"
    # shows old commit message "Another commit" and asks for new commit message
.EXAMPLE
    ask -value "Another commit" -old "Old commit message" -new "New commit message" -append
    # shows old commit message "Another commit" and asks for new commit message
    # if entered "* add some lines" new commit message will be "Another commit * add some lines"
.EXAMPLE
    ask -value "Another commit" new_value "New commit" -old "Old commit message" -new "New commit message"
    # shows old commit message "Another commit" and set new value to "New commit" without asking
    # if entered "* add some lines" new commit message will be "Another commit * add some lines"
#>

Param (
    [string]$new = "Value",
    [string]$old,
    [string]$value,
    [string]$new_value,
    [string]$default_new_value,
    [switch]$append,
    [switch]$secure,
    [switch]$silent
)

if (!$default_new_value) { $default_new_value = $value}

if (!$silent) {
    if ($old) { Write-Host "${old}: $value" }
    Write-Host "${new}: " -NoNewline -ForegroundColor Yellow
}

if (!$silent) {
    if (!$new_value) {
        $new_value = switch ($secure) {
            $true { [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR((Read-Host -AsSecureString))) }
            $false { Read-Host }
        }
    } else { Write-Host }
}

if ($new_value.Count -eq 0 -or $new_value[0].Count -eq 0) {
    $new_value = $default_new_value
} else {
    if ($append) {
        if ($new_value -match "^\*\s*$") {
            $new_value = $value -replace "\s*\*.*", ""
        }
        if ($new_value -match "^\*\s+(.+)") {
            $new_value = $value -replace "\s*\*\s+.*$", ""
            $new_value = $new_value + " * " + $matches[1]
        }
        if ($new_value -match "^\*\*(\s+(.*))?") {
            $new_value = $value -replace "\s*\*\s+[^\*]*$", ""
            if ($matches[2]) { $new_value = $new_value + " * " + $matches[2] }
        }
        if ($new_value -match "^\*\+(\s+(.*))?") {
            $new_value = $value
            if ($matches[2]) { $new_value = $new_value + " * " + $matches[2] }
        }
        if ($new_value -match "^\*\-(\s+(.*))?") {
            $new_value = $value -replace "\s*\*\s+[^\*]*(\s*\*\s+[^\*]*)?$", ""
            if ($matches[2]) { $new_value = $new_value + " * " + $matches[2] }
        }
    }
}

if (!$silent) {
    $new_value_output = switch($secure){ $true { $new_value -replace '.', "*" } default { $new_value } }
    [console]::SetCursorPosition([console]::CursorLeft, [console]::CursorTop - 1)
    Write-Host "${new}: $new_value_output" -ForegroundColor Green
}

$new_value
