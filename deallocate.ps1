<#
.SYNOPSIS
    Release elastip ip
.PARAMETER ip
    Elastic IP address to release
#>

Param (
    [Parameter(Mandatory = $true)][string]$ip
)

$eips = $(aws ec2 describe-addresses --filters --output json) | ConvertFrom-Json
$eip = $eips.Addresses | ? { $_.PublicIp -eq $ip }

if (!$eip) {
    throw "EIP $ip not found"
}

aws ec2 release-address --allocation-id $eip.AllocationId
