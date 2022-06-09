<#
.SYNOPSIS
    Check whether ip address is blocked
.DESCRIPTION
    Check whether ip address is within one of specifised subnet cidrs
.PARAMETER addresses
    List of ips or dns names or http addresses to check
.PARAMETER strict
    Whether to throw an exception when [resolved] ip address is in blocked cidr
.EXAMPLE
    blocked site.com
    # check whether site.com is blocked
.EXAMPLE
    blocked http://site2.com/qwerty?asd=wer
    # check whether site2.com is blocked
.EXAMPLE
    blocked 1.2.3.4
    # check whether 1.2.3.4 is blocked
.EXAMPLE
    blocked 5.6.7.8 -strict
    # check whether 5.6.7.8 is within one of blocked networks and throw an exception if it is 
.EXAMPLE
    blocked 11.12.13.14 15.16.17.18 google.com
    # check whether either of [11.12.13.14, 15.16.17.18, google.com] is within one of blocked networks.
#>

Param (
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$addresses,
    [switch]$strict
)

$blocks = "D:/blocks"

Function CheckAddress($address) {
    $ips = @()
    
    if ($address -match "^([\d\.]+)$") {
        $ips += $address
    } else {
        $address = $address -replace "^(\w+://)?([^/]+).*?$", '$2'
        
        [System.Net.Dns]::GetHostAddresses($address) | % {
            $ips += $_.IPAddressToString
        }
    }
    
    $ips | % {
        if ($blocked = IsIpBlocked -ip $_) {
            $message = "IP $_ is blocked ($blocked)"
            
            if ($strict) {
                throw $message
            } else {
                Write-Host $message -ForegroundColor Red
            } 
        } else {
            Write-Host "IP $_ is not blocked" -ForegroundColor Green
        }
    }
}

Function IsIpBlocked($ip) {
    if (!$ip) { return }
    $first = $ip -split '\.' | Select -First 1

    $blockfile = Join-Path $blocks "$first.txt"

    if (!(Test-Path $blockfile)) { return }

    Get-Content $blockfile | % {
        if ($_.Contains("/")) {
            if ($_.StartsWith($first_part) -and (IsIpWithinCidr -ip $ip -cidr $_)) { return $_ }
        } else {
            if ($ip -eq $_) { return "$_/32" }
        }
    }
}

Function IsIpWithinCidr($ip, $cidr) {
    if (!($ip -is [System.Net.IPAddress])) {
        $ip = [System.Net.IPAddress]::Parse($ip)
    }
    
    $parts = $cidr.Split('/');
    $subnet_ip = [System.Net.IPAddress]::Parse($parts[0])
    $subnet_bits = [int]$parts[1]
    $ip_int = [BitConverter]::ToInt32($ip.GetAddressBytes(), 0)
    $subnet_ip_int = [BitConverter]::ToInt32($subnet_ip.GetAddressBytes(), 0)
    $subnet_mask_int = [System.Net.IPAddress]::HostToNetworkOrder(-1 -shl (32 - $subnet_bits))
    return (($ip_int -band $subnet_mask_int) -eq ($subnet_ip_int -band $subnet_mask_int))
}

if ($addresses.Count -gt 0) {
    $addresses | % { CheckAddress -address $_ }
}