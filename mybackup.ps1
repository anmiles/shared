<#
.SYNOPSIS
    Backup directories
.DESCRIPTION
    Make backup of specified directories, copy backup to several places and execute tasks before and after backup
.PARAMETER configFile
    Config file. Default is %USERPROFILE%\mybackup.config
.PARAMETER verify
    Check whether all directories exist
.EXAMPLE
    mybackup -configFile C:\Temp\mybackup.config
    # Perform backup using config from file C:\Temp\mybackup.config
#>

Param (
    [string]$configFile,
    [switch]$verify
)

Function ShowError($message){
    Get-Command push 2>&1 | Out-Null
    if ($?) {
        push -title mybackup -message $message -color Red
    } else {
        Write-Host $message -ForegroundColor Red
    }
}

try {
    Write-Host "Starting..." -ForegroundColor Green
    $extension = ".zip"

    Write-Host "Getting config..." -ForegroundColor Green
    if (!$configFile) { $configFile = Join-Path $env:UserProfile "mybackup.config" }
    if (!(Test-Path $configFile)) { throw "Config file $configFile doesn't exist" }
    $content = Get-Content $configFile
    $xml = [xml]$content
    $config = $xml.mybackup

    if ($config.source) {
        Write-Host "Copying config from $($config.source) to $configFile..." -ForegroundColor Green
        try { Copy-Item $config.source $configFile }
        catch { Write-Host "Unable to copy config" -ForegroundColor Green }
        $config = ([xml](Get-Content $configFile)).mybackup
    }

    if ($verify) {
        Function Verify([array]$items) {
            $items.ChildNodes | ? { $_.LocalName -ne "#comment" } | % {
                if (!(Test-Path $_.path)) {
                    out "{Red:Path} {Yellow:$($_.path)} {Red:does not exist}"
                }
            }
        }

        Verify $config.tasks
        Verify $config.destinations
        Verify $config.items
        exit
    }

    Write-Host "Executing tasks [before]..." -ForegroundColor Green
    $config.tasks.ChildNodes | ? { $_.LocalName -ne "#comment" -and $_.when -eq "before" } | % {
        $name = $_.name
        Write-Host "    > $name"
        Push-Location $_.path
        iex $_.command
        Pop-Location
    }

    Write-Host "Copying items..." -ForegroundColor Green
    $tmpRoot = Join-Path $env:TEMP "mybackup"
    New-Item $tmpRoot -Type Directory -Force | Out-Null

    $tmpZip = $tmpRoot + $extension

    Get-ChildItem $tmpRoot | Remove-Item -Recurse -Force

    $config.items.ChildNodes | ? { $_.LocalName -ne "#comment" } | % {
        $name = $_.name
        Write-Host "    > $name"
        
        $path = $_.path.TrimEnd("\")
        $include = $_.include -split "\s*;\s*"
        $exclude = $_.exclude -split "\s*;\s*"
        $recurse = $_.recurse -and ($_.recurse.ToLower() -ne "false")
        
        if (!(Test-Path $path)) {
            ShowError "Path does not exist for backup item '$name': $path"
            return
        }
        
        $tmpDir = Join-Path $tmpRoot $name
        New-Item $tmpDir -Type Directory -Force | Out-Null
        
        $pathRegex = [regex]::Escape($path)
        $pathFind = $path
        if (!$recurse) { $pathFind = $pathFind + "\*" }

        Get-ChildItem $pathFind -Include $include -Exclude $exclude -Recurse:$recurse -File:(!$recurse) -ErrorAction SilentlyContinue | ? { !$exclude -or !$_.FullName.Contains($exclude ) } | % {
            $src = $_.FullName
            $dst = $_.FullName -replace $pathRegex, $tmpDir
            $dstParent = Split-Path $dst
            New-Item $dstParent -Type Directory -Force | Out-Null
            Copy-Item $src $dst -Force | Out-Null
        }
    }

    Write-Host "Compressing..." -ForegroundColor Green
    Get-ChildItem $tmpRoot | Compress-Archive -Destination $tmpZip -CompressionLevel Fastest -Force

    Write-Host "Saving backup..." -ForegroundColor Green
    $config.destinations.ChildNodes | ? { $_.LocalName -ne "#comment" } | % {
        $dstName = ([regex]"\{(.*)\}").Replace($_.format, {(Get-Date).ToString($args[0].Groups[1])})
        $dstPath = Join-Path $_.path $dstName
        
        try {
            if ($_.expiredays) {
                $expireDate = (Get-Date).AddDays(-[int]$_.expiredays)

                Get-ChildItem $_.path | ? { $_.Name.EndsWith($extension) -and $_.LastWriteTime -lt $expireDate } | % {
                    Remove-Item $_.FullName -Force
                }
            }
            
            Copy-Item $tmpZip $dstPath
        } catch {
            if (!$_.remote) {
                throw "Cannot copy to $($_.path)"
            }
        }
    }

    Write-Host "Cleaning up..." -ForegroundColor Green
    Remove-Item $tmpZip -Force -Recurse
    Remove-Item $tmpRoot -Force -Recurse

    Write-Host "Executing tasks [after]..." -ForegroundColor Green
    $config.Tasks.ChildNodes | ? { $_.LocalName -ne "#comment" -and $_.when -eq "after" } | % {
        $name = $_.name
        Write-Host "    > $name"
        Push-Location $_.path
        iex $_.command
        Pop-Location
    }

    Write-Host "Done!" -ForegroundColor Green
} catch {
    ShowError $_.Exception.Message
    exit
}

