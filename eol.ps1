<#
.SYNOPSIS
    Convert line-breaks
.PARAMETER lf
    Whether convert to LF
.PARAMETER crlf
    Whether convert to CRLF
.PARAMETER path
    Relative path of the directory on whether to perform converting
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    eol -lf
    # convert all line-breaks to LF in the current repository
.EXAMPLE
    eol -crlf win32
    # convert all line-breaks to LF in the directory "win32" under current repository
#>

Param (
    [string]$path = ".",
    [switch]$lf,
    [switch]$crlf,
    [switch]$quiet
)

if ($lf -eq $crlf) {
    out "{Red:Need to specify one and only one switch of [ lf | crlf ]"
    exit
}

if ($crlf) {
    git config core.autocrlf true
    $regex_wrong = '(?<!\r)\n'
    $replace_correct = "`r`n"
}

if ($lf) {
    git config core.autocrlf input
    $regex_wrong = '\r\n'
    $replace_correct = "`n"
}

repo -name this -quiet:$quiet -action {
    git grep -e . --name-only -I --untracked --exclude-standard $path/* | % {
        $filename_relative = $_.Replace("[", "``[").Replace("]", "``]")
        $filename = (Join-Path $repo $filename_relative | Resolve-Path).Path

        try {
            $content = file $filename
        }
        catch {
            out "Error when reading filename '{Yellow:$filename}' where relative filename is '{Yellow:$filename_relative}': $_" -ForegroundColor Red
            exit 1
        }

        if ($content -notmatch $regex_wrong) { return }
    
        if (!$quiet) { out "{Yellow:> $filename}" }
        $content = $content -replace $regex_wrong, $replace_correct
        file $filename $content
    }
}
