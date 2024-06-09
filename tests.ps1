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

$colors = @{
    $true = [char]27 + "[32m";
    $false = [char]27 + "[31m";
    "0" = [char]27 + "[0m";
}

$results = @{
    $true = "PASS"
    $false = "FAIL"
}

$data = (Import-Module $file -Force) | % {
    $test = if ($_ -is [HashTable]) {
        $_
    } else {
        $hashTable = @{}
        $_.PSObject.Properties | % { $hashTable[$_.Name] = $_.Value }
        $hashTable
    }

    if ($test.Command) { $test.Input = $test.Command }
    $test.Input = Stringify(ShowInput($test.Input))
    if (!$test.Value) { $test.Value = $test.Input }
    $test.Value = Stringify($test.Value)
    $test.Received = if ($test.Command) { iex($test.Command) } else { Test($test.Value) }
    $test.Received = Stringify(ShowReceived($test.Received))
    $test.Expected = Stringify(ShowExpected($test.Expected))

    [PsCustomObject]@{
        Color = $colors[$test.Received -eq $test.Expected];
        Result = $results[$test.Received -eq $test.Expected];
        Input = $test.Input;
        Received = $test.Received;
        Expected = $test.Expected;
        Comment = $test.Comment;
    }
}

$data | Format-Table -Property @(
    @{Label = "Result"; Expression = {$_.Color + $_.Result}},
    @{Label = "Input"; Expression = {$_.Input}},
    # @{Label = "Received"; Expression = {$_.Received}},
    @{Label = "Expected"; Expression = {$_.Expected}},
    @{Label = "Comment"; Expression = {$_.Comment}}
)

$colors["0"]

$data | ? { $_.Result -eq "FAIL" } | % {
    "--------"
    "Expected: $($colors[$true])$($_.Expected)$($colors["0"])"
    "Received: $($colors[$false])$($_.Received)$($colors["0"])"
    $colors["0"]
}
