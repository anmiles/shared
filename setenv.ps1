<#
.SYNOPSIS
    Sets the environment variables for current workspace
#>

$scripts_shared = $PSScriptRoot
$scripts_root = Split-Path $scripts_shared -Parent
$root = $MyInvocation.PSScriptRoot
$terraform_root = Join-Path (Split-Path $scripts_root -Parent) "terraform"

$vars = @{}
$vars_file = Join-Path $root env.json

if (Test-Path $vars_file) {
    $json = Get-Content $vars_file | ConvertFrom-Json

    $json.PSObject.Properties | % {
        $vars[$_.Name] = $_.Value
    }
}

Function global:shpath([string]$path, [switch]$native) {
    if (!$path) { return $path }
    if ($native -and $env:WSL_ROOT) { $path = $path.Replace($env:GIT_ROOT, $env:WSL_ROOT) }
    $drive, $dir = $path -split ":"
    if (!$dir) { return $path -replace '\\', '/' -replace ' ', '\ ' }
    return $root + $drive.ToLower() + $dir -replace '\\', '/' -replace ' ', '\ '
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

    if ($vars.WSL_COMMANDS_NODE -and $vars.WSL_NODE_MODULES) {
        $vars.WSL_COMMANDS += @("node", "npm", "npx")
        $vars.WSL_COMMANDS += Get-ChildItem $vars.WSL_NODE_MODULES -Recurse -Depth 1 | ? { $_.Name -eq "package.json" } | % {
            (Get-Content $_.FullName | ConvertFrom-Json).bin.PSObject.Properties.Name
        }
    }

    if ($vars.WSL_COMMANDS.Length) {
        $vars.WSL_COMMANDS = $vars.WSL_COMMANDS | Get-Unique
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
