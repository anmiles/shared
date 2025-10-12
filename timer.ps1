Import-Module $env:MODULES_ROOT\timer.ps1 -Force

$timer = Start-Timer -accurate

$timer.StartTask("First")
Start-Sleep -Milliseconds 1000
$timer.FinishTask()

$timer.StartTask("Second")
Start-Sleep -Milliseconds 2000
$timer.FinishTask()

Start-Sleep -Milliseconds 2000

$timer.StartTask("Third")
Start-Sleep -Milliseconds 1000
$timer.FinishTask()

$timer.Finish()
