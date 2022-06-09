Function Test {
    Param (
        [Parameter(Mandatory = $true)][TimeSpan]$timeSpan
    )

    return $timeSpan.ToString("G") -replace '^[0\D]+(.*)(\d\.\d+)$', '$1$2' -replace '(\.\d{3})\d*$', '$1'
}

@(
    @{Input = [TimeSpan]::new(0, 0, 0, 0, 0); Expected = "0.000"},
    @{Input = [TimeSpan]::new(0, 0, 0, 0, 2); Expected = "0.002"},
    @{Input = [TimeSpan]::new(0, 0, 0, 0, 20); Expected = "0.020"},
    @{Input = [TimeSpan]::new(0, 0, 0, 0, 200); Expected = "0.200"},
    @{Input = [TimeSpan]::new(0, 0, 0, 2, 0); Expected = "2.000"},
    @{Input = [TimeSpan]::new(0, 0, 0, 2, 200); Expected = "2.200"},
    @{Input = [TimeSpan]::new(0, 0, 0, 20, 20); Expected = "20.020"},
    @{Input = [TimeSpan]::new(0, 0, 2, 0, 0); Expected = "2:00.000"},
    @{Input = [TimeSpan]::new(0, 0, 2, 2, 0); Expected = "2:02.000"},
    @{Input = [TimeSpan]::new(0, 0, 2, 20, 0); Expected = "2:20.000"},
    @{Input = [TimeSpan]::new(0, 0, 2, 2, 2); Expected = "2:02.002"},
    @{Input = [TimeSpan]::new(0, 0, 20, 0, 0); Expected = "20:00.000"},
    @{Input = [TimeSpan]::new(0, 0, 20, 2, 0); Expected = "20:02.000"},
    @{Input = [TimeSpan]::new(0, 0, 20, 0, 20); Expected = "20:00.020"},
    @{Input = [TimeSpan]::new(0, 0, 20, 20, 20); Expected = "20:20.020"},
    @{Input = [TimeSpan]::new(0, 2, 0, 0, 0); Expected = "2:00:00.000"},
    @{Input = [TimeSpan]::new(0, 2, 2, 0, 0); Expected = "2:02:00.000"},
    @{Input = [TimeSpan]::new(0, 2, 0, 2, 0); Expected = "2:00:02.000"},
    @{Input = [TimeSpan]::new(0, 2, 0, 0, 200); Expected = "2:00:00.200"},
    @{Input = [TimeSpan]::new(0, 20, 0, 0, 0); Expected = "20:00:00.000"},
    @{Input = [TimeSpan]::new(0, 20, 0, 0, 2); Expected = "20:00:00.002"},
    @{Input = [TimeSpan]::new(2, 0, 0, 0, 0); Expected = "2:00:00:00.000"},
    @{Input = [TimeSpan]::new(2, 2, 0, 0, 0); Expected = "2:02:00:00.000"},
    @{Input = [TimeSpan]::new(2, 0, 0, 0, 2); Expected = "2:00:00:00.002"},
    @{Input = [TimeSpan]::new(20, 0, 0, 0, 0); Expected = "20:00:00:00.000"},
    @{Input = [TimeSpan]::new(20, 0, 0, 0, 200); Expected = "20:00:00:00.200"}
)
