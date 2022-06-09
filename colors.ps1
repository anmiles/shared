<#
.SYNOPSIS
    Output all console colors
#>

[Enum]::GetValues([ConsoleColor]) | % { Write-Host $_ -ForegroundColor $_ }
[Enum]::GetValues([ConsoleColor]) | ? { $_ -lt 10 } | % { Write-Host $_ -ForegroundColor White -BackgroundColor $_ }
[Enum]::GetValues([ConsoleColor]) | ? { $_ -ge 10 } | % { Write-Host $_ -ForegroundColor Black -BackgroundColor $_ }