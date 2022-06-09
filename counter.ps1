Import-Module $env:MODULES_ROOT\counter.ps1 -Force

$counter = Start-Counter

$limit = 200

@(1, 5, 10) | % {
    $timeout = $limit / $_

    for ($i = 0; $i -lt $_; $i ++) {
        $counter.Set()
        Start-Sleep -Milliseconds $timeout
        $counter.Tick("[single] $_ by $timeout ms")
    }
}

@(20, 50, 100) | % {
    $timeout = $limit / $_

    $counter.Set()
    Start-Sleep -Milliseconds $limit
    $counter.Tick("[bulk] $_ by $timeout ms", $_)
}

$counter.Render()
