$preserve_commands = @("difftool")

if ($preserve_commands.Contains($args[0])) {
	& "C:\Program Files\Git\bin\git.exe" $args
	exit
}

if ($args) {
	$args = $args | % {
		if ($_ -is [string] -and ($_[0] -eq "%" -or $_.Contains(" ") -or $_.Contains("'"))) {
			return "'$($_ -replace "'", "'\''")'"
		}

		return $_
	}

	sh "git $args"
} else {
	sh "tig"
}
