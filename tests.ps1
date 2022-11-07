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
    if (!$function:Test) {
        Function Test {
            Param (
                [Parameter(Mandatory = $true)]$value
            )
            return $value
        }
    }

    $test = $_
    $test.Input = Stringify($test.Input)
    if (!$test.Value) { $test.Value = $test.Input }
    $test.Value = Stringify($test.Value)
    $test.Actual = Stringify(Test($test.Value))
    $test.Expect = Stringify($test.Expect)

    [PsCustomObject]@{
        Color = switch($test.Actual) {$test.Expect { "32" } default { "31" }};
        Result = switch($test.Actual) {$test.Expect { "PASS" } default { "FAIL" }};
        Input = $test.Input;
        Actual = $test.Actual;
        Expect = $test.Expect;
        Comment = $test.Comment;
    }
} | Format-Table -Property @(
    @{Label = "Result"; Expression = {[char]27 + "[" + $_.Color + "m" + $_.Result}},
    @{Label = "Input"; Expression = {$_.Input}},
    @{Label = "Actual"; Expression = {$_.Actual}},
    @{Label = "Expect"; Expression = {$_.Expect}},
    @{Label = "Comment"; Expression = {$_.Comment + [char]27 + "[0m"}}
)
