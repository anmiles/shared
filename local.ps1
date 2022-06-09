<#
.SYNOPSIS
    Access to resource bypassing current default gateway
.DESCRIPTION
    Create persistent route to access specified resources through office gateway
.PARAMETER addresses
    List of ips or dns names or http addresses to route
.EXAMPLE
    local site.com
    # creates persistent route to access site.com through office gateway
.EXAMPLE
    local http://site2.com/qwerty?asd=wer
    # creates persistent route to access site.com through office gateway
.EXAMPLE
    local 1.2.3.4
    # creates persistent route to access 1.2.3.4 through office gateway
.EXAMPLE
    blocked 11.12.13.14 15.16.17.18 example.com
    # creates persistent route to access each of [11.12.13.14, 15.16.17.18, example.com] through office gateway
#>

Param (
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$addresses
)

$original_default_gateway = "192.168.0.3"

Function AddRoutes($address) {
    $cidrs = @()
    
    if ($address -match "^([\d\.]+)\/\d+$") {
        $cidrs += "$address"
    } else {    
        if ($address -match "^([\d\.]+)$") {
            $cidrs += "$address/32"
        } else {
            $address = $address -replace "^(\w+://)?([^/]+).*?$", '$2'
            
            [System.Net.Dns]::GetHostAddresses($address) | % {
                $cidrs += "$($_.IPAddressToString)/32"
            }
        }
    }
    
    $cidrs | % {
        $parts = $_.Split('/');
        $subnet_ip = [System.Net.IPAddress]::Parse($parts[0])
        $subnet_bits = [int]$parts[1]
        $int64 = [convert]::ToInt64(('1' * $subnet_bits + '0' * (32 - $subnet_bits)), 2)
        $subnet_mask = '{0}.{1}.{2}.{3}' -f
            ([math]::Truncate($Int64 / [Math]::Pow(2, 24))).ToString(), 
            ([math]::Truncate(($Int64 % [Math]::Pow(2, 24)) / [Math]::Pow(2, 16))).ToString(), 
            ([math]::Truncate(($Int64 % [Math]::Pow(2, 16))/[Math]::Pow(2, 8))).ToString(), 
            ([math]::Truncate($Int64 % [Math]::Pow(2, 8))).ToString()
        $subnet_ip.IPAddressToString
        $subnet_mask
        route delete $subnet_ip.IPAddressToString
        route add $subnet_ip.IPAddressToString mask $subnet_mask $original_default_gateway -p
    }
}

if ($addresses.Count -gt 0) {
    $addresses | % { AddRoutes -address $_ }
}
