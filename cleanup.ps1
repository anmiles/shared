$scheduledTagName = "Terminate" # Tag name to schedule terminate on next launch
$scheduledTagValue = "True" # Tag values to schedule terminate on next launch

$environmentTagName = "Environment" # Tag name to detect enviromnent
$envinronmentLive = "live" #Tag value for live environment

$typeTagName = "Type" #Tag name to detect instance type
$typeWeb = "web" #Tag value for web instances

$versionTagName = "WebVersion" #Tag name to detect web version

$packerKeyNameRegex = "^packer_.*" # Regex for keypair that might be assigned to packer instance and should be removed on terminate
$packerSecurityGroupNameRegex = "^packer_.*" # Regex for security group name that might be assigned to packer instance and should be removed on terminate

$disableInstanceTermination = $true

Write-Host "Getting instances..."
$query = "Reservations[*].Instances[*].{InstanceId:InstanceId,StateName:State.Name,KeyName:KeyName,SecurityGroups:SecurityGroups[*].{GroupId:GroupId,GroupName:GroupName},Volumes:BlockDeviceMappings[*].Ebs,${scheduledTagName}:Tags[?Key==``$scheduledTagName``].Value|[0],${versionTagName}:Tags[?Key==``$versionTagName``].Value|[0],${environmentTagName}:Tags[?Key==``$environmentTagName``].Value|[0],${typeTagName}:Tags[?Key==``$typeTagName``].Value|[0]}"

$instances = ($(aws ec2 describe-instances --query "$query" --output json) -join "" | ConvertFrom-Json)

$lastLiveWebVersion = ec2-tags WebVersion

# If instance doesn't have tag $scheduledTagName = $scheduledTagValue and it's either a packer instance or stopped web instance with previous version, then mark it to delete on next launch
$tagInstances = $instances | ? {$_.StateName -ne "terminated" -and $_.$scheduledTagName -ne $scheduledTagValue -and (($_.$typeTagName -eq $typeWeb -and $_.StateName -eq "stopped" -and $_.$versionTagName -lt $lastLiveWebVersion) -or ($_.KeyName -match $packerKeyNameRegex))}

if ($tagInstances) {
    Write-Host "Tagging instances [$($tagInstances.InstanceId)] to terminate on next launch..."
    aws ec2 create-tags --tags "Key=$scheduledTagName,Value=$scheduledTagValue" --resources $tagInstances.InstanceId
}

# If instance already has tag $scheduledTagName, terminate it
$terminateInstances = $instances | ? {$_.StateName -ne "terminated" -and $_.$scheduledTagName -eq $scheduledTagValue}
$cleanupInstances = @()

foreach ($instance in $terminateInstances) {
    $value = (aws ec2 describe-instance-attribute --instance-id $instance.InstanceId --attribute disableApiTermination --output json | ConvertFrom-Json).DisableApiTermination.Value

    if ($value -and $disableInstanceTermination) {
        Write-Host "Disabling termination protection on instance [$($instance.InstanceId)] ..."
        aws ec2 modify-instance-attribute --instance-id $instance.InstanceId --attribute disableApiTermination --value false
    }

    if (!$value -or $disableInstanceTermination) {
        Write-Host "Terminating instance [$($instance.InstanceId)] ..."
        $result = aws ec2 terminate-instances --instance-ids $instance.InstanceId
        $cleanupInstances += $instance
    }
}

foreach ($instance in $cleanupInstances) {
    do {
        $state = $(aws ec2 describe-instances --filters "Name=instance-id,Values=$($instance.InstanceId)" --query "Reservations[*].Instances[*].State.Name" --output text)
        Write-Host "Waiting instance [$($instance.InstanceId)] state... $state"
    } while ($state -ne "terminated")

    # Delete keypair only if it matches $packerKeyNameRegex
    if ($instance.KeyName -match $packerKeyNameRegex) {
        Write-Host "Deleting key pair $($instance.KeyName) ..."
        $result = aws ec2 delete-key-pair --key-name $instance.KeyName
    }
    
    # Delete security groups that match $packerKeyNameRegex
    foreach ($securityGroup in $instance.SecurityGroups) {
        if ($securityGroup.GroupName -match $packerSecurityGroupNameRegex) {
            Write-Host "Deleting security group $($securityGroup.GroupId) ..."
            $result = aws ec2 delete-security-group --group-id $securityGroup.GroupId
        }
    }

    # Delete volumes that were attached to instance excluding current userdata volume for live environment
    $volumes = ($(aws ec2 describe-volumes --query "Volumes[*].{VolumeId:VolumeId,${typeTagName}:Tags[?Key==``$typeTagName``].Value|[0]}" --filters Name=tag:$environmentTagName,Values=$($instance.$environmentTagName) Name=tag:$versionTagName,Values=$($instance.$versionTagName) --output json) -join "" | ConvertFrom-Json)

    $volumes | ? {$instance.$environmentTagName -ne $environmentLive -or $_.$typeTagName -ne "userdata"} | % {
        Write-Host "Deleting volume $_.VolumeId ..."
        $result = aws ec2 delete-volume --volume-id $_.VolumeId
    }

    # Delete network interfaces that were attached to instance
    $networkInterfaceIds = ($(aws ec2 describe-network-interfaces --query "NetworkInterfaces[*].NetworkInterfaceId" --filters Name=tag:$environmentTagName,Values=$($instance.$environmentTagName) Name=tag:$versionTagName,Values=$($instance.$versionTagName) --output json) -join "" | ConvertFrom-Json)

    $networkInterfaceIds | % {
        Write-Host "Deleting network interface $_ ..."
        $result = aws ec2 delete-network-interface --network-interface-id $_
    }    
}

Write-Host "Done!"
