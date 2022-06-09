<#
.SYNOPSIS
    Approve plan files
.DESCRIPTION
    Wait for .tfplan files in $plan_root directory.
    When file appears - show this plan and ask to approve.
    Then add ".approved" or ".rejected" suffix to plan filename
#>

Param (
    [string]$plan_file
)

$plan_root = "D:\.terraform\plan"

if ($plan_file) {
    Write-Host "Getting terraform plan..." -ForegroundColor Green
    terraform show $plan_file

    if (confirm "Do you want to apply plan file {{$plan_file}}") { 
        Write-Host "Plan approved!" -ForegroundColor Green
        Move-Item $plan_file "${plan_file}.approved"
    } else {
        Write-Host "Plan rejected!" -ForegroundColor Red
        Move-Item $plan_file "${plan_file}.rejected"
    }
    
    exit
}

while ($true) {
    Write-Host "Waiting .tfplan files..." -ForegroundColor Green

    while (!(Test-Path "$plan_root\*.tfplan")) {
        Start-Sleep 1
    }

    Get-Childitem -Path $plan_root -Include *.tfplan -Recurse -ErrorAction SilentlyContinue | foreach {
        Write-Host "Found $($_.Name)..." -ForegroundColor Green
        $process = Start-Process -FilePath powershell -ArgumentList $MyInvocation.MyCommand.Definition, $_.FullName -WindowStyle Maximized -Wait
    }

    while (Test-Path "$plan_root\*.tfplan") {
        Start-Sleep 1
    }
}
