<#
.SYNOPSIS
    Rebase onto another branch
.PARAMETER new_branch
    Name of base branch to rebase onto
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    rebase master
    # rebase with master
.EXAMPLE
    rebase use
    # rebase branch "use" or next branch that contains "use" (case-insensitive)
#>

Param (
    [Parameter(Mandatory = $true)][string]$new_branch,
    [switch]$quiet
)

$diff1 = "../__rebase1.diff"
$diff2 = "../__rebase2.diff"

repo -name this -new_branch $new_branch -quiet:$quiet -action {
    out "{Yellow:> Rebase onto $new_branch}"

    $commit = ask "Enter previous base commit hash or press ENTER to accept HEAD~1 as answer" -value "HEAD~1"
    git diff $commit > $diff1

    git rebase -X ours $new_branch

    while ($LastExitCode -ne 0) {
        $conflicts_list = $(git diff --check)
        $conflicts = $conflicts_list.Count

        if ($conflicts -gt 0) {
            out "{Red:Conflicts detected:}"
            $conflicts_list
            out "{Red:Resolve conflicts and press ENTER}"
        } else {
            out "{Red:Rebase failed but conflicts are not detected. Please fix this manually and press ENTER}"
        }

        $enter = Read-Host | Out-Null
        git add --all .
        $rebase_head = git show --quiet REBASE_HEAD --format=%h

        if ($LastExitCode -ne 0) {
            $success = $true
        } else {
            git rebase --continue
        }
    }

    git diff $new_branch > $diff2

    out "{Yellow:Detecting changes in diffs...}"
    git diff --text --no-index $diff1 $diff2
    # Remove-Item -Force $diff1
    # Remove-Item -Force $diff2

    out "{Green:Rebase finished}"
}
