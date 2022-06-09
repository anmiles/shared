<#
.SYNOPSIS
    Make branches based on each of N recent commits in default branch and pushes them
.DESCRIPTION
    This will cause N pipelines to be started on each of N recent commits in default branch to be analyzed then
.PARAMETER commits
    Amount of recent commits
.PARAMETER prefix
    Path to where to create temporary file
.PARAMETER head
    Whether to create all branches from the same HEAD of the default branch. If $false - create branches from each commit before HEAD
.PARAMETER quiet
    Whether to not output current repository and branch name
#>


Param (
    [string]$commits = 1,
    [string]$prefix = "",
    [switch]$head = $false,
    [switch]$quiet = $true
)

out "{Green:Get default branch}"
repo -name this -quiet:$quiet -action {
    $testDir = Join-Path $repo $prefix
    $testFile = Join-Path $testDir ".pipeline_test_file"

    ChangeBranch $default_branch -quiet:$quiet
    $branches = @()

    git log --first-parent $default_branch -n $commits --pretty=format:%h | % {
        $dateTime = [DateTime]::Now.ToString("yyyy-MM-dd-HH-mm-ss")
        $branch = "test/pipeline-$dateTime-$_"
        $branches += $branch
        out "{Green:Create new branch} {Yellow:$branch}"
        if (!$head) { git checkout $_ }
        branch $branch -force:$quiet
        file $testFile $branch
        out "{Green:Push merge request} {Yellow:$branch}"
        $message = $branch
        if ($env:GIT_DEFAULT_PROJECT) { $message = "$($env:GIT_DEFAULT_PROJECT)-0 $branch" }
        save -message $message -nomerge -push -mr -draft -quiet:$quiet
    }

    if (confirm "Do you want to remove all newly created branches ($branches) both locally and remotely") {
        git checkout $default_branch

        $branches | % {
            git branch -D $_
            git push origin -d $_
        }
    }
}
