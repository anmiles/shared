<#
.SYNOPSIS
    Creates a directory with all pending changes and then rollback them
.PARAMETER file
    Which file to make patch from. If not specified - process all files
.PARAMETER to
    Which subdirectory to use for patch files. If not specified - create non-existing directory that named like current branch
.PARAMETER R
    Whether to apply -R to diff
.PARAMETER keep
    Whether to not rollback file/files from which patch was generated
.PARAMETER quiet
    Whether to not output current repository and branch name
#>

Param (
    [string]$base = "HEAD",
    [string]$file,
    [string]$to,
    [switch]$R,
    [switch]$keep,
    [switch]$quiet = $true
)

$temp_file = "patch.patch"
$directory = ".patch"

repo -new_branch $base -quiet:$quiet -action {
    $command = switch($R) {$true {"git diff -R"} $false {"git diff"}}

    if (git status --short --untracked-files --renames) {
        if ($file) {
            if (Test-Path $file) {
                git add --all $file
            }
        } else {
            git add --all *
        }
    }

    $diff = $file
    if ($diff) { $diff = "-- '$diff'" }

    sh "$command $new_branch $diff > $temp_file"

    $patch = file (Join-Path $repo $temp_file)
    Remove-Item $temp_file -Force
    if (!$patch.Trim()) { exit }

    New-Item $directory -Type Directory -Force | Out-Null

    $rev = 0

    if ($to) {
        $patch_subdir = "$directory/$to"
    } else {
        do {
            $revString = switch($rev){ 0 {""} default {"-$_"} }
            $patch_subdir = "$directory/$branch$revString"
            $rev++
        } while (Test-Path $patch_subdir)
    }

    New-Item $patch_subdir -Type Directory -Force | Out-Null

    $patch -split '(?=diff \-\-git)' | ? { $_ } | % {
        $_ -match 'diff \-\-git (a|b)\/(.*) (b|a)\/(.*)' | Out-Null
        $path = $matches[2] -replace '[\/\\]', "_"
        $dest = "$patch_subdir/$path.patch"
        file (Join-Path $repo $dest) $_
        out "{Yellow:$dest}"
    }

    Copy-Item -Recurse -Force $directory/* $env:GIT_ROOT/.patch

    if ($base -eq "HEAD" -and !$keep) {
        discard $file -quiet
    }
}
