<#
.SYNOPSIS
    Ping with removing protocol and url parts
.EXAMPLE
    p https://www.example.com/qwerty.html
    # pings www.example.com
#>

$args = $args | % {
    $_ -replace "^(\w+://)?([^/:]+).*?$", '$2'
}

ping $args