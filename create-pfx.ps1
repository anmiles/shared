<#
.SYNOPSIS
    Create PFX certificate
.DESCRIPTION
    Generate PFX file from CSR certificates and private key
.PARAMETER pfx
    PFX that is need to be renewed
.PARAMETER crt
    CRT file
.PARAMETER crts
    Directory containing intermediate crt files
.PARAMETER key
    Private key
#>

Param (
    [string]$pfx,
    [string]$crt,
    [string]$crts,
    [string]$key
)

$openssl = "openssl"

Function OpenSSL-Exists {
    return Get-Command $openssl -errorAction SilentlyContinue
}

Function Refresh-Path {
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") +
                ";" + 
                [System.Environment]::GetEnvironmentVariable("Path","User")
}

Function Ask-File ([string]$path, [string]$extension, [string]$prompt, [switch]$multiple){
    do {
        $thisPath = $path
        if (!$thisPath) { $thisPath = Read-Host $prompt }
        
        if (Test-Path -PathType Leaf $thisPath) {
            if ($thisPath.EndsWith($extension)) {
                if ($multiple) {
                    return @($thisPath)
                } else {
                    return (Resolve-Path $thisPath)
                }
            }
        }
        
        if ($multiple -and (Test-Path -PathType Container $thisPath)) {
            $thisPath = Get-ChildItem -Path $thisPath -Filter "*$extension"
            
            if ($thisPath) {
                return $thisPath.FullName
            }
        }
    } while ($true)
}

if (!(OpenSSL-Exists)) {
    Refresh-Path
    
    if (!(OpenSSL-Exists)) {
        choco install -y openssl.light
        Refresh-Path
    }
}

$pfx = Ask-File -path $pfx -extension ".pfx" -prompt "PFX that is need to be renewed"
$crt = Ask-File -path $crt -extension ".crt" -prompt "CRT file"
$crts = Ask-File -path $crts -extension ".crt" -prompt "CRT files (directory containing intermediate CRT files, if any)" -multiple
$key = Ask-File -path $key -extension ".key" -prompt "KEY file"

$arguments = @("pkcs12")
$arguments += @("-export")
$arguments += @("-out", $pfx)
$arguments += @("-inkey", $key)
$arguments += @("-certfile ", $crt)
$crts | ? {$_ -ne $crt} | % { $arguments += @("-in", $_) }
$arguments -Join " "
Start-Process -NoNewWindow -Wait $openssl $arguments

Write-Host "Done!" -ForegroundColor Green
