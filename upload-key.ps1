<#
.SYNOPSIS
    Upload private key to AWS SSM
.DESCRIPTION
    Read .pem file and upload it as ssm parameter
.PARAMETER file
    Path to *.pem file to upload. If not specified - asks it
.PARAMETER prefix
    Prefix to key name to upload. If not specified - uses "private_key_"
.PARAMETER silent
    If specified - do not remember to remove the file manually
.EXAMPLE
    upload-key
    # ask for private key file and upload it to ssm
.EXAMPLE
    upload-key D:\main.pem
    # upload D:\main.pem as private_key_main to ssm
.EXAMPLE
    upload-key D:\new.pem -prefix key_ -silent
    # upload D:\new.pem as key_new to ssm and do not remember to remove the file manually
#>

Param (
    [string]$file,
    [string]$prefix,
    [switch]$silent
)

if (!$file) {
    $file = Read-Host -Prompt "Specify full path to *.pem file"
}

if (!(Test-Path $file)) {
    throw "File doesn't exist"
}

if (!$prefix) {
    $prefix = "private_key_"
}

$name = $prefix + [IO.Path]::GetFileNameWithoutExtension($file)
$value = (Get-Content $file) -join "\n"

aws ssm put-parameter --type SecureString --name $name --value "$value" --overwrite

if (!$silent) {
    Write-Host "Remember to remove file $file manually!" -ForegroundColor Yellow
}