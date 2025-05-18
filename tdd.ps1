<#
.SYNOPSIS
    Wrapper to run `npm run test:watch:coverage` for one file or all files
.PARAMETER lib
    Specific lib to test
.PARAMETER inspect
    Whether to inspect test with inspect-brk
.EXAMPLE
    tdd
    # run tdd for current repo
.EXAMPLE
    tdd parser/video
    # run tdd for all tests in src/lib/parser/video.ts
.EXAMPLE
    tdd parser/video should parse correctly
    # run tdd for "should parse correctly" test in src/lib/parser/video.ts
#>

Param (
    [string]$lib,
    [switch]$inspect,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$specs
)

$lib = if ($lib) { "src/lib/$lib" } else { $null }

npr test -watch -coverage -inspect:$inspect -lib $lib -specs $specs
