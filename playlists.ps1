<#
.SYNOPSIS
    Converts m3u8 playlists into mobile-compatible format
#>

$ignores = @("xhistory.m3u8")
$root = "H:/music/playlists"

if (!(confirm "Did you have exported all m3u8 playlists into $root")) { exit 1 }

Get-ChildItem $root/*.m3u8 | ? { !$ignores.Contains($_.Name) } | % {
	$src = $_.FullName
	$dst = $_.FullName.Replace($_.Name, (Join-Path "mobile" $_.Name))
	$content = file $_
	$content = $content -replace "H:\\music\\mp3\\", "primary/Music/mp3/"
	file $dst $content
}

"Done!"
