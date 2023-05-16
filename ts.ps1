<#
.SYNOPSIS
	Boilerplate for Typescript project
.PARAMETER action
	One of { init | test | ignore }.
	Init - generate TS project
	Test - add test for module based on its exported functions
	Ignore - adds ignore pattern everywhere
.PARAMETER arg
	Should be one of (app | lib) for `init`
	Should be relative path to module for `test`
	Should be relative path to directory for `ignore`
#>

Param (
	[Parameter(Mandatory = $true)][ValidateSet('init', 'test', 'ignore')][string]$action,
	[Parameter(Mandatory = $true)][string]$arg
)

$location = Get-Location

repo ts {
	if ($repo -eq $location) {
		throw "Cannot init ts app itself"
	}
}

function AddToJSON($file, $key, $line) {
	$json = file $file
	$bound = "`"|'|\b"
	$parts = @($bound, $key, $bound, "\s*:\s*", "\[|\{", "\n\s*")
	$regex = ($parts | % { "($_)" }) -join ""
	$level1 = $json -split $regex
	$level2 = [System.Collections.ArrayList]($level1[$parts.Length + 1] -split "(,?)(\s*)(\}|\])")
	$comma = switch($level2[1]){ ","{""} ""{","} }
	$level2.Insert(2, $comma + $level1[$parts.Length] + $line)
	$level1[$parts.Length + 1] = $level2 -join ""
	$json = $level1 -join ""
	file $file $json
}

function StripGeneric($type) {
	$strippedType = $type -replace "<[^>]+>", ""
	if ($strippedType -ne $type) { return StripGeneric $strippedType }
	return $strippedType
}

function GetDateString(){
	return (Get-Date).ToString("yyyy-MM-dd")
}

function GetYearString(){
	return (Get-Date).ToString("yyyy")
}

$fields = @(
	@{Name = "NAME"; Input = $true}
	@{Name = "PATH"; Input = $true}
	@{Name = "DESCRIPTION"; Input = $true}
	@{Name = "DATE"; Callback = $function:GetDateString}
	@{Name = "YEAR"; Callback = $function:GetYearString}
)

switch ($action) {
	"init" {
		$types = @("app", "lib")

		if (!$types.Contains($arg)) {
			$usages = ($types | % { "`tts $action $_" }) -join "`n"
			throw "Usages:`n$usages"
		}

		$fields | % {
			if ($_.Input) {
				$_.Value = ask $_.Name
			}
			if ($_.Callback) {
				$_.Value = $_.Callback.Invoke($fields)[0]
			}
		}

		repo ts {
			$items = @()
			$items += Get-ChildItem -Recurse | ? { $fullName = $_.FullName; return ($types | ? {$fullName -match "\\.$_"}).Length -eq 0 }
			$items += Get-ChildItem ".$arg" -Recurse

			$items | % {
				$dst = $_.FullName.Replace($repo, $location).Replace("\.$arg", "")

				if ($_.PSIsContainer) {
					mkdir $dst -Force | Out-Null
				} else {
					$content = file $_.FullName
					$fields | % {
						$content = $content.Replace("{$($_.Name)}", $_.Value)
					}
					file $dst $content
				}
			}

			$newSrc = Join-Path $location "src"
			$newReadme = Join-Path $location "README.md"
			mkdir $newSrc -Force | Out-Null
		}

		if ($arg -eq "app") {
			AddToJSON -file package.json -key "scripts" -line "`"start`": `"node ./dist/index.js`""
		}
	}

	"test" {
		$arg = $arg -replace '\.ts$', ""
		$moduleParts = $arg -split "\/([^\/]+)$"
		$moduleDir = $moduleParts[0]
		$moduleName = $moduleParts[-2]
		$testDir = "$moduleDir/__tests__"
		$testFile = "$testDir/$moduleName.test.ts"
		$moduleFile = "$moduleDir/$moduleName.ts"
		$moduleContent = file $moduleFile

		$exportParts = $moduleContent -split "export default \{(.*?)\}"
		if ($exportParts.Length -eq 1) {
			throw "Please profide ``export default`` in file $moduleFile that will export all functions that needs to be tested"
		}

		$exports = $exportParts[1] -split '(\w+)' | ? { $_ -match '^\w+$' }

		$functionMatches = [Regex]::Matches($moduleContent, "(async )?function ([^(]+)\((.*?)\)")
		$allArguments = @()

		$functions = $functionMatches | % {
			$arguments = ((StripGeneric $_.Groups[3].Value) -split ",\s") | % {$_.Split(':')[0] -replace '\?$', ''}
			if ($arguments) { $allArguments += $arguments }

			return @{
				Name = $_.Groups[2].Value;
				Async = $_.Groups[1].Value -ne "";
				Arguments = $arguments;
			}
		}

		$nonExportedFunctions = $functions | ? { !$exports.Contains($_.Name) } | % { $_.Name }
		if ($nonExportedFunctions) {
			throw "Please include functions ($($nonExportedFunctions -join ", ")) into default export in order to test them"
		}

		$argumentMaxLength = ($allArguments | % { $_.Length } | measure -Maximum).Maximum
		$functionMaxLength = ($functions | % { $_.Name.Length } | measure -Maximum).Maximum

		$output = @()
		$output += "import $moduleName from '../$moduleName';"

		if ($functions.Length -gt 1) {
			$original = "original"
			$output += "const $original = jest.requireActual('../$moduleName').default as typeof $moduleName;";
			$output += "jest.mock<typeof $moduleName>('../$moduleName', () => ({";
			$functions | % {
				$output += "`t$($_.Name)$(" " * ($functionMaxLength - $_.Name.Length)) : jest.fn().mockImplementation(() => {}),";
			}
			$output += "}));";
		} else {
			$original = $moduleName
		}

		$output += ""

		if ($allArguments) {
			$allArguments | Sort | Get-Unique | % {
				$output += "const $_$(" " * ($argumentMaxLength - $_.Length)) = undefined;"
			}
			$output += ""
		}

		$output += "describe('$arg', () => {"

		$describes = @()
		$functions | % {
			$async = ""
			$await = ""
			if ($_.Async) { $async = " async" }
			if ($_.Async) { $await = " await" }
			$describe = @()
			$describe += "`tdescribe('$($_.Name)', () => {";
			$describe += "`t`tit('should return something',$async () => {"
			$describe += "`t`t`tconst result =$await $original.$($_.Name)($($_.Arguments -join ", "));"
			$describe += ""
			$describe += "`t`t`texpect($moduleName.$($_.Name)).toBeCalledWith($($_.Arguments -join ", "));"
			$describe += "`t`t`texpect(result).toEqual('something');"
			$describe += "`t`t});"
			$describe += "`t});";
			$describes += $describe -join "`n"
		}

		$output += ($describes -join "`n`n")
		$output += "});";
		$output += "";
		file $testFile ($output -join "`n")
	}

	"ignore" {
		$arg = $arg -replace '^\/?(.*?)\/?$', '$1'
		AddToJSON -file tsconfig.json -key "exclude" -line "`"$arg/`","
		AddToJSON -file jest.config.js -key "collectCoverageFrom" -line "'!<rootDir>/$arg/**',"
		AddToJSON -file .eslintrc.js -key "ignorePatterns" -line "'$arg/',"
		file .gitignore ((file .gitignore).Trim() + "`n$arg`n")
	}
}
