<#
.SYNOPSIS
    Perform checking over collection of tests
.PARAMETER filename
    PS1 filename returning collection of tests; must contain only alphanumeric characters, dots, hyphens and underscores
.PARAMETER separator
    String to separate items of array
#>

Param (
    [ValidatePattern("^[A-Za-z0-9\.\-_]+$")][Parameter(Mandatory = $true)][string]$filename,
    [string]$separator = " | "
)

$file = Join-Path $PSScriptRoot "tests/$filename.ps1"
if (!(Test-Path $file)) { throw "File $file doesn't exist" }

Function Stringify($obj) {
    $str = switch ($obj.GetType().IsArray) { $true { $obj -join $separator } $false { $obj.ToString() } }
    return $str
}

Import-Module $file -Force | % {
    $test = $_
    $test.Actual = Stringify(Test($test.Input))
    $test.Input = Stringify($test.Input)
    $test.Expected = Stringify($test.Expected)

    [PsCustomObject]@{
        Input = $test.Input;
        Actual = $test.Actual;
        Expected = $test.Expected;
        Result = switch($test.Actual) {$test.Expected { "PASS" } default { "FAIL" }};
        Color = switch($test.Actual) {$test.Expected { "32" } default { "31" }}
    }
} | Format-Table -Property @(
    @{Label = "Input"; Expression = {[char]27 + "[" + $_.Color + "m" + $_.Input}},
    @{Label = "Result"; Expression = {$_.Result}},
    @{Label = "Actual"; Expression = {$_.Actual}},
    @{Label = "Expected"; Expression = {$_.Expected + [char]27 + "[0m"}}
)
