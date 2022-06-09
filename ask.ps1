<#
.SYNOPSIS
    Ask for new value
.DESCRIPTION
    Show prompt with asking new value of existing string.
    If ENTER has pressed - just leaves string as is. Returns new value
.PARAMETER append
    Whether consider asterisk (*) as need to append this to previous value
.PARAMETER default_new_value
    Which value is set if emptiness has been input. By default it equals to old value
.EXAMPLE
    ask -value "Another commit" -old "Old commit message" -new "New commit message"
    # shows old commit message "Another commit" and asks for new commit message
.EXAMPLE
    ask -value "Another commit" -old "Old commit message" -new "New commit message" -append
    # shows old commit message "Another commit" and asks for new commit message
    # if entered "* add some lines" new commit message will be "Another commit * add some lines"
.EXAMPLE
    ask -value "Another commit" -forced_value "New commit" -old "Old commit message" -new "New commit message"
    # shows old commit message "Another commit" and set new value to "New commit" without asking
    # if entered "* add some lines" new commit message will be "Another commit * add some lines"
#>

Param (
    [Parameter(Mandatory = $true)][string]$new,
    [string]$old,
    [string]$value,
    [string]$new_value,
    [string]$default_new_value,
    [switch]$append
)

if (!$default_new_value) { $default_new_value = $value}

if ($old) { Write-Host "${old}: $value" }
Write-Host "${new}: " -NoNewline -ForegroundColor Yellow
if (!$new_value) { $new_value = Read-Host } else { Write-Host }

if ($new_value.Count -eq 0 -or $new_value[0].Count -eq 0) {
    $new_value = $default_new_value
} else {
    if ($append -and $new_value -match "^\*($| [^$])") {
        if ($new_value -eq "*") { $new_value = "" }
            else { $new_value = " " + $new_value }

        $new_value = ($value -replace "\s*\* [^\*]*$", "") + $new_value
    }
}

[console]::SetCursorPosition([console]::CursorLeft, [console]::CursorTop - 1)
Write-Host "${new}: $new_value" -ForegroundColor Green
$new_value
