<#
.SYNOPSIS
    Make branches based on each of N recent commits in current branch and pushes them
.DESCRIPTION
    This will cause N pipelines to be started on each of N recent commits in current branch to be analyzed then
.PARAMETER commits
    Amount of recent commits
.PARAMETER prefix
    Path to where to create temporary file
.PARAMETER head
    Whether to create all branches from the same HEAD of the branch. If $false - create branches from each commit before HEAD
.PARAMETER quiet
    Whether to not output current repository and branch name
#>


Param (
    [string]$commits = 1,
    [string]$prefix = "",
    [switch]$head = $false,
    [switch]$quiet = $true
)

repo -name this -quiet:$quiet -action {
    $from = switch($head){ $true { "{DarkYellow:HEAD}" } $false { "{DarkYellow:$commits} recent commits" } }
    $hash = git rev-parse --short HEAD
    $branch_question = switch($branch){ "HEAD" { $hash } default { $branch } }

    if (!(confirm "Do you want to create {DarkYellow:$commits} pipelines from $from of {DarkYellow:$branch_question}")) {
        exit
    }

    $testDir = Join-Path $repo $prefix
    $testFile = Join-Path $testDir ".pipeline_test_file"

    $branches = @()

    git log --first-parent $branch -n $commits --pretty=format:%h | % {
        $dateTime = [DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss")
        $temp_branch = "test/pipeline-$dateTime-$_"
        $branches += $temp_branch
        out "{Green:Create new branch} {Yellow:$temp_branch}"
        if (!$head) { git checkout $_ }
        branch $temp_branch -force:$quiet
        file $testFile $temp_branch
        out "{Green:Push merge request} {Yellow:$temp_branch}"
        $message = $temp_branch
        if ($env:GIT_DEFAULT_PROJECT) { $message = "$($env:GIT_DEFAULT_PROJECT)-0 $message" }
        save -message $message -nomerge -push -mr -draft -quiet:$quiet
        mr
    }

    if (confirm "Do you want to remove all newly created branches ($branches) both locally and remotely") {
        $target_branch = switch($branch){"HEAD" {$default_branch} default {$branch} }
        git checkout $target_branch

        $branches | % {
            git branch -D $_
            git push origin -d $_
        }
    }
}
