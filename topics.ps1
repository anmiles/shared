<#
.DESCRIPTION
    Set github topics based on tags in package.json and used technologies
.PARAMETER name
	Repository name to set topics to. If empty - process all github-hosted repositories
#>

Param (
    [string]$name = "all"
)

$frontend_libs_names = @("react", "vue", "knockout", "jquery", "leaflet")

$technologies = @(
	@{ name = "nodejs"; 		condition = { $packageJSONs } }
	@{ name = "javascript";		condition = {
		if ($packageJSONs -and (!$packages.Contains("typescript") -or ($packageJSONs | ? { $_.scripts -and $_.scripts.build }))) { return $true }
		if ($files | grep '\.js$') { return $true }
		return $false
	} }
	@{ name = "typescript";		condition = { $packages.Contains("typescript") } }
	@{ name = "c-sharp";		condition = { $files | grep '\.cs$' } }
	@{ name = "aspnet";			condition = { $files | grep -i 'web\.config$' } }
	@{ name = "powershell";		condition = { ($files | grep -i '\.ps1$') -is [Array] } }
	@{ name = "python";			condition = { $files | grep -i '\.py$' } }
	@{ name = "java";			condition = { $files | grep '\.java$' } }
	@{ name = "android"; 		condition = { $files | grep 'AndroidManifest\.xml$' } }
	@{ name = "apk";			condition = { $files | grep 'AndroidManifest\.xml$' } }
	@{ name = "hcl";			condition = { $files | grep '\.tf$' } }
	@{ name = "library";		condition = { (Get-Item .).Parent.Name -eq "lib" } }
	@{ name = "website";		condition = { ($files | grep -i 'web\.config$') -or ($name -eq "anmiles.net") } }
	@{ name = "backend";		condition = { ($packages | ? { $_.StartsWith("@nestjs/")}) -or $packages.Contains("express") } }
	@{ name = "frontend";		condition = { $frontend_libs.Contains("react") -or $frontend_libs.Contains("knockout") -or $frontend_libs.Contains("vue") } }
	@{ name = "react";			condition = { $frontend_libs.Contains("react") } }
	@{ name = "knockout";		condition = { $frontend_libs.Contains("knockout") } }
	@{ name = "vue";			condition = { $frontend_libs.Contains("vue") } }
	@{ name = "jquery";			condition = { $frontend_libs.Contains("jquery") } }
	@{ name = "jest";			condition = { $packages.Contains("jest") } }
	@{ name = "css";			condition = { $files | grep -E '\.(css|less)$' } }
	@{ name = "less";			condition = { $files | grep '\.less$' } }
	@{ name = "nestjs";			condition = { ($packages | ? { $_.StartsWith("@nestjs/")}) } }
	@{ name = "next";			condition = { $packages.Contains("next") } }
	@{ name = "mongodb";		condition = { $packages.Contains("mongodb") } }
	@{ name = "graphql";		condition = { $packages.Contains("graphql") } }
	@{ name = "postgres";		condition = { $packages.Contains("postgres") -or $packages.Contains("pg") } }
	@{ name = "express";		condition = { $packages.Contains("express") } }
	@{ name = "leaflet";		condition = { $frontend_libs.Contains("leaflet") } }
	@{ name = "googleapis";		condition = { $packages.Contains("googleapis") } }
	@{ name = "phantomjs";		condition = { $packages.Contains("phantom") -or $packages.Contains("phantomjs") } }
	@{ name = "docker";			condition = { $packageJSONs | ? { $_.scripts -and $_.scripts | grep docker } } }
	@{ name = "electron";		condition = { $packages.Contains("electron") } }
	@{ name = "mssql";			condition = { $packages.Contains("mssql") -or ($files | grep -i 'web\.config$' | ? { gg $_ "<connectionStrings>" }) } }
	@{ name = "aws";			condition = { (gg .json ami_name) -or (gg provider.tf '"aws"') } }
	@{ name = "stl";			condition = { $files | grep '\.stl$' } }
	@{ name = "maps";			condition = { $frontend_libs.Contains("leaflet") } }
	@{ name = "charts";			condition = { $packages.Contains("chart.js") -or $packages.Contains("graph") -or $packages.Contains("vega") } }
	@{ name = "telegraf";		condition = { $packages.Contains("telegraf") } }
	@{ name = "telethon";		condition = { $files | grep '\.py$' | ? { gg $_ telethon } } }
	@{ name = "telegram";		condition = { $packages | grep telegram } }
)

$topics = @{}

out "{Yellow:Scanning repositories...}"

repo -name $name -quiet {
	if (!(@("git@github.com:$env:GITHUB_USER/", "https://github.com/$env:GITHUB_USER/") | ? { $repository.remote.StartsWith($_) })) {
		out "{DarkYellow:$name}`n[skip]"
		return
	}

	out "{Green:$name}"
	$topics[$name] = @()
	$packages = (packages).name
	if (!$packages) { $packages = @() }
	$files = gg
	$packageJSONs = $files | grep package.json | % { file $_ | ConvertFrom-JSON }
	$frontend_libs_in_html = gg '\.html$' -E "/\($($frontend_libs_names -Join "|")\)\W"
	$frontend_libs = $frontend_libs_names | ? {
		if ($packages.Contains($_)) { return $true }
		if ($files | grep "/$_\W") { return $true }
		if ($frontend_libs_in_html | grep $_) { return $true }
		return $false
	}
	if (!$frontend_libs) { $frontend_libs = @() }

	$technologies | % {
		if (Invoke-Command $_.condition) {
			$topics[$name] += $_.name
		}
	}

	$packageJSONs | % {
		if ($_.keywords) { $_.keywords | ? { $_ -notmatch '^\{.*\}$' } | % { $topics[$name] += $_ } }
	}

	$topics[$name] = @($topics[$name] | Unique)
	out ($topics[$name] -join " ")
}

out "{Yellow:Updating topics...}"

gitservice -token admin -exec {
	$topics.Keys | Sort | % {
		$name = $_
		out "{Green:$name}"
		[void](Load-GitService "https://api.github.com/repos/$env:GITHUB_USER/$name/topics" -method PUT -data @{ names = $topics[$name] } | ConvertTo-Json)
	}
}
