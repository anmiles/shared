<#
.SYNOPSIS
    Grep specified text in specified files existing in git
.PARAMETER file_pattern
    Pattern to search the file
.PARAMETER text_pattern
    Pattern to search the text in the file
.EXAMPLE
    gg '\.ts$' import
    # search all imports in all *.ts files in current repository
#>

Param (
    [string]$file_pattern,
    [string]$text_pattern
)

git ls-files | grep $file_pattern | % {
    $file = $_

    if (!(Test-Path $file)) {
        return
    }

    if ($text_pattern) {
        grep $text_pattern ($file.Replace("/", "\\")) | % { "$file`t$_"}
    } else {
        "$file"
    }
}
