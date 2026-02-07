<#
.SYNOPSIS
    Asks confirmation and accepts only y/n
.DESCRIPTION
    Highlights everything in yellow and {{text}} in green
.PARAMETER question
    String question to ask without '?'
.PARAMETER defaultValue
    Default value if nothing selected and ENTER just pressed
.PARAMETER extended
    Whether to provide additional options like 'a' for all yes and 'x' for all no
.PARAMETER result
    Predefined result
.EXAMPLE
    confirm "Are you really sure to delete {{$file}}"
    # outputs "Are you sure (y/n)?", highlights question with yellow, and $file with green, and accepts only (y/n) as answer, then returns True if y and False if n
.EXAMPLE
    confirm "Suppress warning" -extended
    # outputs "Suppress warning (y/n/a/x)?", highlights question with yellow and accepts (y/n/a/x) as answer, then returns objects with (True if y and False if n) and All
.EXAMPLE
    confirm "Enable debugging" -defaultValue y
    # outputs "Enable debugging (y/n)?", highlights question with yellow and accepts only (y/n) as answer, then returns True if y and False if n, defaulting to y
#>

Param (
    [Parameter(Mandatory = $true)][string]$question,
    [string]$defaultValue,
    [switch]$extended,
    [Nullable[boolean]]$result = $null
)

$question = $question -replace '\{\{(.*?)\}}', '{Green:$1}'

$options = switch($extended) {
    $false { "y/n" }
    $true { "y = yes, n = no, a = yes for all, x = no for all" }
}

$answers = switch($extended) {
    $false { @("y", "n") }
    $true { @("y", "n", "a", "x") }
}

if ($defaultValue) {
    if (!$answers.Contains($defaultValue)) {
        throw "Invalid default value '$defaultValue', expected one of $answers"
    }

    $options += ", default=$defaultValue"
}

Function Ask-Question($question) {
    if ($result -is [boolean]) {
        if ($result) { return "y" }
        else { return "n" }
    }

    out $question -NoNewline -ForegroundColor Yellow
    out " ($options)? " -NoNewline -ForegroundColor Yellow
    Read-Host
}

while ($true) {
    $answer = Ask-Question $question

    if (!$answer) {
        $answer = $defaultValue
    }

    if ($answers.Contains($answer)) {
        break
    }
}

switch($extended) {
    $false { $answer -eq "y" }
    $true { @{result = ($answer -eq "a" -or $answer -eq "y"); all = ($answer -eq "a" -or $answer -eq "x")} }
}
