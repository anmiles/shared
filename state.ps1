<#
.SYNOPSIS
    Shortcut to terraform action
.DESCRIPTION
    Can apply or destroy states
    Switch workspace automatically
    Init if needed
    Pass tfvars files automatically
.PARAMETER action
    One of { apply | destroy }
.PARAMETER state
    State name
.PARAMETER targets
    Target resources
.PARAMETER force
    Whether to force action without confirmation
.PARAMETER new
    Remove resources from terraform state for selected environment to create new environment in parallel
    If targets specified - remove its resource from terraform state for selected environment to create new resource in the same environment
    Applicable only for action = apply
.PARAMETER renew
    Destroy resource and apply it again. Applicable only for action = apply and targets specified
.PARAMETER current
    Explicitly set "new" to $false and suppress confirmations
.PARAMETER forgot
    When destroy, assume that resources to be forgot are already forgot
.EXAMPLE
    state -action apply -state core
    # apply core state with confirmation
.EXAMPLE
    state -action apply -state web.live -targets null_resource.deploy
    # apply web state, live environment (workspace) null_resource.deploy resource
.EXAMPLE
    state -action apply -state web.live -new
    # apply web state, live environment (workspace) with removing resources from terraform state to create new environment in parallel
.EXAMPLE
    state -action apply -state web.live -targets null_resource.deploy -new
    # apply web state, live environment (workspace) with removing this resource first
.EXAMPLE
    state -action apply -state web.prelive -targets null_resource.source -renew
    # apply web state, prelive environment (workspace) with destroying this resource first
.EXAMPLE
    state -action destroy -state web.prelive -force
    # destroy web state, prelive environment (workspace) without confirmation
#>

Param (
    [Parameter(Mandatory = $true)][ValidateSet('apply', 'destroy')][string]$action,
    [Parameter(Mandatory = $true)][string]$state,
    [string[]]$targets,
    [switch]$force,
    [switch]$new,
    [switch]$renew,
    [switch]$current,
    [switch]$forgot
)

Import-Module $env:MODULES_ROOT\timer.ps1 -Force
$timer = Start-Timer

$environment_name = "default"

if ($state -match "\.") {
    $arr = $state -split "\."
    $state = $arr[0]
    $environment_name = $arr[1]
}

$state_location = Join-Path $env:TERRAFORM_ROOT $state

$tfvars_default = "../shared/default.tfvars"
$tfvars_state = "vars/$state.tfvars"
$tfvars_environment = "vars/environments/$environment_name.tfvars"

if ($state -eq "web" -and $environment_name -eq "live" -and !$new -and !$current -and $action -eq "apply") {
    $current = confirm "Do you really want to re-apply current web.live environment"
    $new = !$current
}

if ($new -and $state -eq "core") {
    throw "-new switch is not applicable to the core state"
}

if ($new -and $action -ne "apply") {
    throw "-new switch is applicable to apply action only"
}

if ($renew -and $action -ne "apply") {
    throw "-renew switch is applicable to apply action only"
}

if ($new -and $current) {
    throw "`$new and `$current cannot be set to `$true at the same time"
}

if ($renew -and ($new -or $current)) {
    throw "-renew switch cannot be set together with -new or -current"
}

if ($renew -and !$targets) {
    throw "-renew switch required targets to be set"
}

Push-Location $state_location

if ($state -eq "web") {
    $timer.StartTask("Getting versions")

    $version_keys = @("ami_version", "web_version")
    $version_keys_tags = @("AmiVersion", "WebVersion")
    $tagValues = ec2-tags $version_keys_tags -type $state -environment $environment_name
    $version_keys_found = @()

    @($tfvars_default, $tfvars_state, $tfvars_environment) | % {
        $file = $_
        $filename = Split-Path $_ -Leaf

        Join-Path $state_location $file | Resolve-Path | Get-Content | % {
            $line = $_
            $version_keys | ? { $line -match "$_ = (\d+)" } | % {
                $version_keys_found += @(@{Key = $_; Value = $matches[1]; Filename = $filename})
            }
        }
    }

    if ($new -and !$targets -and $version_keys_found.Length) {
        $version_keys_found | % {
            $found = $_.Value
            $existing = $tagValues[$version_keys.IndexOf($_.Key)]
            
            if ($found -eq $existing) {
                if (!(confirm "Allow new {{$state.$environment_name}} environment to re-use the same {{$($_.Key)}} = {{$found}} as existing one")) {
                    out "Please update {Green:$($_.Key)} in {Green:$($_.Filename)} and try again"
                    exit
                }
            }
        }
    }

    $timer.FinishTask()
}

$timer.StartTask("Getting workspace")

$current_workspace = $(terraform workspace show)

if ($LASTEXITCODE -eq 1) {
    terraform init -force-copy
    $current_workspace = $(terraform workspace show)
}

if ($current_workspace -ne $environment_name) {
    terraform workspace select $environment_name
}

$timer.FinishTask()

if ($renew) {
    state -action destroy -state "$state.$environment_name" -targets $targets -force:$force
}

$forgets = @()
$tf = Join-Path $env:SCRIPTS_ROOT "tf.json"

if (Test-Path $tf) {
    $tf_json = (file $tf) | ConvertFrom-Json
    $tf_forgets = $tf_json | ? { $_.state -eq $state }
    if (!$tf_forgets) { $tf_forgets = $tf_json | ? { $_.state -eq "default" } }

    if ($new) {
        if ($targets) {
            $forgets += $targets
        } else {
            ($tf_forgets.forgets | ? { $_.when -eq "new" }).resources | % {
                $forgets += $_
            }
        }
    }

    if ($action -eq "destroy" -and !$targets -and !$forgot) {
        ($tf_forgets.forgets | ? { $_.when -eq "destroy" }).resources | % {
            $forgets += $_
        }
    }
}

if ($forgets.Length -gt 0) {
    $timer.StartTask("Removing old resources")

    $forgets | % {
        Write-Host "Removing $_..." -ForegroundColor Green
        terraform state rm $_
    }

    $timer.FinishTask()
}

if ($targets) { $targets = ($targets | % { "-target=`"$_`"" }) -join " " }

$approve = ""

if ($force) { $approve = "--auto-approve" }

if ($action -eq "destroy") { [Environment]::SetEnvironmentVariable("TF_WARN_OUTPUT_ERRORS", 1, "Process") }

$timer.StartTask($action)

terraform $action $approve `
-var-file="$tfvars_default" `
-var-file="$tfvars_state" `
-var-file="$tfvars_environment" `
-var "name=$state" `
-var "environment_name=$environment_name" `
$targets

$timer.FinishTask()

if ($action -eq "destroy") { [Environment]::SetEnvironmentVariable("TF_WARN_OUTPUT_ERRORS", $null, "Process") }

Pop-Location
$timer.Finish()
