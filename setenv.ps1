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

function global:fmt {
    Param (
        [string]$text,
        [string]$ForegroundColor = $null,
        [string]$BackgroundColor = $null
    )

    $ForegroundColors = @{
        0 = 30
        1 = 34
        2 = 32
        3 = 36
        4 = 31
        5 = 35
        6 = 33
        7 = 37
        8 = 90
        9 = 94
        10 = 92
        11 = 96
        12 = 91
        13 = 95
        14 = 93
        15 = 97
    }

    $BackgroundColors = @{
        0 = 40
        1 = 44
        2 = 42
        3 = 46
        4 = 41
        5 = 45
        6 = 43
        7 = 47
        8 = 100
        9 = 104
        10 = 102
        11 = 106
        12 = 101
        13 = 105
        14 = 103
        15 = 107
    }

    $result = @{ length = 0 }

    Function Colorize($str, $ForegroundColor, $BackgroundColor) {
        if ($str.Length -eq 0) { return "" }

        $result.length += $str.Length

        $f1 = $b1 = $c0 = ""

        if ($ForegroundColor) {
            $code = $ForegroundColors[[int][ConsoleColor]$ForegroundColor]
            $f1 = "$([char]27)[$($code)m"
            $c0 = "$([char]27)[m"
        }

        if ($BackgroundColor) {
            $code = $BackgroundColors[[int][ConsoleColor]$BackgroundColor]
            $b1 = "$([char]27)[$($code)m"
            $c0 = "$([char]27)[m"
        }

        return "$b1$f1$str$c0"
    }

    $output = @()

    if ($text) {
        $parts = $text -split "\{([A-Za-z]+):(.*?(?![^``]\}))\}"

        for ($i = 0; $i -lt $parts.Length - 1; $i += 3) {
            $output += Colorize $parts[$i] $ForegroundColor $BackgroundColor
            $output += Colorize $parts[$i + 2] $parts[$i + 1] $BackgroundColor
        }

        $output += Colorize $parts[$parts.Length - 1] $ForegroundColor $BackgroundColor
    }

    return ($output -join "")
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
