<#
.SYNOPSIS
    Grep specified text in specified files existing in git
.PARAMETER file_pattern
    Pattern to search the file
.PARAMETER text_pattern
    Pattern to search the text in the file
.PARAMETER E
    Whether to perform fully-functional regex search with grep
.EXAMPLE
    gg '\.ts$' import
    # search all imports in all *.ts files in current repository
#>

Param (
    [string]$file_pattern,
    [string]$text_pattern,
    [switch]$E
)

git ls-files | grep $file_pattern | % {
    $file = $_

    if (!(Test-Path $file)) {
        return
    }

    if ($text_pattern) {
        $arguments = @()
        if ($E) { $arguments += "-E" }
        $arguments += $text_pattern
        $arguments += $file.Replace("/", "\\")
        (& grep $arguments) | % { "$file`t$_"}
    } else {
        "$file"
    }
}
