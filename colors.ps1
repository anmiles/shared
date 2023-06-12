<#
.SYNOPSIS
    Output all console colors
#>
$colors = [Enum]::GetValues([ConsoleColor])
$maxLength = ($colors | % { $_.ToString().Length } | Measure -Maximum).Maximum

$colors | ? { $_ } | % {
    $front = switch ($_ -lt 10){$true{"White"} $false{"Black"}}
    Write-Host (([int]$_).ToString().PadLeft(2, " ")) -ForegroundColor $_ -NoNewline;
    Write-Host " " -NoNewline;
    Write-Host $_ -ForegroundColor $_ -NoNewline;
    Write-Host (" " * (1 + $maxLength - $_.ToString().Length)) -NoNewline;
    Write-Host $_ -ForegroundColor $front -BackgroundColor $_;
}
