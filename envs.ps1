Get-ChildItem $env:GIT_ROOT -File | ? { $_.Name -match 'env\.|\.json$' } | Sort | % {
	if ($env:WSL_ROOT) {
		sh "code $(shpath -native $_.FullName)"
	} else {
		code $_.FullName
	}
}
