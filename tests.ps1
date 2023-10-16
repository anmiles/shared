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

$files = @("tests/$filename.ps1", "../tests/$filename.ps1" ) | % { Join-Path $PSScriptRoot $_}

if (!($files | ? { Test-Path $_ })) {
    throw "Files $($files -Join ", ") don't exist"
}

$file = $files | ? { Test-Path $_ } | Select -First 1

Function Stringify($obj) {
    $str = switch ($obj.GetType().IsArray) { $true { $obj -join $separator } $false { $obj.ToString() } }
    return $str
}

Function Test {
    Param (
        [Parameter(Mandatory = $true)]$value
    )
    return $value
}

Function ShowInput {
    Param (
        [Parameter(Mandatory = $true)]$value
    )
    return $value
}

Function ShowReceived {
    Param (
        [Parameter(Mandatory = $true)]$value
    )
    return $value
}

Function ShowExpected {
    Param (
        [Parameter(Mandatory = $true)]$value
    )
    return $value
}

$data = Import-Module $file -Force | % {
    $test = $_
    $test.Input = Stringify(ShowInput($test.Input))
    if (!$test.Value) { $test.Value = $test.Input }
    $test.Value = Stringify($test.Value)
    $test.Received = Stringify(ShowReceived(Test($test.Value)))
    $test.Expected = Stringify(ShowExpected($test.Expected))

    [PsCustomObject]@{
        Color = switch($test.Received) {$test.Expected { "32" } default { "31" }};
        Result = switch($test.Received) {$test.Expected { "PASS" } default { "FAIL" }};
        Input = $test.Input;
        Received = $test.Received;
        Expected = $test.Expected;
        Comment = $test.Comment;
    }
}

$data | Format-Table -Property @(
    @{Label = "Result"; Expression = {[char]27 + "[" + $_.Color + "m" + $_.Result}},
    @{Label = "Input"; Expression = {$_.Input}},
    @{Label = "Received"; Expression = {$_.Received}},
    @{Label = "Expected"; Expression = {$_.Expected}},
    @{Label = "Comment"; Expression = {$_.Comment + [char]27 + "[0m"}}
)

$data | ? { $_.Result -eq "FAIL" }
