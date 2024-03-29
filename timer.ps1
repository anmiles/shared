Import-Module $env:MODULES_ROOT\timer.ps1 -Force

$timer = Start-Timer -accurate

$timer.StartTask("Starting")
Start-Sleep -Milliseconds 100
$timer.FinishTask()

$timer.StartTask("Processing")
Start-Sleep -Milliseconds 300
$timer.FinishTask()

$timer.StartTask("Ending")
Start-Sleep -Milliseconds 100
$timer.FinishTask()

$timer.Finish()
