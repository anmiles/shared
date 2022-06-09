<#
.SYNOPSIS
    Sets the environment variables for current workspace
#>

$scripts_shared = $PSScriptRoot
$scripts_root = Split-Path $scripts_shared -Parent
$root = $MyInvocation.PSScriptRoot
$terraform_root = Join-Path (Split-Path $scripts_root -Parent) "terraform"
$vars_file = Join-Path $root env.json
$json = Get-Content $vars_file | ConvertFrom-Json
$vars = @{}

$json.PSObject.Properties | % {
    $var = $_
    $vars[$var.Name] = switch($var.Value) {
        $null { "" }
        default {
            switch ($var.TypeNameOfValue) {
                "System.String" { $var.Value }
                "" { $var.Value }
                default { $var.Value | ConvertTo-Json }
            }
        }
    }
}

$vars.PATH = (($env:PATH -split ";") + @($scripts_root, $scripts_shared) + $vars.PATH) -Join ";"
$vars.WORKSPACE_NAME = Split-Path $root -Leaf
$vars.GIT_ROOT = $root
$vars.SCRIPTS_ROOT = $scripts_root
$vars.MODULES_ROOT = Join-Path $scripts_root "modules"
$vars.TERRAFORM_ROOT = $terraform_root
if (!$vars.PROMPT_COLOR) { $vars.PROMPT_COLOR = "White" }

$vars.Keys | % { [Environment]::SetEnvironmentVariable($_, $vars[$_], "Process") }

function global:prompt {
    Write-Host " `b" -ForegroundColor Gray -NoNewLine:(!$env:PROMPTED)
    [Environment]::SetEnvironmentVariable("PROMPTED", $true, "Process")
    Write-Host "PS $(Get-Location)>" -NoNewLine -ForegroundColor $env:PROMPT_COLOR
    Write-Host " `b" -NoNewLine -ForegroundColor Gray
    return " "
}
