<#
.SYNOPSIS
    Apply terraform state
.DESCRIPTION
    Shoftcut to "state -action apply"
    Apply changes in terraform state for selected environment.
    Live environment needs to be forgotten (forget.cmd) before publishing new code
    "ami_version" can be incremented for state "fs" and "web"
    "web_version" should be incremented for state "web" to prevent caching in CDN
.PARAMETER state
    State name
.PARAMETER targets
    Target resources
.PARAMETER force
    Whether to force apply without confirmation
.PARAMETER new
    Remove resources from terraform state for selected environment to create new environment in parallel
.PARAMETER current
    Explicitly set "new" to $false and suppress confirmations
.EXAMPLE
    apply core -force
    # apply core state without confirmation
.EXAMPLE
    apply web.live
    # apply web state, live environment (workspace) with confirmation
.EXAMPLE
    apply web.live -new
    # apply web state, live environment (workspace) with confirmation, with removing resources from terraform state to create new environment in parallel
.EXAMPLE
    apply web.live -current
    # apply web state, live environment (workspace) without confirmation
.EXAMPLE
    apply web.prelive null_resource.source
    # apply web state, prelive environment (workspace), null_resource.source without confirmation
.EXAMPLE
    apply web.live null_resource.deploy -new
    # apply web state, live environment (workspace) with removing this resource first
.EXAMPLE
    apply web.prelive null_resource.source -renew
    # apply web state, prelive environment (workspace) with destroying this resource first
#>

Param (
    [string]$state,
    [string[]]$targets,
    [switch]$force,
    [switch]$new,
    [switch]$again,
    [switch]$renew,
    [switch]$current
)

state -action apply -state $state -targets $targets -force:$force -new:$new -renew:$renew -current:$current
