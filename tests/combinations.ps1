Import-Module $env:MODULES_ROOT\combinations.ps1 -Force

Function Test {
    Param (
        [Parameter(Mandatory = $true)][string]$query
    )

    return Get-Combinations $query
}

@(
    @{Input = "cat"; Expect = @("cat")},
    @{Input = "?cat"; Expect = @("cat")},
    @{Input = "ca()t"; Expect = @("cat")},
    @{Input = "cas?t"; Expect = @("cat", "cast")},
    @{Input = "ca(s)?t"; Expect = @("cat", "cast")},
    @{Input = "ca(r|s)t"; Expect = @("cart", "cast")},
    @{Input = "ca(r|s)?t"; Expect = @("cat", "cart", "cast")}
    @{Input = "car??(pe)?t"; Expect = @("cat", "cart", "capet", "carpet")}
)
