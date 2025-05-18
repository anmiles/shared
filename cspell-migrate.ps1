repo all -quiet {
	if ((Test-Path .vscode/settings.json) -or (Test-Path package.json)) {
		out $repo Yellow
		wait "Press ENTER to continue"
		edit
		node $PSScriptRoot\cspell-migrate.js

		$packages = npm ls
		$cspell_installed = $packages | grep "cspell@"
		$cspell_ru_installed = $packages | grep "@cspell/dict-ru_ru"
		$cyrillic_proposed = $false

		if (Test-Path package.json) {

			if (!$cspell_installed) {
				$cspell_installed = $true
				npm install -D cspell
			}

			$result = $false
			while (!$result) {
				npm run spellcheck

				$result = $?
				if (!$result) {
					if (!$cyrillic_proposed -and !$cspell_ru_installed) {
						$cyrillic_proposed = $true

						if (confirm "Do you want to enable russian dictionary") {
							npm install -D "@cspell/dict-ru_ru"
							npx cspell link add "@cspell/dict-ru_ru"
							node $PSScriptRoot\cspell-migrate-ru.js
						} else {
							wait "Fix spell errors and press ENTER to re-check"
						}
					} else {
						wait "Fix spell errors and press ENTER to re-check"
					}
				}
			}
		}
	}
}
