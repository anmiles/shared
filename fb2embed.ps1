<#
.DESCRIPTION
    Embed images into an fb2 file
.PARAMETER src
	Directory that contains image files (default - current directory)
.PARAMETER dst
	Output file (default - the same name as the current directory + .fb2 extension)
#>

Param (
    [string]$src,
    [string]$dst
)

$formats = @{
	".jpg" = "image/jpeg"
	".png" = "image/png"
}

if (!$src) {
	$src = "."
}

$src = Resolve-Path $src
$title = Split-Path $src -Leaf

if (!$dst) {
	$dst = $src + ".fb2"
}

$files = Get-ChildItem $src\* -Include ($formats.Keys | % { "*$_" })

$binaries = $files | % {
	$filename = $_.Name
	$path = $_.FullName
	$extension = $_.Extension
	$contentType = $formats[$extension]
	$content = [Convert]::ToBase64String([System.IO.File]::ReadAllBytes($path))
	return @{ filename = $filename; contentType = $contentType; content = $content }
}

$coverpage = $binaries[0].filename

$fb2 = @()
$fb2 += "<?xml version=`"1.0`" encoding=`"windows-1251`"?>"
$fb2 += "<FictionBook xmlns=`"http://www.gribuser.ru/xml/fictionbook/2.0`""
$fb2 += "  xmlns:l=`"http://www.w3.org/1999/xlink`">"
$fb2 += "  <description>"
$fb2 += "    <title-info>"
$fb2 += "      <author></author>"
$fb2 += "      <book-title>$title</book-title>"
$fb2 += "      <coverpage><image l:href=`"#$coverpage`"/></coverpage>"
$fb2 += "    </title-info>"
$fb2 += "  </description>"
$fb2 += "  <body>"
$fb2 += "    <section>"

$binaries | % {
	$fb2 += "      <image l:href=`"#$($_.filename)`"/>"
}

$fb2 += "    </section>"
$fb2 += "  </body>"

$binaries | % {
	$fb2 += "  <binary id=`"$($_.filename)`" content-type=`"$($_.contentType)`">" + $($_.content) + "</binary>"
}

$fb2 += "</FictionBook>"

file $dst ($fb2 -Join "`n")
