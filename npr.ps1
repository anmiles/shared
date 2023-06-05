<#
.SYNOPSIS
    Wrapper to run npm commands in selected repositories
.PARAMETER action
    One of { install | lint | build | test }
.PARAMETER test
    Specific file to test (if action = test)
.PARAMETER coverage
    Whether to collect coverage  (if action = test)
.PARAMETER updateSnapshots
    Whether to update jest snapshots (if action = test)
.PARAMETER watch
    Whether to enable watch flag for jest (if action = test)
.PARAMETER inspect
    Whether to inspect test with inspect-brk (if action = test)
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
	npr
	# run `npm install`; `npm run lint:fix`; `npm run test`; `npm run build`
.EXAMPLE
    npr install
    # run `npm install`
.EXAMPLE
    npr lint
    # run `npm run lint:fix`
.EXAMPLE
	npr test -t library -ciwu
	# run `npm run test:watch:coverage` to execute tests in src/lib/__tests__/library.test.ts with covering src/lib/library.ts and updating snapshots in watch mode with debugger
.EXAMPLE
    npr build
    # run `npm run build`
#>

Param (
    [ValidateSet('', 'install', 'lint', 'test', 'build')][string]$action,
    [string]$test,
    [switch]$coverage,
    [switch]$inspect,
    [switch]$watch,
    [switch]$updateSnapshots,
    [switch]$quiet
)

$actions = @{
	install = "npm install";
	lint = "npm run lint:fix";
	test = "npm run test";
	build = "npm run build";
}

if ($action) {
	$actions = @{$action = $actions[$action]}
}

repo -quiet:$quiet -action {
	$exitCodes = 0
    Import-Module $env:MODULES_ROOT\timer.ps1 -Force
    $timer = Start-Timer

	$actions.Keys | % {
		$title = $_
		$command = $actions[$_]

		if ($title -eq "test") {
			$args = @()

			if ($updateSnapshots) {
				$args += "--updateSnapshots"
			}

			if ($watch) {
				if ($test) {
					$args += "--watch"
				} else {
					$args += "--watchAll"
				}
			}

			if ($inspect) {
				$args += "--inspect"
			}

			if ($coverage) {
				$args += "--coverage"

				if ($test) {
					$args += "--collectCoverageFrom='src/lib/$test.ts'"
				}
			}

			if ($test) {
				$test = $test.Trim().Replace(" $([char]8250) ", " ").Replace(" > ", " ")
				$args += "--testNamePattern 'src/lib/$test'"
				$args += "src/lib/__tests__/$test.test.ts"
			}

			if ($args.Length) {
				$command += " -- " + ($args -join " ")
			}
		}

		$timer.StartTask($title)

		iex $command
		if (!$?) { $exitCodes ++ }

		$timer.FinishTask()
	}

	$timer.Finish()

	if ($exitCodes) { throw }
}
