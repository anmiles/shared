<#
.SYNOPSIS
	Find code in js/ts files across all repositories
.PARAMETER text_pattern
	Pattern to regex search the text in the file
.PARAMETER format
	Output format:
		text (default) - colored human-friendly output
		files - plain list of files
		lines - plain list of lines (or files if text_pattern missing)
		json - machine-readable JSON
.PARAMETER mock
	Whether to mock file system (for test purposes)
.PARAMETER value
	Return value of the first matched group. Not applicable if format == 'files' or text_pattern missing
.EXAMPLE
	g 'import \{(.+)\}'
	# get all named imports in js/ts files
.EXAMPLE
	g 'import \{(.+)\}' -value
	# get all named imports in js/ts files (names only)
.EXAMPLE
	g 'import \{(.+)\}' -format files
	# get all js/ts files that contains named imports
.EXAMPLE
	g 'import \{(.+)\}' -format lines
	# get all lines with named imports in js/ts files
.EXAMPLE
	g 'import \{(.+)\}' -format lines -value
	# get all named imports (names only) in js/ts files
.EXAMPLE
	g 'import \{(.+)\}' -format json
	# get all named imports in js/ts files JSON format
.EXAMPLE
	g 'import \{(.+)\}' -format json -value
	# get all named imports (names only) in js/ts files JSON format

#>

Param (
	[string]$text_pattern,
	[ValidateSet('text', 'files', 'lines', 'json')][string]$format = "text",
	[string]$mockFile,
	[switch]$value
)

repo all -quiet {
	$results = gg -file_pattern '\.[cm]?[jt]sx?$' -text_pattern $text_pattern -format $format -mockFile $mockFile -value:$value

	if ($results) {
		out $repo Yellow
		$results
	}
}
