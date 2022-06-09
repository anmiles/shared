<#
.SYNOPSIS
    Try to allocate non-blocked elastic ip
.DESCRIPTION
    Allocate new ip until it's not within blocked networks
    If failed - release ip and allocate again
.PARAMETER name
    Optional name of the new EIP
#>

Param (
    [string]$name
)

$tags = ""
if ($name) {
    $tags = "ResourceType=elastic-ip,Tags=[{Key=Name,Value=$name}]"
}

Function AllocateNew {
    $eip = $(aws ec2 allocate-address --tag-specifications $tags --output json) | ConvertFrom-Json

    if ($eip.PublicIp) {
        if (blocked $eip.PublicIp) {
            aws ec2 release-address --allocation-id $eip.AllocationId
            return AllocateNew
        } else {
            return $eip
        }
    }
}

AllocateNew
