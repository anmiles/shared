<#
.SYNOPSIS
    Inivaludate cloudfront distribution
.DESCRIPTION
    Inivaludate cloudfront distribution given its ID and one or more invalidation roots
.PARAMETER distribution_id
    Distribution id
.PARAMETER invalidation_roots
    Array of paths to invalidate all objects within them
.PARAMETER web_version
    Versioning suffix if versioning enabled
.PARAMETER async
    If switch specified - do not wait until invalidation finished
.EXAMPLE
    invalidate -distribution_id ABCDE123
    # invalidate all objects inside distribution ABCDE123
.EXAMPLE
    invalidate -distribution_id ABCDE123 -invalidation_roots Scripts,Images
    # invalidate all inside paths @(Scripts,Images) inside distribution ABCDE123
.EXAMPLE
    invalidate -distribution_id ABCDE123 -invalidation_roots images -web_version 40.1
    # invalidate all objects by path "/images/v40.1/*" inside distribution ABCDE123
#>

Param (
    [Parameter(Mandatory = $true)][string]$distribution_id,
    [string[]]$invalidation_roots,
    [string]$web_version,
    [switch]$async
)

& $env:MODULES_ROOT\invalidate.ps1 `
-distribution_id $distribution_id `
-invalidation_roots $invalidation_roots `
-web_version $web_version `
-async:$async
