<#
.SYNOPSIS
    Open MR from the recent push
#>

$push = [Environment]::GetEnvironmentVariable("RECENT_PUSH", "Process")
if (!$push) { err "RECENT_PUSH was not set" }

$match = $push -match "(https:\/\/gitlab.com(\/[\w-]+)+\/merge_requests/\d+)"
if (!$match) { error "RECENT_PUSH doesn't contain MR link:`n`n$push"}

Start-Process $matches[1]
