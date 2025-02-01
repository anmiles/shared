<#
.SYNOPSIS
    Sets the environment variables for current workspace
#>

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
    if (!$text) { return "" }

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
        [string]$BackgroundColor = $null,
        [switch]$parse
    )

    $ForegroundColors = @{
        Black = 30
        DarkBlue = 34
        DarkGreen = 32
        DarkCyan = 36
        DarkRed = 31
        DarkMagenta = 35
        DarkYellow = 33
        Gray = 37
        DarkGray = 90
        Blue = 94
        Green = 92
        Cyan = 96
        Red = 91
        Magenta = 95
        Yellow = 93
        White = 97
    }

    $BackgroundColors = @{
        Black = 40
        DarkBlue = 44
        DarkGreen = 42
        DarkCyan = 46
        DarkRed = 41
        DarkMagenta = 45
        DarkYellow = 43
        Gray = 47
        DarkGray = 100
        Blue = 104
        Green = 102
        Cyan = 106
        Red = 101
        Magenta = 105
        Yellow = 103
        White = 107
    }

    $result = @{ length = 0 }

    Function Colorize($str, $ForegroundColor, $BackgroundColor) {
        if ($str.Length -eq 0) { return "" }

        $result.length += $str.Length

        $f1 = $b1 = $c0 = ""

        $eseq = "$([char]27)"

        if ($ForegroundColor) {
            $code = $ForegroundColors[$ForegroundColor]
            $f1 = "$eseq[$($code)m"
            $c0 = "$eseq[m"
        }

        if ($BackgroundColor) {
            $code = $BackgroundColors[$BackgroundColor]
            $b1 = "$eseq[$($code)m"
            $c0 = "$eseq[m"
        }

        return "$b1$f1$str$c0"
    }

    $output = @()

    if ($text) {
        if ($parse) {
            $parts = $text -split "\{([A-Za-z]+):(.*?(?![^``]\}))\}"

            for ($i = 0; $i -lt $parts.Length - 1; $i += 3) {
                $output += Colorize $parts[$i] $ForegroundColor $BackgroundColor
                $output += Colorize $parts[$i + 2] $parts[$i + 1] $BackgroundColor
            }

            $output += Colorize $parts[$parts.Length - 1] $ForegroundColor $BackgroundColor
        } else {
            $output += Colorize $text $ForegroundColor $BackgroundColor
        }
    }

    return ($output -join "")
}

function global:whereami($text = (Get-PSCallStack)[0].Command) {
    Write-Host (fmt "$(Get-Location) * $text" "DarkGray")
}

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

$paths = [System.Collections.ArrayList]($env:PATH -split ";")
$sourcePaths = @()

    if (!$vars.WSL_COMMANDS) {
        $vars.WSL_COMMANDS = @()
    }

    $commands = @{}
    Get-Command | % { $commands[$_.Name] = $_.Source }

    $vars.WSL_COMMANDS | % {
        if ($commands[$_]) {
            $sourcePath = Split-Path $commands[$_].Source -Parent
                $sourcePaths += $sourcePath
                $sourcePaths += "$sourcePath\"
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
if (!$vars.GITLAB_HOST) { $vars.GITLAB_HOST = "gitlab.com" }

$vars.Keys | % {
    $value = $vars[$_]

    if (!($value -is [string])) {
        if ($value -is [System.Object[]] -and $value.Length -eq 0) {
            $value = "[]"
        } else {
            $value = $value | ConvertTo-Json
        }
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
