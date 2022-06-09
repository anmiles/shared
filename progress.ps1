Import-Module $env:MODULES_ROOT\progress.ps1 -Force

$progress = Start-Progress -title "Backup database" -count 50

$progress.Tick(10)
Start-Sleep -Milliseconds 300
$progress.Tick(10, "Starting")
Start-Sleep -Milliseconds 300
$progress.Tick(10, "Processing")
Start-Sleep -Milliseconds 300
$progress.Tick(10)
Start-Sleep -Milliseconds 300
$progress.Tick(10, "Finished")
