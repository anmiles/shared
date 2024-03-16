$mock = @{
	"src/a.ts" = "import { b1 } from './b1';`n`nimport { b2 } from './b2';`n`nconsole.log(1);`n"
	"src/b1.ts" = "console.log(2);`n"
	"src/b2.ts" = "import { c1, c2 } from './c';`n`nconsole.log(3);`n"
}

@(
    @{
		Command = "gg -mock `$mock '\.ts$'"
		Expected = @(
			"src/a.ts"
			"src/b1.ts"
			"src/b2.ts"
		)
		Comment = "[file] text"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' -format files"
		Expected = @(
			"src/a.ts"
			"src/b1.ts"
			"src/b2.ts"
		)
		Comment = "[file] files"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' -format lines"
		Expected = @(
			"src/a.ts"
			"src/b1.ts"
			"src/b2.ts"
		)
		Comment = "[file] lines"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' -format json"
		Expected = @(
			"src/a.ts"
			"src/b1.ts"
			"src/b2.ts"
		) | ConvertTo-Json
		Comment = "[file] json"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}'"
		Expected = @(
			fmt "{DarkMagenta:src/a.ts}:{DarkCyan:1}:{Red:import {}{DarkYellow: b1 }{Red:`}} from './b1';"
			fmt "{DarkMagenta:src/a.ts}:{DarkCyan:3}:{Red:import {}{DarkYellow: b2 }{Red:`}} from './b2';"
			""
			fmt "{DarkMagenta:src/b2.ts}:{DarkCyan:1}:{Red:import {}{DarkYellow: c1, c2 }{Red:`}} from './c';"
		)
		Comment = "[file] [line] text"
}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -value"
		Expected = @(
			fmt "{DarkMagenta:src/a.ts}:{DarkCyan:1}:{DarkYellow: b1 }"
			fmt "{DarkMagenta:src/a.ts}:{DarkCyan:3}:{DarkYellow: b2 }"
			""
			fmt "{DarkMagenta:src/b2.ts}:{DarkCyan:1}:{DarkYellow: c1, c2 }"
		)
		Comment = "[file] [line] text -value"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -format files"
		Expected = @(
			"src/a.ts"
			"src/b2.ts"
		)
		Comment = "[file] [line] files"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -format lines"
		Expected = @(
			"import { b1 } from './b1';"
			"import { b2 } from './b2';"
			"import { c1, c2 } from './c';"
		)
		Comment = "[file] [line] lines"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -format lines -value"
		Expected = @(
			" b1 "
			" b2 "
			" c1, c2 "
		)
		Comment = "[file] [line] lines -value"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -format json"
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
						value = "import { c1, c2 } from './c';"
					}
				)
			}
		) | ConvertTo-Json
		Comment = "[file] [line] json"
	}
	@{
		Command = "gg -mock `$mock '\.ts$' 'import \{(.+)\}' -format json -value"
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
		) | ConvertTo-Json
		Comment = "[file] [line] json -value"
	}
)
