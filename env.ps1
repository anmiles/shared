<#
.SYNOPSIS
    Start or stop non-live environments
.DESCRIPTION
    Start EC2 and RDS instances that are not belong to live environment
.PARAMETER action
    One of { start | stop | list }
    Start or EC2 and RDS instances that are not belong to live environment
        or list all existing EC2 and RDS instances
.PARAMETER filters
    Array of tag values that instances are filtered by
.PARAMETER simulate
    "WhatIf" mode: just show what could be happen if run this command
.PARAMETER rds
    if action = stop: to stop only RDS instances that aren't used with any running EC2 instances
    if action = stop: to start only RDS instance that are used with any running EC2 instances
.PARAMETER apply
    Whether to apply instances after starting
.PARAMETER new
    Whether to attach new public IP to instance
.EXAMPLE
    env list
    # list all instances
.EXAMPLE
    env stop
    # stop EC2 and RDS instances that have at least one tag that equals "live"
.EXAMPLE
    env start
    # start all instances that marked to restart and remove this mark
.EXAMPLE
    env stop -rds
    # stop all rds instances that appropriate EC2 instances are not running
#>

Param (
    [ValidateSet('start', 'stop', 'list')][string]$action,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$filters,
    [switch]$simulate,
    [switch]$rds,
    [switch]$apply,
    [switch]$new
)

Import-Module $env:MODULES_ROOT\iis.ps1 -Force

if ($action -eq "start" -and $filters.Length -eq 0) {
    throw "Should specify filters"
}

if ($simulate) {
    Write-Host "SIMULATE MODE" -ForegroundColor Yellow
}

if ($rds) {
    Write-Host "RDS ONLY" -ForegroundColor Yellow
}

$applies = @()

Function ExpandTags($obj, $tags){
    $matched_filters = @{}

    foreach ($tag in $tags) {
        Add-Member -InputObject $obj -NotePropertyName $tag.Key -NotePropertyValue $tag.Value -Force

        $filters | % {
            if ($tag.Key -ne "Name" -and $_ -eq $tag.Value) { $matched_filters[$_] = $_ }
        }
    }

    $obj.PSObject.Properties.Remove("Tags")
    
    if ($action -ne "list" -and ($tags | ? { $_.Key -eq "Environment" }).Value -eq "live") {
        return;
    }

    if ($matched_filters.Keys.Count -eq $filters.Length) { return $obj }
}

Function GetEC2Instances() {
    $query = "Reservations[*].Instances[*].{Id:InstanceId,State:State.Name,Tags:Tags}"
    $instances = @()

    $result = $(aws ec2 describe-instances --query $query --output json) -join "" | ConvertFrom-Json
    $result | % {
        $instance = ExpandTags -obj $_[0] -tags $_[0].Tags
        if ($instance) { $instances += $instance }
    }

    return $instances
}

Function GetRDSInstances() {
    $query = "DBInstances[*].{Id:DBInstanceIdentifier,State:DBInstanceStatus,ARN:DBInstanceArn}"
    $instances = @()

    $result = $(aws rds describe-db-instances --query $query --output json) -join "" | ConvertFrom-Json
    $result | % {
        $tags = $(aws rds list-tags-for-resource --resource-name $_.ARN --output json) -join "" | ConvertFrom-Json
        $instance = ExpandTags -obj $_[0] -tags $tags.TagList
        if ($instance) { $instances += $instance }
    }
    return $instances
}

Function GetEIPAddresses() {
    $addresses = @()

    $result = $(aws ec2 describe-addresses --output json) -join "" | ConvertFrom-Json
    $result.Addresses | % {
        $address = ExpandTags -obj $_[0] -tags $_[0].Tags
        if ($address) { $addresses += $address }
    }

    return $addresses
}

Function GetColor($colors) {
    return ($colors | % { [char]27 + "[" + $_ + "m" }) -join ""
}

