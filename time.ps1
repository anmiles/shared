Import-Module $env:MODULES_ROOT\timer.ps1 -Force

$timer = Start-Timer -accurate

$timer.StartTask($args)

& $args[0] $args[1..($args.Length - 1)]

$timer.Finish()
