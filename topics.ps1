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
	@{ name = "javascript";		condition = { $files | grep '\.js$' } }
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
	@{ name = "website";		condition = { ($files | grep -i 'web\.config$') -or ($files | grep -i '\.github/workflows/static.yml') } }
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
	@{ name = "vite";			condition = { $packages.Contains("vite") } }
	@{ name = "mongodb";		condition = { $packages.Contains("mongodb") } }
	@{ name = "graphql";		condition = { $packages.Contains("graphql") } }
	@{ name = "postgres";		condition = { $packages.Contains("postgres") -or $packages.Contains("pg") } }
	@{ name = "express";		condition = { $packages.Contains("express") } }
	@{ name = "zod";			condition = { $packages.Contains("zod") } }
	@{ name = "leaflet";		condition = { $frontend_libs.Contains("leaflet") } }
	@{ name = "googleapis";		condition = { $packages.Contains("googleapis") } }
	@{ name = "phantomjs";		condition = { $packages.Contains("phantom") -or $packages.Contains("phantomjs") } }
	@{ name = "docker";			condition = { $packageJSONs | ? { $_.scripts -and $_.scripts | grep docker } } }
	@{ name = "electron";		condition = { $packages.Contains("electron") } }
	@{ name = "mssql";			condition = { $packages.Contains("mssql") -or (gg 'web\.config$' "<connectionStrings>") } }
	@{ name = "aws";			condition = { (gg '\.json$' ami_name) -or (gg 'provider\.tf$' '"aws"') } }
	@{ name = "stl";			condition = { $files | grep '\.stl$' } }
	@{ name = "maps";			condition = { $frontend_libs.Contains("leaflet") } }
	@{ name = "charts";			condition = { $packages.Contains("chart.js") -or $packages.Contains("graph") -or $packages.Contains("vega") } }
	@{ name = "telegraf";		condition = { $packages.Contains("telegraf") } }
	@{ name = "telethon";		condition = { gg '\.py$' telethon } }
	@{ name = "telegram";		condition = { $packages | grep telegram } }
)

$ignore_repositories = @(
	"patch"
)

$topics = @{}

out "{Yellow:Scanning repositories...}"

repo -name $name -quiet {
	out "{Green:$name}"

	if (!(@("git@github.com:$env:GITHUB_USER/", "https://github.com/$env:GITHUB_USER/") | ? { $repository.remote.StartsWith($_) })) {
		out "    {DarkYellow:[skip local]}"
		return
	}

	if ($ignore_repositories | ? { $_ -eq $name }) {
		out "    {DarkYellow:[ignore]}"
		return
	}

	$topics[$name] = @()
	$packages = (packages).name
	if (!$packages) { $packages = @() }
	$files = gg
	$packageJSONs = $files | grep package.json | % { file $_ | ConvertFrom-JSON }
	$frontend_libs_in_html = gg '\.html$' "src=.[^\`"]*?/($($frontend_libs_names -Join "|"))\W" -format lines
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

	$topics[$name] = $topics[$name] | Unique | Sort
	out "    $($topics[$name] -join " ")"
}

out "{Yellow:Updating topics...}"

gitservice -token admin -exec {
	$topics.Keys | Sort | % {
		$name = $_
		out "{Green:$name}"

		$url = "https://api.github.com/repos/$env:GITHUB_USER/$name/topics"
		$existing_topics = (Load-GitService $url -method GET).names
		$actual_topics = $topics[$name]

		$added_topics = $actual_topics | ? { !$existing_topics.Contains($_) }
		$deleted_topics = $existing_topics | ? { !$actual_topics.Contains($_) }

		if ($added_topics -or $deleted_topis) {
			$added_topics | % { out "    {Yellow:+ $_}" }
			$deleted_topics | % { out "    {DarkRed:- $_}" }
			[void](Load-GitService $url -method PUT -data @{ names = $topics[$name] } | ConvertTo-Json)
		} else {
			out "    {DarkYellow:[up-to-date]}"
		}
	}
}