if ($action -eq "list") {
    Function OutputInstances($instances, $type) {
        if (!$instances) { return }

        $instances | % {
            $instance = $_

            [PsCustomObject]@{
                Id = $instance.Id;
                Name = $instance.Name;
                State = $instance.State.ToUpper();
                Color = switch($instance.State) {
                    "running" { GetColor 32 }
                    "available" { GetColor 32 }
                    "stopped" { GetColor 31 }
                    "terminated" { GetColor 1,30 }
                    default { GetColor 1,33 }
                }
            }
        } | Format-Table -Property @(
            @{Label = "$type ID"; Expression = {$_.Color + $_.Id}},
            @{Label = "Name"; Expression = {$_.Name}},
            @{Label = "State"; Expression = {$_.State + (GetColor 0)}}
        )
    }

    Function OutputAddresses($addresses, $ec2_instances) {
        if (!$addresses) { return }

        $addresses | % {
            $address = $_

            [PsCustomObject]@{
                PublicIp = $address.PublicIp;
                Name = $address.Name;
                Instance = switch($address.InstanceId) {
                    $null { "" }
                    default { ($ec2_instances | ? { $_.Id -eq $address.InstanceId}).Name }
                }
                Color = switch($address.AssociationId) {
                    $null { GetColor 31 }
                    default { GetColor 32 }
                }
            }
        } | Format-Table -Property @(
            @{Label = "Public IP"; Expression = {$_.Color + $_.PublicIp}},
            @{Label = "Name"; Expression = {$_.Name}}
            @{Label = "Instance"; Expression = {$_.Instance + (GetColor 0)}}
        )
    }

    $ec2_instances = GetEC2Instances
    $rds_instances = GetRDSInstances
    $eip_addresses = GetEIPAddresses
    
    Write-Host "EC2 instances..." -ForegroundColor DarkYellow
    OutputInstances $ec2_instances "EC2"

    Write-Host "RDS instances..." -ForegroundColor DarkYellow
    OutputInstances $rds_instances "RDS"

    Write-Host "EIP addresses..." -ForegroundColor DarkYellow
    OutputAddresses $eip_addresses $ec2_instances

} else {
    Write-Host "Getting EC2 instances..."
    $ec2_instances = GetEC2Instances

    Write-Host "Getting RDS instances..."
    $rds_instances = GetRDSInstances

    $ec2_running_instances = $ec2_instances | ? {$_.State -eq "running"}

    switch ($action) {
        "start" {
            # # Try to start instance even if it's started. Useful for changing IP ($new flag)
            # $ec2_instances = $ec2_instances | ? {$_.State -eq "stopped"}

            if ($ec2_instances -and !$rds) {
                Write-Host "Starting EC2 instances [$($ec2_instances.Name)] ..."
                if (!$simulate) { $result = aws ec2 start-instances --instance-ids $ec2_instances.Id }

                $applies += $ec2_instances | % { "$($_.Type).$($_.Environment)" }
            }
            
            $rds_instances = $rds_instances | ? {$_.State -eq "stopped" -and (!$rds -or $ec2_running_instances.Environment.Contains($_.Environment))}
            
            $rds_instances | % {
                Write-Host "Starting RDS instances [$($_.Name)] ..."
                if (!$simulate) { $result = aws rds start-db-instance --db-instance-identifier $_.Id }
            }
        }
        
        "stop" {
            $ec2_instances = $ec2_instances | ? {$_.State -eq "running"}

            if ($ec2_instances -and !$rds) {
                Write-Host "Stopping EC2 instances [$($ec2_instances.Name)] ..."
                if (!$simulate) { $result = aws ec2 stop-instances --instance-ids $ec2_instances.Id }
            }

            $rds_instances = $rds_instances | ? {$_.State -eq "available" -and (!$rds -or !$ec2_running_instances -or !$ec2_running_instances.Environment.Contains($_.Environment))}

            $rds_instances | % {
                Write-Host "Stopping RDS instances [$($_.Name)] ..."
                if (!$simulate) { $result = aws rds stop-db-instance --db-instance-identifier $_.Id }
            }
        }
    }

    $waiting_states = @{
        "EC2" = switch($action){"start" { "running" } "stop" { "stopped" }}
        "RDS" = switch($action){"start" { "available" } "stop" { "stopped" }}
    }

    if (!$rds) {
        foreach ($ec2_instance in $ec2_instances) {
            Write-Host "Waiting until EC2 instance [$($ec2_instance.Name)] state is '$($waiting_states.EC2)'..."
            $query = "Reservations[*].Instances[*].{Id:InstanceId,State:State.Name,NetworkInterfaces:NetworkInterfaces[*].{Association:Association.{PublicIp:PublicIp,IpOwnerId:IpOwnerId},NetworkInterfaceId:NetworkInterfaceId}}"
            $filters = "Name=instance-id,Values=$($ec2_instance.Id)"

            do {
                $result = $(aws ec2 describe-instances --query $query --filters $filters --output json) | ConvertFrom-Json
            } while ($result[0][0].State -ne $waiting_states.EC2 -and !$simulate)

            if ($action -eq "start") {
                $ip = $result[0][0].NetworkInterfaces.Association.PublicIp

                if ($new) {
                    $eip = allocate -name $ec2_instance.Name
                    $association = aws ec2 associate-address --network-interface-id $result[0][0].NetworkInterfaces[0].NetworkInterfaceId --allocation-id $eip.AllocationId
                    $ip = $eip.PublicIp
                    
                    $result[0][0].NetworkInterfaces | % {
                        if ($_.Association.IpOwnerId -ne "amazon") {
                            deallocate $_.Association.PublicIp
                        }
                    }
                }
                
                Write-Host $ip -ForegroundColor DarkYellow

                $hosts = [HostsFile]::new()
                $hosts.Load()
                $hosts.AddRecord($ip, "$($ec2_instance.Type)-$($ec2_instance.Environment).$($env:WORKSPACE_NAME).local", $env:WORKSPACE_NAME.ToUpper())
                $hosts.Save()
            }
        }
    }

    foreach ($rds_instance in $rds_instances) {
        Write-Host "Waiting until RDS instance [$($rds_instance.Name)] state is '$($waiting_states.RDS)'..."
        $query = "DBInstances[*].{State:DBInstanceStatus}"
        $filters = "Name=db-instance-id,Values=$($rds_instance.Id)"

        do {
            $result = $(aws rds describe-db-instances --query $query --filters $filters --output json) | ConvertFrom-Json
        } while ($result[0].state -ne $waiting_states.RDS -and !$simulate)
    }

    if ($apply -and $applies) {
        [Linq.Enumerable]::Distinct([string[]]$applies) | % {
            Write-Host "Apply started instance $_ to sync its new Public IP with other resources..."
            if (!$simulate) { apply $_ }
        }
    }

    Write-Host "Done!"
}
