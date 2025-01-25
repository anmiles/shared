Function GetTests($ps1, $mockFile) {

	return @(
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$'"
			Expected = @(
				"src/a.ts"
				"src/b1.ts"
				"src/b2.ts"
			)
			Comment = "[file] text"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -format files"
			Expected = @(
				"src/a.ts"
				"src/b1.ts"
				"src/b2.ts"
			)
			Comment = "[file] files"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -format lines"
			Expected = @(
				"src/a.ts"
				"src/b1.ts"
				"src/b2.ts"
			)
			Comment = "[file] lines"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -format json"
			Expected = @(
				"src/a.ts"
				"src/b1.ts"
				"src/b2.ts"
			) | ConvertTo-Json -Depth 100 -Compress | % { [Regex]::Unescape($_) }
			Comment = "[file] json"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}'"
			Expected = @(
				fmt -parse "{DarkMagenta:src/a.ts}:{DarkCyan:1}:{Red:import {}{DarkYellow: b1 }{Red:`}} from './b1';"
				fmt -parse "{DarkMagenta:src/a.ts}:{DarkCyan:3}:{Red:import {}{DarkYellow: b2 }{Red:`}} from './b2';"
				""
				fmt -parse "{DarkMagenta:src/b2.ts}:{DarkCyan:1}:{Red:IMPORT {}{DarkYellow: c1, c2 }{Red:`}} from './c';"
			)
			Comment = "[file] [line] text"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -value"
			Expected = @(
				fmt -parse "{DarkMagenta:src/a.ts}:{DarkCyan:1}:{DarkYellow: b1 }"
				fmt -parse "{DarkMagenta:src/a.ts}:{DarkCyan:3}:{DarkYellow: b2 }"
				""
				fmt -parse "{DarkMagenta:src/b2.ts}:{DarkCyan:1}:{DarkYellow: c1, c2 }"
			)
			Comment = "[file] [line] text -value"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -format files"
			Expected = @(
				"src/a.ts"
				"src/b2.ts"
			)
			Comment = "[file] [line] files"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -format lines"
			Expected = @(
				"import { b1 } from './b1';"
				"import { b2 } from './b2';"
				"IMPORT { c1, c2 } from './c';"
			)
			Comment = "[file] [line] lines"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -format lines -value"
			Expected = @(
				" b1 "
				" b2 "
				" c1, c2 "
			)
			Comment = "[file] [line] lines -value"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -format json"
			Expected = @(
				@{
					file = "src/a.ts"
					lines = @(
						@{
							line = 1
							value = "import { b1 } from './b1';"
						},
						@{
							line = 3
							value = "import { b2 } from './b2';"
						}
					)
				}
				@{
					file = "src/b1.ts"
					lines = @(
					)
				}
				@{
					file = "src/b2.ts"
					lines = @(
						@{
							line = 1
							value = "IMPORT { c1, c2 } from './c';"
						}
					)
				}
			) | ConvertTo-Json -Depth 100 -Compress | % { [Regex]::Unescape($_) }
			Comment = "[file] [line] json"
		}
		@{
			Command = "gg -ps1:$ps1 -mockFile $mockFile -file_pattern '\.ts$' -text_pattern 'import \{(.+)\}' -format json -value"
			Expected = @(
				@{
					file = "src/a.ts"
					lines = @(
						@{
							line = 1
							value = " b1 "
						},
						@{
							line = 3
							value = " b2 "
						}
					)
				}
				@{
					file = "src/b1.ts"
					lines = @(
					)
				}
				@{
					file = "src/b2.ts"
					lines = @(
						@{
							line = 1
							value = " c1, c2 "
						}
					)
				}
			) | ConvertTo-Json -Depth 100 -Compress | % { [Regex]::Unescape($_) }
			Comment = "[file] [line] json -value"
		}
	)
}

$mockFile = Join-Path $PSScriptRoot gg.mock.json

@(GetTests "`$true" $mockFile) + @(GetTests "`$false" (shpath -native $mockFile))
