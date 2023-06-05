<#
.SYNOPSIS
    Wrapper to run `npm run test:watch:coverage` for one file or all files
.PARAMETER test
    Specific file to test (if action = test)
#>

Param (
    [string]$test
)

npr test -w -c $test
