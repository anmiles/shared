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

$status = @{ value = "run script" }

Function ShowError($message){
    Get-Command push 2>&1 | Out-Null
    $message += " when $($status.Value)"

    if ($?) {
        push -title mybackup -message $message -status error
    } else {
        Write-Host $message -ForegroundColor Red
    }
}

try {
    Write-Host "Starting..." -ForegroundColor Green
    $status.Value = "start"
    $extension = ".zip"

    Write-Host "Getting config..." -ForegroundColor Green
    $status.Value = "get config"
    if (!$configFile) { $configFile = Join-Path $env:UserProfile "mybackup.config" }
    if (!(Test-Path $configFile)) { throw "Config file $configFile doesn't exist" }
    $content = Get-Content $configFile
    $xml = [xml]$content
    $config = $xml.mybackup

    if ($config.source) {
        Write-Host "Copying config from $($config.source) to $configFile..." -ForegroundColor Green
        $status.Value = "copy config from $($config.source) to $configFile"
        try {
            Copy-Item $config.source $configFile
        }
        catch {
            ShowError "Unable to copy config" -ForegroundColor Green
        }

        $config = ([xml](Get-Content $configFile)).mybackup
    }

    if ($verify) {
        $status.Value = "verify paths"

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
        $status.Value = "execute before task $name..."
        Push-Location $_.path
        iex $_.command
        Pop-Location
    }

    Write-Host "Copying items..." -ForegroundColor Green
    $status.Value = "start copy"
    $tmpRoot = Join-Path $env:TEMP "mybackup"
    New-Item $tmpRoot -Type Directory -Force | Out-Null

    $tmpZip = $tmpRoot + $extension

    Get-ChildItem $tmpRoot | Remove-Item -Recurse -Force

    $config.items.ChildNodes | ? { $_.LocalName -ne "#comment" } | % {
        $name = $_.name
        Write-Host "    > $name"
        $status.Value = "backup $name"

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
            $status.Value = "copy $src to $dst"
            New-Item $dstParent -Type Directory -Force | Out-Null
            Copy-Item -LiteralPath $src $dst -Force | Out-Null
        }
    }

    Write-Host "Compressing..." -ForegroundColor Green
    $status.Value = "compress"
    Get-ChildItem $tmpRoot | Compress-Archive -Destination $tmpZip -CompressionLevel Fastest -Force

    Write-Host "Saving backup..." -ForegroundColor Green
    $status.Value = "save backup"
    $config.destinations.ChildNodes | ? { $_.LocalName -ne "#comment" } | % {
        $dstName = ([regex]"\{(.*)\}").Replace($_.format, {(Get-Date).ToString($args[0].Groups[1])})
        $dstPath = Join-Path $_.path $dstName

        try {
            if ($_.expiredays) {
                $expireDate = (Get-Date).AddDays(-[int]$_.expiredays)

                $status.Value = "remove expired backup $($_.path)"
                Get-ChildItem $_.path | ? { $_.Name.EndsWith($extension) -and $_.LastWriteTime -lt $expireDate } | % {
                    Remove-Item $_.FullName -Force
                }
            }

            $status.Value = "copy backup $tmpZip to $dstPath"
            Copy-Item $tmpZip $dstPath
        } catch {
            if (!$_.remote) {
                throw "Cannot copy to $($_.path)"
            }
        }
    }

    Write-Host "Cleaning up..." -ForegroundColor Green
    $status.Value = "cleanup"
    Remove-Item $tmpZip -Force -Recurse
    Remove-Item $tmpRoot -Force -Recurse

    Write-Host "Executing tasks [after]..." -ForegroundColor Green
    $config.Tasks.ChildNodes | ? { $_.LocalName -ne "#comment" -and $_.when -eq "after" } | % {
        $name = $_.name
        Write-Host "    > $name"
        $status.Value = "execute after task $name..."
        Push-Location $_.path
        iex $_.command
        Pop-Location
    }

    Write-Host "Done!" -ForegroundColor Green
} catch {
    ShowError $_.Exception.Message
    exit
}

