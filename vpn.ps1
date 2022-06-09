<#
.SYNOPSIS
    Connect or disconnect VPN using rasdial
.PARAMETER name
    The name of connection. If empty - disconnects
.PARAMETER force
    Answer 'y' to any questions
.PARAMETER y
    Answer 'y' to any questions
.EXAMPLE
    vpn live 
    # Tries to connect live. If live connected - asks for disconnect. If other VPNs connected - asks for connect on top.
.EXAMPLE
    vpn
    # If any VPNs connected - shows them and asks for disconnect.
#>

Param (
    [Parameter(ValueFromRemainingArguments = $true)][string]$name,
    [switch]$force,
    [switch]$y
)

$name = ($name + "").ToUpper()
$force = $force -or $y

$rasdial = $(rasdial)

if ($rasdial -Contains "No connections") {
    if ($name) {
        rasdial $name
    } else {
        Write-Host "No VPN connections"
    }
} else {
    $connections = $rasdial | ? {$_ -ne "Connected to" -and $_ -ne "Command completed successfully."} | % {$_.ToUpper()}
    
    if ($name) {
        if ($connections -Contains $name) {
            Write-Host "VPN [$name] is already connected" -ForegroundColor Green
            
            if ($force -or (confirm "Do you want to disconnect")) {
                rasdial $name /disconnect
            }
            
        } else {
            Write-Host "VPN connected: [$($connections -join ", ")]" -ForegroundColor Green

            if ($force -or (confirm "Do you want to connect VPN {{$name}} on top")) {
                rasdial $name
            }
        }
    } else {
        Write-Host "VPN connected: [$($connections -join ", ")]"

        if ($force -or (confirm "Do you want to disconnect")) {
            $connections | % {
                rasdial $_ /disconnect
            }
        }
    }
}