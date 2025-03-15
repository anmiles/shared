<#
.SYNOPSIS
    Base64-encode file
.DESCRIPTION
    Make base64-encoded version of file (text or binary or anything else, e. g. archive) to copy it as plain text and restore on remote server
    Suitable if no other ways to copy the file or directory to remote server
    Can encode image from clipboard
    Can encode file list from clipboard and make an archive from these files
.PARAMETER src
    Source file which to base64-encode. If omitted, try to get from clipboard
.PARAMETER dst
    Destination file where to save base64 string. If omitted, save to clipboard
.PARAMETER marker
    Optional marker to insert in the beginning of output string
.EXAMPLE
    encode files.zip files.zip.base64
    # base64-encode files.zip and save to files.zip.base64
.EXAMPLE
    encode image.png
    # base64-encode image.png and save to clipboard
.EXAMPLE
    encode
    # try to get text, image or file list from clipboard, encode and save back to clipboard. The fastest way to "base64-copy" image or files
#>

Param (
    [string]$src,
    [string]$dst,
    [string]$marker = ""
)

Function ConvertBytes($bytes) {
    return $marker + [Convert]::ToBase64String($bytes)
}

$utf8 = New-Object System.Text.UTF8Encoding $false

if ($src) {
    if (!(Test-Path $src)) { throw "File '$($src)' doesn't exist!" }
    $bytes = file $src -bytes
    $text = ConvertBytes($bytes)

    if ($dst) {
        file $dst $text
    } else {
        Set-Clipboard $text
    }
} else {

    $clipboard = Get-ClipBoard -Format Text
    if ($clipboard) {
        $bytes = $utf8.GetBytes($clipboard)
        $text = ConvertBytes($bytes)
        Set-Clipboard $text
        exit
    }

    $clipboard = Get-ClipBoard -Format Image
    if ($clipboard) {
        $tmpfile = Join-Path $env:TEMP ([Guid]::NewGuid().Guid)
        $clipboard.Save($tmpfile)
        $bytes = file $tmpfile -bytes
        $text = ConvertBytes($bytes)
        Set-Clipboard $text
        exit
    }

    $clipboard = Get-ClipBoard -Format FileDropList
    if ($clipboard) {
        $tmpdir = Join-Path $env:TEMP ([Guid]::NewGuid().Guid)
        New-Item -ItemType Directory -Path $tmpdir -Force | Out-Null
        $clipboard | % { Copy-Item $_ $tmpdir -Force -Recurse }
        $archive = zip $tmpdir
        $bytes = file $archive -bytes
        $text = ConvertBytes($bytes)
        Set-Clipboard $text
        Remove-Item -Force -Recurse $tmpdir
        Remove-Item -Force $archive
        exit
    }

    throw "Unable to encode clipboard, it doesn't seem a text, image or files"
}
