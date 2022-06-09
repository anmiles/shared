<#
.SYNOPSIS
    Destroy terraform state
.DESCRIPTION
    Shoftcut to "state -action destroy"
    Destroy resources in terraform state for selected environment.
    Not applicable to "core" and "web.live" because core configuration and live web server cannot be deleted
.PARAMETER state
    State name
.PARAMETER targets
    Target resources
.PARAMETER force
    Whether to force destroy without confirmation
.PARAMETER forgot
    Assume that resources to be forgot are already forgot
.EXAMPLE
    destroy web.prelive -force
    # destroy whole prelive without confirmation
.EXAMPLE
    destroy web.live aws_instance.default
    # destroy only aws_instance.default from live
#>

Param (
    [string]$state,
    [string[]]$targets,
    [switch]$force,
    [switch]$forgot
)

state -action destroy -state $state -targets $targets -force:$force -forgot:$forgot
