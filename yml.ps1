<#
.SYNOPSIS
    YML parser
.DESCRIPTION
    Parses YML into object
.PARAMETER file
    Full path to yml
#>

Param (
    [Parameter(Mandatory = $true)][string]$file
)

$debug = $false
$line = 0
$spaces = $spaces_current = 0
$space_diff = 0
$object = @{}
$path = @($object)
$current = $object
$last_key = $null

Get-Content $file | % {
    $line ++
    if (!$_.Trim() -or $_.Trim()[0] -eq "#") { return }

    $spaces_current = switch ($_ -match '^(\s*)') {
        $true { $matches[1].Length }
        $false { $spaces }
    }

    if ($spaces_current -gt $spaces) {
        if ($space_diff -eq 0) {
            $space_diff = $spaces_current - $spaces
        }

        $path += $current

        if ($debug) {
            "... add 1 to path, will be"
            $path | ConvertTo-Json
        }
    }

    if ($spaces_current -lt $spaces) {
        $space_remove = ($spaces - $spaces_current) / $space_diff
        $path = $path[0..($path.Length - $space_remove - 1)]

        if ($debug) {
            "... remove $space_remove from path, will be"
            $path | ConvertTo-Json
        }
    }

    $spaces = $spaces_current

    if ($debug) { 
        ""
        "==="
        "Line $line"
    }
    
    if ($_ -match '^\s*([A-Za-z0-9-_<]+)\s*:(\s+(.+))?$') {
        $last_key = $key = $matches[1]
        $value = $matches[3]
        
        if (!$value -or ($value -match '^&(.*)$')) {
            $current = switch(!!$value){ $true { @{ ref = $matches[1]} } default { @{} } }

            if ($debug) {
                "Value = $value then add $($matches[1]) = $($current | ConvertTo-Json) to $($path[-1] | ConvertTo-Json)"
            }

            $path[-1][$matches[1]] = @{
                line = $line
                spaces = $spaces_current
                value = $current
            }

            if ($debug) {
                $path[-1]
                "----"
                $object | ConvertTo-Json
            }
        } else {
            if ($debug) { "Add key $key = $value" }

            $path[-1][$key] = @{
                line = $line
                spaces = $spaces_current
                value = $value -replace "^'?(.*?)'?$", '$1'
            }
        }
    } else {
        if ($_ -match '^\s*\-\s*(.*)$') {
            if ($path[-1] -is [Hashtable]) {
                $path[-2][$last_key] = $path[-1] = [System.Collections.Generic.List[System.Object]]::new()
            }
            $path[-1].Add(@{
                line = $line
                spaces = $spaces_current
                value = $matches[1]
            })
        } else {
            # throw "$_ doesn't match any"
        }
    }

    $spaces = $spaces_current
}

$object
