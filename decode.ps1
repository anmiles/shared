<#
.SYNOPSIS
    Base64-decode file
.DESCRIPTION
    Decode a base64-encoded version of file (text or binary or anything else, e. g. archive)
    Suitable if no other ways to copy the file or directory to remote server
.PARAMETER dst
    Destination file where to save decoded base64 string.
.PARAMETER src
    Source file or archive to decode. If omitted, get text from clipboard
.EXAMPLE
    encode files.zip
    # base64-encode files.zip and save to files.zip.base64
.EXAMPLE
    encode image.png image.png.txt
    # base64-encode image.png and save to image.png.txt
#>

Param (
    [string]$src,
    [string]$dst
)

$utf8 = New-Object System.Text.UTF8Encoding $false

if ($src) {
    if (!(Test-Path $src)) { throw "File '$($src)' doesn't exist!" }
    $text = file $src
} else {
    $text = Get-ClipBoard -Format Text
}

$bytes = [Convert]::FromBase64String($text)

if ($dst) {
    file $dst -bytes $bytes
} else {
    $text = $utf8.GetString($bytes)
    Set-Clipboard $text
}
