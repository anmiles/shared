Import-Module $env:MODULES_ROOT\combinations.ps1 -Force

Function Test {
    Param (
        [Parameter(Mandatory = $true)][string]$query
    )

    return Get-Combinations $query
}

@(
    @{Input = "cat"; Expected = @("cat")},
    @{Input = "?cat"; Expected = @("cat")},
    @{Input = "ca()t"; Expected = @("cat")},
    @{Input = "cas?t"; Expected = @("cat", "cast")},
    @{Input = "ca(s)?t"; Expected = @("cat", "cast")},
    @{Input = "ca(r|s)t"; Expected = @("cart", "cast")},
    @{Input = "ca(r/s)?t"; Expected = @("cat", "cart", "cast")}
    @{Input = "car??(pe)?t"; Expected = @("cat", "cart", "capet", "carpet")}
)
