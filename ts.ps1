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

function AddToFile($file, $line) {
	if ((Test-Path $file)) {
		$contents = file $file
	} else {
		$contents = ""
	}

	file $file ($contents.Trim() + "`n$line`n")
}

function AddToJSON($file, $key, $line) {
	if (!(Test-Path $file)) {
		out "{DarkYellow:Skipping AddToJSON for non-existing file $file}"
		return
	}

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
	@{Name = "name"; Input = $true}
	@{Name = "description"; Input = $true}
	@{Name = "date"; Callback = $function:GetDateString}
	@{Name = "year"; Callback = $function:GetYearString}
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
				# Write-Host "value for $($_.Name) is $($_.Value)"
			}
		}

		$location = Get-Location
		$template = "ts-template-$arg"

		repo $template -quiet -action {
			if ($repo -eq $location) {
				throw "Cannot init $template itself"
			}

			gg | % {
				$src = $_
				$dst = Join-Path $location $_
				$content = file $src

				$fields | ? { $_.Name -ne "name" } | % {
					$content = $content.Replace("$template-$($_.Name)", $_.Value)
				}

				$fields | ? { $_.Name -eq "name" } | % {
					$content = $content.Replace("$template", $_.Value)
				}

				Write-Host "Creating $src ... " -NoNewLine
				$parent = Split-Path $dst -Parent
				New-Item $parent -Type Directory -Force | Out-Null
				file $dst $content
				Write-Host "done!"
			}
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
		$functionMatches = [Regex]::Matches($moduleContent, "(^|\n)\s*(async )?function ([^(<]+)(<.*>)?\((.*?)\)")
		$allArguments = @()

		$functions = $functionMatches | % {
			$argsMatch = [Regex]::Match($_.Groups[5].Value, '^(^\s*\{\s*)?(.*?)\s*(\}|$)')
			$isBrackets = $argsMatch.Groups[1].Length -gt 0
			$arguments = ((StripGeneric $argsMatch.Groups[3]) -split ",\s") | % {$_.Split(':')[0] -replace '\?$', ''}
			if ($arguments) { $allArguments += $arguments }

			return @{
				Name = $_.Groups[3].Value;
				Async = $_.Groups[2].Value -ne "";
				IsBrackets = $isBrackets;
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
		$output += ""

		if ($functions.Length -gt 1) {
			$original = "original"
			$output += "// eslint-disable-next-line @typescript-eslint/no-unsafe-member-access";
			$output += "const $original = jest.requireActual<{ default : typeof $moduleName }>('../$moduleName').default;";
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
			$openBracket = ""
			$closeBracket = ""
			if ($_.Async) { $async = " async" }
			if ($_.Async) { $await = " await" }
			if ($_.IsBrackets) { $openBracket = "{" }
			if ($_.IsBrackets) { $closeBracket = "}" }
			$arguments = (@($openBracket, ($_.Arguments -join ", "), $closeBracket) | ? { $_ }) -join " "

			$describe = @()
			$describe += "`tdescribe('$($_.Name)', () => {";
			$describe += "`t`tit('should return something',$async () => {"
			$describe += "`t`t`tconst result =$await $original.$($_.Name)($arguments);"
			$describe += ""
			$describe += "`t`t`texpect($moduleName.$($_.Name)).toBeCalledWith($arguments);"
			$describe += "`t`t`texpect(result).toEqual('something');"
			$describe += "`t`t});"
			$describe += "`t});";
			$describes += $describe -join "`n"
		}

		$output += ($describes -join "`n`n")
		$output += "});";
		$output += "";

		if (!(Test-Path $testDir)) {
			New-Item -Type Directory $testDir -Force | Out-Null
		}

		file $testFile ($output -join "`n")
		code $testFile
	}

	"ignore" {
		$ignore = $arg -replace '^\/?(.*?)\/?$', '$1'
		AddToFile -file .eslintignore $ignore
		AddToFile -file .gitignore $ignore
		AddToFile -file .npmignore $ignore
	}
}
