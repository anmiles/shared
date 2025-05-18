Param (
    [string]$email
)

Function Get-Telnet {
    Param (
        [Parameter(ValueFromPipeline = $true)]
        [String[]]$commands = @("helo hi"),
        [string]$remoteHost = "HostnameOrIPAddress",
        [string]$port = "25",
        [int]$waitTime = 1000
    )
    
    $socket = New-Object System.Net.Sockets.TcpClient($remoteHost, $port)
    
    if ($socket){
        $stream = $socket.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $buffer = New-Object System.Byte[] 1024 
        $encoding = New-Object System.Text.AsciiEncoding

        foreach ($command in $commands) {
            $writer.WriteLine($command)
            $writer.Flush()
            Start-Sleep -Milliseconds $waitTime
        }

        $result = ""
        
        while ($stream.DataAvailable) {
            $read = $stream.Read($buffer, 0, 1024) 
            $result += ($encoding.GetString($buffer, 0, $read))
        }
    }
    else {
        $result = "Unable to connect to host: $($RemoteHost):$Port"
    }
    
    $result
}

Function CheckEmail {
    Param (
        [string]$email
    )
    
    $emailRegex = "(?:[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*|`"(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21\x23-\x5b\x5d-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])*`")@(?:(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\[(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\x01-\x08\x0b\x0c\x0e-\x1f\x21-\x5a\x53-\x7f]|\\[\x01-\x09\x0b\x0c\x0e-\x7f])+)\])"

    if ($email -notmatch $emailRegex) {
        return "Bad email $email"
    }
    
    $server = ($email -split "@")[1]
    
    [System.Net.Dns]::GetHostAddresses($address) | % {
        if (blocked $_) {
            return "IP $_ is blocked"
        }
    }
    
    $nslookup = Resolve-DnsName $server -Server 8.8.8.8 -Type MX -ErrorAction SilentlyContinue

    if (!$nslookup) {
        return "Bad server $server"
    }

    $mx = ($nslookup | Sort -Property Preference -Descending)[0]
    $answer = Get-Telnet -RemoteHost $mx.NameExchange -Commands "helo $server","mail from: <$mail>","rcpt to: <$email>"
    return ($answer -split '\r?\n' | ? { $_.StartsWith("550") }) -join "`r`n"
}

if ($result = CheckEmail -email $email) {
    Write-Host $result -ForegroundColor Red
} else {
    Write-Host "Email exists" -ForegroundColor Green
}
