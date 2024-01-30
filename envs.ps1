Get-ChildItem $env:GIT_ROOT -File | ? { $_.Name -match '\.json$' } | % { code $_.FullName }
