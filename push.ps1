<#
.SYNOPSIS
    Send message to Pushover
.PARAMETER message
    Message to send
.PARAMETER title
    Optional title
.PARAMETER token
    Token name
.PARAMETER sound
    Sound from the list
.PARAMETER priority
    Push notification priority (set "1" to alarm)
.PARAMETER status
    Status that defined whether to show message in console and in which color
.PARAMETER local
    Whether to show message locally and don't use pushover
#>

Param (
    [Parameter(Mandatory = $true)][string]$message,
    [string]$title,
    [string]$user = $env:PUSH_USER,
    [string]$app = "notification",
    [string]$sound = "magic",
    [int]$priority = 0,
    [ValidateSet('info', 'warning', 'error')][string]$status = "info",
    [switch]$local
)

if (!$local -and !!$user) {
    $user_key = "pushover_user_$user"
    $app_key = "pushover_app_$($user)_$app"

    vars -op $env:OP_USER -aws $env:AWS_PROFILE -names $user_key,$app_key -silent

    $token = Get-Variable | ? { $_.Name -eq $app_key }
    $user = Get-Variable | ? { $_.Name -eq $user_key }
}

if (!$token -or !$user) {
    $icon = $status
    if (!$icon) { $icon = "Info" }
    msgbox $message $title "OK" $icon
} else {
    $data = @{
        token = $token
        user = $user
        message = $message
        title = $title
        sound = $sound
        priority = $priority
    }

    try {
        Invoke-RestMethod -Method POST -Uri "https://api.pushover.net/1/messages.json" -Body $data | Out-Null
    } catch {
        Write-Host "Error: $_" -ForegroundColor Red
        if (!$status) { $status = "info" }
    }
}

if ($status) {
    $color = switch($status) {
        "error" { "Red" }
        "warn" { "Yellow" }
        "info" { "Green" }
    }

    out $message -ForegroundColor $color
}
