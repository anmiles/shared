Param (
	[switch]$save
)

$dir = Join-Path $env:GIT_ROOT ".scripts.diff"
$zip = "$dir.zip"

$modules_temp = Join-Path $dir "modules.diff"
$shared_temp = Join-Path $dir "shared.diff"

$modules = Join-Path $env:SCRIPTS_ROOT "modules"
$shared = Join-Path $env:SCRIPTS_ROOT "shared"

if (!$save) {
	Remove-Item $dir -Force -Recurse
	mkdir $dir | Out-Null

	git -C $modules add --all
	git -C $shared add --all

	git -C $modules diff HEAD > $modules_temp
	git -C $shared diff HEAD > $shared_temp

	zip -src $dir -dst $zip
	encode $zip
	out "{Yellow:Save scrip and press any key}"
	Read-Host

	goto modules
	discard
	git pull

	goto shared
	discard
	git pull

	goto scripts
	save -push
} else {
	decode -dst $zip
	unzip -src $zip -dst $dir
	(file $modules_temp) -replace '\r\n', "`n" | git -C $modules apply
	(file $shared_temp) -replace '\r\n', "`n" | git -C $shared apply
	save -push modules
	save -push shared
	save -push scripts
}
