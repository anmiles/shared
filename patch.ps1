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

repo -new_branch $base -quiet:$quiet -action {
    $temp_file = "patch.patch"
    $patch_root = Join-Path $env:GIT_ROOT ".patch"
    $directory = Join-Path $patch_root $repo.Replace($env:GIT_ROOT, "")

    $command = switch($R) {$true {"git diff -R"} $false {"git diff"}}

    if (git status --short --untracked-files --renames) {
        if ($file) {
            if (Test-Path $file) {
                git add --all $file
            }
        } else {
            git add --all .
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
        $patch_subdir = Join-Path $directory $to
    } else {
        do {
            $revString = switch($rev){ 0 {""} default {"-$_"} }
            $patch_subdir = Join-Path $directory $branch$revString
            $rev++
        } while (Test-Path $patch_subdir)
    }

    New-Item $patch_subdir -Type Directory -Force | Out-Null

    $patch -split '(?=diff \-\-git)' | ? { $_ } | % {
        $_ -match 'diff \-\-git (a|b)\/(.*) (b|a)\/(.*)' | Out-Null
        $path = $matches[2] -replace '[\/\\]', "_"
        $dest = Join-Path $patch_subdir "$path.patch"
        file $dest $_
        out "{Yellow:$dest}"
    }

    if ($base -eq "HEAD" -and !$keep) {
        discard $file -quiet
    }
}
