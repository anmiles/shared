<#
.SYNOPSIS
    WinRM like SSH
.DESCRIPTION
    Use winrm to connect to remote host and provide remote console (like ssh).
    Asks password.
    If connection is not specified - asks both hostname and username
    If connection is specified only as hostname - asks username
.PARAMETER connection
    Can be one of:
    - nothing
    - hostname
    - username@hostname
.PARAMETER command
    Can be provided only if $connection provided
.EXAMPLE
    remote
    # ask hostname, username, password and provide remote interactive session on hostname with username and password
.EXAMPLE
    remote  192.168.0.1
    # ask username and password and provide remote interactive session on hostname 192.168.0.1 with username and password
.EXAMPLE
    remote 192.168.0.1
    # ask username and password and provide remote interactive session on hostname 192.168.0.1 with username and password
.EXAMPLE
    remote Administrator@example.com
    # ask password and provide remote interactive session on hostname example.com with username Administrator and password
.EXAMPLE
    remote c3sql "shutdown -r -f -t 00"
    # ask username, password and remotely reboot c3sql using username and password
#>

Param (
    [string]$connection,
    [string]$command
)

$hostname = ""
$username = ""
$password = ""
$commandPassed = !!$command

if ($connection) {
    if ($connection -match "@") {
        $hostname = $connection -split "@" | select -last 1
        $username = $connection -split "@" | select -first 1
    } else {
        $hostname = $connection
    }
}

if (!$hostname) { $hostname = Read-Host -Prompt 'Hostname' }
if (!$username) { $username = Read-Host -Prompt 'Username' }
if (!$password) { $password = Read-Host -Prompt 'Password' -AsSecureString }

#Get-PSSession -ComputerName $hostname | Remove-PSSession

$credential = $(New-Object System.Management.Automation.PSCredential $username, $password)
$session = New-PSSession -ConnectionUri "http://${hostname}:5985" -Credential $credential
$dir = Invoke-Command -Session $session -ScriptBlock { (Get-Location).Path }

do {
    if (!$commandPassed) {
        Write-Host -NoNewline "$username@${hostname}: PS $dir> "; $command = Read-Host
    }

    if ($command) {
        $result = Invoke-Command -Session $session -ScriptBlock {
            param($command)
            Invoke-Expression $command
            (Get-Location).Path
        } -ArgumentList $command

        if ($result) {
            if ($result -is [string]) {
                $dir = $result
            } else {
                $dir = $result[$result.Count - 1]
                Write-Output $result[0..($result.Count - 2)]
            }
        }
    }
}
while (!$commandPassed -and $command -ne "exit")

Remove-PSSession -Session $session
