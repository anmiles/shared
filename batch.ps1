<#
.SYNOPSIS
    Batch execute multiple commands
.PARAMETER commands
    Commands to execute
.EXAMPLE
	$output1, $output2 = batch @("command1", "command2")
#>

Param (
    [string[]]$commands
)

$output = if ($env:WSL_ROOT) {
	$command = ($commands | % { "($_) | tr '\n' '\0'" }) -join "; echo ''; "
	sh $command
} else {
	$command = ($commands | % { "`$($_) -join `"`0`"" }) -join ";"
	iex $command
}

$output | % {
	$output_item = ($_ -replace '\0$', '') -split '\0'

	if ($output_item.Count -eq 1) {
		return $output_item[0]
	} else {
		return ,$output_item
	}
}
