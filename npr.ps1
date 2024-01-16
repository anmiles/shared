<#
.SYNOPSIS
    Wrapper to run npm commands in selected repositories
.PARAMETER action
    One of { install | lint | build | test }
.PARAMETER lib
    Specific lib to test (if action = test)
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
	npr test -l library -ciwu
	# run `npm run test:watch:coverage` to execute tests in src/lib/__tests__/library.test.ts with covering src/lib/library.ts and updating snapshots in watch mode with debugger
.EXAMPLE
    npr build
    # run `npm run build`
#>

Param (
    [ValidateSet('', 'install', 'lint', 'test', 'build')][string]$action,
    [string]$lib,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$specs,
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
			if ($lib) {
				$args += "--watch"
			} else {
				$args += "--watchAll"
			}

			$args += "--verbose=false"
		}

		if ($inspect) {
			$command = "node --inspect-brk ./node_modules/jest/bin/jest.js"
		} else {
			$command += " --"
		}

		if ($coverage) {
			$args += "--coverage"

			if ($lib) {
				$args += "--collectCoverageFrom='src/lib/$lib.ts'"
			}
		}

		if ($lib) {
			if ($specs) {
				$pattern = (($specs | % { $_.Replace(" $([char]8250) ", " ").Replace(" > ", " ") }) | ? { $_ }) -join " "
				$args += "--testNamePattern '$pattern'"
			}

			$lib -match '^((.+)/)?([^\/]+)$' | Out-Null
			$filename = $matches[3]
			$directory = $matches[2]
			$args += (@("src/lib", $matches[2], "__tests__", "$filename.test.ts") | ? { $_ }) -join "/"
		}

		if ($args.Length) {
			$command += " " + ($args -join " ")
		}
	}

	$timer.StartTask($title)

	$command
	iex $command
	if (!$?) { $exitCodes ++ }

	$timer.FinishTask()
}

$timer.Finish()

if ($exitCodes) { throw }
