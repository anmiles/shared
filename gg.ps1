<#
.SYNOPSIS
    Grep files and their contents
.DESCRIPTION
    Grep specified text in specified files existing in current git repository in the current directory or its subdirectories
.PARAMETER file_pattern
    Pattern to regex search the file
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
    gg '\.ts$'
    # search all *.ts files
.EXAMPLE
    gg '\.ts$' -format json
    # get all *.ts files in JSON format
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}'
    # get all *.ts files and their named imports
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -value
    # get all *.ts files and their named imports (names only)
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -format files
    # get all *.ts files that contains named imports
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -format lines
    # get all named imports inside *.ts files
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -format lines -value
    # get all named imports (names only) inside *.ts files
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -format json
    # get all *.ts files and their named imports in JSON format
.EXAMPLE
    gg '\.ts$' 'import \{(.+)\}' -format json -value
    # get all *.ts files and their named imports (names only) in JSON format

#>

Param (
    [string]$file_pattern,
    [string]$text_pattern,
    [ValidateSet('text', 'files', 'lines', 'json')][string]$format = "text",
    [string]$mockFile,
    [switch]$value
)

if ($env:WSL_ROOT) {
	$exec = shpath -native (Join-Path $PSScriptRoot gg.sh)
	$cmd = "$exec -file_pattern '$file_pattern' -text_pattern '$text_pattern' -format '$format' -mockFile '$mockFile'"
    if ($value) { $cmd += " -value" }
    sh $cmd
    exit
}

if ($mockFile) {
    $mock = (file $mockFile | ConvertFrom-Json)
}

$files = if ($mock) {
    $mock.PSObject.Properties.Name
} else {
    (@(git ls-files) + @(git ls-files --exclude-standard --others) ) | ? { Test-Path $_ }
}

$files = $files | Sort { $_.Contains("/") }, { $_ }

if ($file_pattern) {
    $files = $files | grep -i -P $file_pattern
}

if ($text_pattern) {
    $json = @()

    $file_index = -1

    $files | % {
        $file = $_
        $file_index ++

        $entries = if ($mock) {
            @($mock.$file | grep -i -n -P $text_pattern)
        } else {
            @(grep -i -n -P $text_pattern $file.Replace("/", "\\"))
        }

        switch ($format) {
            "json" {
                $json += @{
                    file = $file
                    lines = @($entries | % {
                        $split = $_ -split '^(\d+):';
                        $line = [int]$split[1]
                        $value_str = $split[2]

                        if ($value) {
                            $value_str = [Regex]::Match($value_str, $text_pattern, 'IgnoreCase').Groups[1].Value
                        }

                        @{
                            line = $line
                            value = $value_str
                        }
                    })
                }
            }

            "files" {
                if ($entries) {
                    $file
                }
            }

            default {
                $token = [Guid]::NewGuid().ToString()

                if ($file_index -gt 0 -and $entries -and $format -eq "text") {
                    ""
                }

                $entries | % {
                    $nothing, $line, $entry = $_ -split '^(\d+):'
                    $value_str = [Regex]::Match($entry, $text_pattern, 'IgnoreCase').Groups[1].Value

                    if ($format -eq "lines") {
                        if ($value) {
                            $value_str
                        } else {
                            $entry
                        }
                    } else {
                        $output = (fmt $file "DarkMagenta") + ":" + (fmt $line "DarkCyan") + ":"

                        if ($value) {
                            $output += fmt $value_str "DarkYellow"
                        } else {
                            $tokenized = [Regex]::Replace($entry, $text_pattern, { param($match) $token + $match.Groups[0].Value + $token }, 'IgnoreCase')
                            $entry_split = $tokenized -split $token
                            $entry_split | % { $i = 0 } {
                                if ($i++ % 2) {
                                    if ($value_str) {
                                        $parts = $_ -split [Regex]::Escape($value_str)
                                        $output += fmt $parts[0] "Red"
                                        $output += fmt $value_str "DarkYellow"
                                        $output += fmt $parts[1] "Red"
                                    } else {
                                        $output += fmt $_ "Red"
                                    }
                                } else {
                                    $output += fmt $_
                                }
                            }
                        }

                        $output -join ""
                    }
                }
            }
        }
    }

    if ($format -eq "json") {
        $json | ConvertTo-Json -Depth 100 -Compress | % { [Regex]::Unescape($_) }
    }
} else {
    switch ($format) {
        "json" {
            $files | ConvertTo-Json -Depth 100 -Compress | % { [Regex]::Unescape($_) }
        }
        default {
            $files
        }
    }
}
