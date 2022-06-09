<#
.SYNOPSIS
    Backup all sql structures
.DESCRIPTION
    Generate scripts for all scriptable MSSQL server objects
.PARAMETER destination
    Where to create sql scripts
.PARAMETER sqlInstance
    MSSQL instance
.EXAMPLE
    sqlbackup -destination D:\db\MSSQL\Structure -sqlInstance localhost
    # Scripts all scriptable objects of instance localhost in D:\db\MSSQL\Structure
#>

Param (
    [Parameter(Mandatory = $true)][string] $destination,
    [Parameter(Mandatory = $true)][string] $sqlInstance,
    [switch] $append = $false
)

Import-Module dbatools

New-Item -Force -Type Directory $destination | Out-Null
Push-Location $destination

if (!$append) {
    Get-ChildItem $destination | Remove-Item -Force -Recurse
}

$option = New-DbaScriptingOption
$option.IncludeIfNotExists = $true
$option.IncludeHeaders = $true
$option.SchemaQualify = $false
$option.ScriptDataCompression = $false
$option.ExtendedProperties = $true
$option.DriAllConstraints = $true
$option.DriAllKeys = $true
$option.DriDefaults = $true
$option.DriForeignKeys = $true
$option.DriIndexes = $true
$option.DriPrimaryKey = $true
$option.DriUniqueKeys = $true

New-Item -Force -Type Directory "Databases" | Out-Null

Get-DbaDatabase -SqlInstance $sqlInstance -ExcludeSystem | % {
    $db = $_.Name
    New-Item -Force -Type Directory "Databases/$db" | Out-Null
    Export-DbaScript $_ -Path "Databases/$db/Database.sql" -ScriptingOptionsObject $option

    New-Item -Force -Type Directory "Databases/$db/Tables" | Out-Null

    Get-DbaDbTable -SqlInstance $sqlInstance -Database $db | % {
        $table = $_.Name
        Export-DbaScript $_ -Path "Databases/$db/Tables/$table.sql" -ScriptingOptionsObject $option
    }

    New-Item -Force -Type Directory "Databases/$db/StoredProcedures" | Out-Null

    Get-DbaDbStoredProcedure -SqlInstance $sqlInstance -Database $db -ExcludeSystemSp | % {
        $sp = $_.Name
        Export-DbaScript $_ -Path "Databases/$db/StoredProcedures/$sp.sql" -ScriptingOptionsObject $option
    }

    New-Item -Force -Type Directory "Databases/$db/Views" | Out-Null

    Get-DbaDbView -SqlInstance $sqlInstance -Database $db -ExcludeSystemView | % {
        $view = $_.Name
        Export-DbaScript $_ -Path "Databases/$db/Views/$view.sql" -ScriptingOptionsObject $option
    }

    New-Item -Force -Type Directory "Databases/$db/Users" | Out-Null
    
    Get-DbaDbUser -SqlInstance $sqlInstance -Database $db -ExcludeSystemUser | % {
        $user = $_.Name
        Export-DbaScript $_ -Path "Databases/$db/Users/$user.sql" -ScriptingOptionsObject $option
    }

    New-Item -Force -Type Directory "Databases/$db/Functions" | Out-Null

    Get-DbaDbUdf -SqlInstance $sqlInstance -Database $db -ExcludeSystemUdf | % {
        $function = $_.Name
        Export-DbaScript $_ -Path "Databases/$db/Modules/$function.sql" -ScriptingOptionsObject $option
    }
}

New-Item -Force -Type Directory "Jobs" | Out-Null

Get-DbaAgentJob -SqlInstance $sqlInstance | % {
    $job = $_.Name
    Export-DbaScript $_ -Path "Jobs/$job.sql" -ScriptingOptionsObject $option
}

Pop-Location

Write-Host "Done!" -ForegroundColor Green