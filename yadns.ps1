<#
.DESCRIPTION
    Check domain resolving by yandex.net DNS
.PARAMETER domain
    Domain to check
.PARAMETER times
	How much times ask each DNS server
.EXAMPLE
    yadns mysite.ru
    # checks how each yandex.net DNS server resolve mysite.ru 4 times
.EXAMPLE
    yadns mysite.ru 1
    # checks how yandex.net DNS servers resolve mysite.ru only once
#>

Param (
    [Parameter(Mandatory = $true)][string]$domain,
	[int]$times = 4
)

(1..$times) | % {
	$time = $_

	(1..2) | % {
		$index = $_
		if (!($index -eq 1 -and $time -eq 1)) { Start-Sleep -Milliseconds 500 }
		$dns = "dns$index.yandex.net"
		$answer = nslookup $domain $dns
		$line = @($answer | grep "Address:" | Select -Skip 1)[0]
		$address = $line.Replace("Address:", "").Trim()
		"$dns : $address"
	}
}
