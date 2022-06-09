<#
.SYNOPSIS
    Compares local diff and remote diff between the same branches
.PARAMETER new_branch
    Name of branch to diff with. If not specified, diff with default branch
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    diffs 1234
    # Perform compare between (current_branch <-> feature/some-1234) and (origin/current_branch <-> origin/feature/some-1234)
.EXAMPLE
    diffs 1234 5678
    # Perform compare between (current_branch <-> feature/some-1234) and (origin/current_branch <-> origin/feature/another-5678)
.EXAMPLE
    diffs
    # Perform compare between (current_branch <-> master) and (origin/current_branch <-> origin/master)
#>

Param (
    [string]$local_branch,
    [string]$remote_branch,
    [switch]$quiet
)

repo -name this -quiet:$quiet -action {
    Function ParseBranch($branch) {
        if ($branch.Contains("/")) {
            return $branch
        }

        $new_branch = $branch
        $branch = GetNewBranch -branch $default_branch -quiet:$true

        if ($branch -is [System.Array]) {
            if ($branch.Contains($default_branch)) {
                return $default_branch
            } else {
                return $branch[0]
            }
        }

        return $branch
    }

    $local_branch = ParseBranch $local_branch

    if ($remote_branch) {
        $remote_branch = ParseBranch $remote_branch
    } else {
        $remote_branch = $local_branch
    }

    $diff_local = "__local.diff"
    $diff_remote = "__remote.diff"

    git diff $branch $local_branch > $diff_local
    git diff origin/$branch origin/$remote_branch > $diff_remote
    git difftool --text --no-index $diff_local $diff_remote
}
