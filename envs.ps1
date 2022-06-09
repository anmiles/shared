$filename = "env.json"
$root = Split-Path $env:GIT_ROOT -Parent

Get-ChildItem -Path $root -Directory | % {
	$envFile = Join-Path $_.FullName $filename
	if (Test-Path $envFile) { code $envFile }
}
