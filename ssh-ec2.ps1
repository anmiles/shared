<#
.SYNOPSIS
    SSH for linux EC2 from Windows
.DESCRIPTION
    Connect to remote linux instance using Putty
.PARAMETER state
    State and environment name separated by dot. If environment name not specified - consider connecting to hostname specified
.PARAMETER hostname
    Considered if state not specified
.EXAMPLE
    ssh-ec2 linux.live
    # connects to ec2 instance in state linux, environment name live, using linux.pem key
.EXAMPLE
    ssh-ec2 empty -hostname 1.2.3.4
    # connects to ec2 instance 1.2.3.4 using empty.pem key
#>

Param (
    [Parameter(Mandatory = $true)][string]$state,
    [string]$hostname
)

if (!$hostname) {
    Write-Host "Getting hostname for $state ..." -ForegroundColor Green
    vars -terraform $state -names public_ip -silent
    $hostname = $public_ip
}

if ($state -match "\.") {
    $arr = $state -split "\."
    $state = $arr[0]
    $environment_name = $arr[1]
}

$pem = Join-Path $env:TEMP "$state.pem"
$ppk = Join-Path $env:TEMP "$state.ppk"

Write-Host "Downloading key file..." -ForegroundColor Green
download-key -file $pem -silent

Write-Host "Converting key file to putty format..." -ForegroundColor Green
winscp /keygen $pem /output=$ppk

Write-Host "Starting putty..." -ForegroundColor Green
vars -aws $env:AWS_PROFILE -names linux_username -silent
putty -ssh $hostname -i $ppk -l $linux_username

Write-Host "Key files will be deleted in 5 seconds..." -ForegroundColor Green
Start-Sleep 5
Remove-Item $pem -Force
Remove-Item $ppk -Force

Write-Host "Done" -ForegroundColor Green
