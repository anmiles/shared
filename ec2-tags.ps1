<#
.SYNOPSIS
    Get tag from the current live EC2 instance
.PARAMETER tagName
    Tag name
.PARAMETER type
    State name
.PARAMETER environment
    Environment name
.PARAMETER silent
    If specified - do not show information messages
.EXAMPLE
    ec2-tags WebVersion
    # get value of the tag WebVersion for live web instance
.EXAMPLE
    ec2-tags WebVersion,AmiVersion -environment prelive
    # get values of tags WebVersion, AmiVersion for prelive web instance
#>

Param (
    [Parameter(Mandatory = $true)][string[]]$tagNames,
    [string]$type = "web",
    [string]$environment = "live",
    [switch]$silent
)

$filters = @{
    Type = $type
    Environment = $environment
}

if (!$silent) {
    out "{Green:Getting $($tagNames -Join ", ") for $type.$environment...} " -NoNewline
}

$filters = $filters.Keys | % { "Name=tag:$_,Values=$($filters[$_])" }
$query = "Addresses[*].InstanceId"
$instanceId = aws ec2 describe-addresses --filters $filters --query $query --output text

$tagQuery = $tagNames | % { "$($_):Tags[?Key==``$_``].Value|[0]" }

$query = "Reservations[0].Instances[0].{$($tagQuery -Join ",")}"
$tagValues = $(aws ec2 describe-instances --instance-id $instanceId --query $query --output json) | ConvertFrom-Json

$result = @()

if (!$silent) {
    out (($tagNames | % { $tagValues.$_ }) -Join ", ") -ForegroundColor Yellow -NoNewline
    out " "
}

return $tagNames | % { $tagValues.$_ }
