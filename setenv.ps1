<#
.SYNOPSIS
    Sets the environment variables for current workspace
#>

$scripts_shared = $PSScriptRoot
$scripts_root = Split-Path $scripts_shared -Parent
$root = $MyInvocation.PSScriptRoot
$terraform_root = Join-Path (Split-Path $scripts_root -Parent) "terraform"

$vars = @{}
$vars.ENV_FILE = Join-Path $root "env.json"
$vars.ENV_REPOSITORIES_FILE = Join-Path $root "env.repositories.json"

if (Test-Path $vars.ENV_FILE) {
    $json = Get-Content $vars.ENV_FILE | ConvertFrom-Json

    $json.PSObject.Properties | % {
        $vars[$_.Name] = $_.Value
    }
}

Function global:ex([switch]$confirm, [switch]$return) {
    if ($exitCode = $lastExitCode) {
        if ($confirm) {
            if (!(confirm "Do you want to continue")) {
                if ($return) { return $false } else { exit 1 }
            }
        } else {
            out "{Red:Command failed with exit code $exitCode}"
            if ($return) { return $false } else { exit 1 }
        }
    }

    return $true
}

Function global:getenc($num) {
    switch ($num) {
        866 { return [System.Text.Encoding]::GetEncoding("cp866") }
        1251 { return [System.Text.Encoding]::GetEncoding("Windows-1251") }
        1252 { return [System.Text.Encoding]::GetEncoding("Windows-1252") }
        default { return [System.Text.Encoding]::UTF8 }
    }
}

Function global:enc($text, $from, $to) {
    $from = getenc $from
    $to = getenc $to

    $bytes = $to.GetBytes($text)
    $text = $from.GetString($bytes)
    return $text
}

Function global:shpath([string]$path, [switch]$native, [switch]$resolve) {
    if (!$path) { return $path }
    $path = $path -replace '/', '\'
    if ($native -and $env:WSL_ROOT) { $path = $path.Replace($env:GIT_ROOT, $env:WSL_ROOT) }
    $drive, $dir = $path -split ":"
    if ($drive.Length -gt 1) { $dir = $null }
    $root = switch($native) { $true { "/mnt/" } $false { "/" } }
    # commented because couldn't find path with an escaped space
    if (!$dir) { $path = $path -replace '\\', '/' <# -replace ' ', '\ ' #> }
    else { $path = $root + $drive.ToLower() + $dir -replace '\\', '/' <# -replace ' ', '\ ' #> }
    if ($resolve) { $path = $path -replace '~', "`$HOME"}
    return $path
}

function global:wsh($command, $arguments){
    $arguments = $arguments | % {
        if ($_ -is [string] -and ($_[0] -eq "%" -or $_.Contains(" ") -or $_.Contains("'"))) {
            return "'$($_ -replace "'", "'\''")'"
        }

        return $_
    }

    sh "$command $arguments"
}

$paths = [System.Collections.ArrayList]($env:PATH -split ";")
$sourcePaths = @()

if ($env:WSL_COMMANDS) {
    $vars.WSL_COMMANDS = $env:WSL_COMMANDS | ConvertFrom-Json
} else {
    if (!$vars.WSL_COMMANDS) {
        $vars.WSL_COMMANDS = @()
    }

    $vars.WSL_COMMANDS | % {
        $commands = Get-Command $_ -All -ErrorAction SilentlyContinue

        if ($commands) {
            $commands.Source | ? { $_ } | % {
                $sourcePath = Split-Path $_ -Parent
                $sourcePaths += $sourcePath
                $sourcePaths += "$sourcePath\"
            }
        }
    }
}

$vars.WSL_COMMANDS | % {
    iex "function global:$_(){wsh $_ `$args}"
}

$paths = $paths | ? { $_ -notin $sourcePaths }
$vars.PATH = ($paths + @($scripts_root, $scripts_shared) + $vars.PATH) -Join ";"
$vars.GIT_ROOT = $root
$vars.SCRIPTS_ROOT = $scripts_root
$vars.MODULES_ROOT = Join-Path $scripts_root "modules"
$vars.TERRAFORM_ROOT = $terraform_root
if (!$vars.PROMPT_COLOR) { $vars.PROMPT_COLOR = "White" }

$vars.Keys | % {
    $value = $vars[$_]

    if (!($value -is [string])) {
        $value = $value | ConvertTo-Json
    }

    [Environment]::SetEnvironmentVariable($_, $value, "Process")
}

[Environment]::SetEnvironmentVariable("ENVARS", $vars.Keys -join ",", "Process")

function global:prompt {
    Write-Host " `b" -ForegroundColor Gray -NoNewLine:(!$env:PROMPTED)
    [Environment]::SetEnvironmentVariable("PROMPTED", $true, "Process")
    Write-Host "PS $(Get-Location)>" -NoNewLine -ForegroundColor $env:PROMPT_COLOR
    Write-Host " `b" -NoNewLine -ForegroundColor Gray
    return " "
}
