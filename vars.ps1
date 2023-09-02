<#
.SYNOPSIS
    Get variables from aws ssm or terraform state
.DESCRIPTION
    Populate powershell variables specified in $names by values from aws ssm (parameter store) or from terraform state (outputs)
    Powreshell variables will be visible to this script and its caller.
.PARAMETER op
    1password account to get variables
.PARAMETER aws
    AWS profile to get variables 
.PARAMETER terraform
    Terraform state to get variables. If state contains "." - consider $state.$workspace format
.PARAMETER names
    List of variable names separated by comma
.PARAMETER silent
    If specified - do not show information messages
.EXAMPLE
    vars -op $env:OP_USER -names my_token
    # gets my_token from op using account $env:OP_USER and save to variable $my_token
.EXAMPLE
    vars -aws $env:AWS_PROFILE -names db_username,db_password
    # gets db_username,db_password from ssm using aws profile $env:AWS_PROFILE and save to variables $win_username,$win_password
.EXAMPLE
    vars -terraform core -names bucket_names.backup,db_option_group
    # gets bucket_names.backup,db_option_group from terraform state "core" using default workspace
    # saves to variables $bucket_names,$db_option_group
.EXAMPLE
    vars -terraform web.live -names winrm_endpoint -silent
    # gets winrm_endpoint from terraform state "web" using workspace "live"
    # saves to variable $winrm_endpoint without any info output
#>

Param (
    [string]$op,
    [string]$aws,
    [string]$terraform,
    [string[]]$names,
    [switch]$silent
)

$op_disabled = $true

$nameString = $names -join ","

if ($op) {
    if (!$silent) {
        Write-Host "Getting $nameString from 1password"
    }

    $names | % {
        if ($op_disabled) {
            $result = @{ exitCode = 1; err = "1password disabled" }
        } else {
            $result = exec op "item get $_ --fields label=password"
        }

        if ($result.exitCode -eq 1) {
            if ($result.err.Contains("op signin") -or $result.err.Contains("sign in")) {
                iex $(Get-Content $env:OP_CODE | op signin --account $op)
                $result = exec op "item get $_ --fields label=password"
            } else {
                $result = @{ output = ask -new $_ -secure }
            }
        }

        Set-Variable -Force -Name $_ -Value $result.output -Scope 1
    }

    exit
}

if ($terraform) {
    if (!$silent) { "Getting $nameString from terraform state $terraform" }

    $state = $terraform
    $workspace = "default"

    if ($terraform -match "\.") {
        $arr = $terraform -split "\."
        $state = $arr[0]
        $workspace = $arr[1]
    }

    Join-Path $env:TERRAFORM_ROOT $state | Push-Location

    if (!(Test-Path .terraform)) {
        terraform init -force-copy
    }

    if ($(terraform workspace show) -ne $workspace) {
        terraform workspace select $workspace
    }

    $result_json = terraform output -json

    if ($LASTEXITCODE -eq 1) {
        terraform init -force-copy
        $result_json = terraform output -json
    }

    $result = $result_json | ConvertFrom-Json
    $output = @{}

    $names | % {
        $name = $_
        $result_obj = $result
        $output_obj = $output
        $keys = $name -split "\."
        $key = $keys[0]

        $keys | % {
            $result_obj = $result_obj.$_
            if ($result_obj.value) { $result_obj = $result_obj.value }

            if ($result_obj -is [PSCustomObject]) {
                if (!$output_obj.$_) { $output_obj.$_ = @{} }
                $output_obj = $output_obj.$_
            } else {
                $output_obj.$_ = $result_obj
            }
        }

        Set-Variable -Force -Name $key -Value $output.$key -Scope 1
    }

    Pop-Location

    exit
}

if ($aws -or $env:AWS_ACCESS_KEY_ID) {
    if (!$silent) {
        Write-Host "Getting $nameString from AWS SSM"
    }

    $profile = ""
    if ($aws) { $profile = "--profile $aws" }

    $result = iex "aws ssm get-parameters --with-decryption --names $names $profile --output json | ConvertFrom-Json"

    if (!$?) {
        $names | % {
            Set-Variable -Force -Name $_ -Value (ask -new $_) -Scope 1
        }
    }

    $result.Parameters | % {
        Set-Variable -Force -Name $_.Name -Value $_.Value -Scope 1
    }

    exit
}

throw "Please specify at least one of [ op | terraform | state ] arguments or have AWS_ACCESS_KEY_ID set"

