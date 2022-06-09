<#
.SYNOPSIS
    Download private key from AWS SSM
.DESCRIPTION
    Download .pem file from ssm parameter
.PARAMETER file
    Path to *.pem file to download. If not specified - asks it
.PARAMETER prefix
    Prefix to key name to upload. If not specified - uses "private_key_"
.PARAMETER silent
    If specified - do not remember to remove the file manually
.EXAMPLE
    download-key
    # ask for private key file name and download ssm parameter to it
.EXAMPLE
    download-key D:\main.pem
    # download private_key_main from ssm as D:\main.pem
.EXAMPLE
    download-key D:\new.pem -prefix key_ -silent
    # download key_new from ssm as D:\new.pem and do not remember to remove the file manually
#>

Param (
    [string]$file,
    [string]$prefix,
    [switch]$silent
)

if (!$file) {
    $file = Read-Host -Prompt "Specify full path to *.pem file"
}

if ((Test-Path $file) -and !(confirm "File {{$file}} already exists, do you want to overwrite")) {
    exit
}

if (!$prefix) {
    $prefix = "private_key_"
}

$name = $prefix + [IO.Path]::GetFileNameWithoutExtension($file)

$result = aws ssm get-parameters --with-decryption --name $name --output json | ConvertFrom-Json

If ($result.InvalidParameters) {
    throw "Error while getting parameter $name from aws"
}

$key = $result.Parameters.Value -replace "\\n", "`n"
file $file $key

if (!$silent) {
    Write-Host "Remember to remove file $file manually!" -ForegroundColor Yellow
}
