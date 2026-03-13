Import-Module $env:MODULES_ROOT\npm.ps1 -Force

Function Test {
    Param (
        [string]$range
    )

    $usages = FindDependencyUsages -root /root-location -name test-package -range $range -mockFile (Join-Path $PSScriptRoot "npm.mock.json")

    return ($usages | % { "$($_.name): $($_.version)"})
}

@(
    @{
        Input = "";
        Expected = @(
            "dep-2: 1.2.1",
            "dep-3: 1.2.1",
            "dep-5: 1.2.1",
            "dep-6: 1.2.2",
            "dep-7: 1.2.3",
            "dep-8: 2.4.0"
            "dep-9: 2.5.1"
        )
    },
    @{
        Input = "<=1.2.2 || 2.4.0";
        Expected = @(
            "dep-2: 1.2.1",
            "dep-3: 1.2.1",
            "dep-5: 1.2.1",
            "dep-6: 1.2.2",
            "dep-8: 2.4.0"
        )
    }
)
