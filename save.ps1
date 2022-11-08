<#
.SYNOPSIS
    Save changes to git
.DESCRIPTION
    Add all changes to stage, commit if needed (asks commit message) and push repository in current branch.
    Can skip commits particular repositories by specifiying "skip" or "-" as commit message
    Can show diff by specifying "diff" or "?" as commit message
    Can show difftool by specifying "difftool" or "??" as commit message
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Commit message
.PARAMETER quiet
    Whether to not output current repository and branch name
.PARAMETER nomerge
    Whether to suppress asking for merge with default branch
.PARAMETER empty
    Whether to allow empty commits
.PARAMETER mr
    Whether to automatically create merge request on GitLab
.PARAMETER draft
    Whether merge request is draft
.PARAMETER push
    Whether to push. Forcibly set to "true" if name is "all"
.PARAMETER squash
    Whether to squash all unpushed commits into one
.PARAMETER minor
    Whether to skip CI pipeline
.EXAMPLE
    save 
    # add and commit the current directory
.EXAMPLE
    save this 
    # add and commit the current directory
.EXAMPLE
    save lib "Autocommit" 
    # add and commit the repository "lib" and preset commit message
.EXAMPLE
    save all -push
    # add, commit and push each repository that can be found in $roots
#>

Param (
    [string]$name,
    [string]$message,
    [switch]$quiet,
    [switch]$empty,
    [switch]$nomerge = $true,
    [switch]$mr,
    [switch]$draft,
    [switch]$push,
    [switch]$squash,
    [switch]$minor
)

if ($name -eq "all") { $push = $true }

$commit_message_example = "ABC-123 Description"
$commit_message_pattern = switch($env:COMMIT_MESSAGE_STRICT) {
    "1" { "^([A-Z]+\-\d+) [^$]" }
    default { "" }
}

repo -name $name -quiet:$quiet -action {
    function GetPrevMessage {
        $offset = 0
        $prev_message = ""

        while (!$prev_message -or $prev_message.StartsWith("Merge branch") -or $prev_message -match '^\d+\.\d+\.\d+$') {
            $prev_message = $(git log --first-parent $branch --skip $offset -n 1 --pretty=format:%B) -split "`n" | Select -First 1
            $offset = $offset + 1
            if ($prev_message.StartsWith("Merge branch") -and $prev_message.Contains(" into '$default_branch'")) {
                $prev_message = ""
                break
            }
        }

        return $prev_message
    }

    $commands = @(
        "git log --format=format:%H origin/$branch..$branch",
        "git status --short --untracked-files --renames",
        "git diff --name-status --diff-filter=U",
        "git diff --check"
    )

    $command = ($commands | % { "$_ | wc -l" }) -join " && "
    $unpushed, $uncommitted, $unmerged, $problems = sh $command

    if ($problems -gt 0) {
        git diff --check
        if (!(confirm "Do you want to ignore problems")) { exit 1 }
    }

    if ($empty -or $uncommitted -gt 0) {
        Write-Host "-------------------------------------------------------------------" -ForegroundColor Yellow
        git status --short --untracked-files --renames
        Write-Host "-------------------------------------------------------------------" -ForegroundColor Yellow

        $skip = $false

        if ($unmerged -eq 0) {
            $prev_message = GetPrevMessage
            $ready = $false

            while (!$ready) {
                if (!$message) { $message = ask -value $prev_message -old "Prev commit message" -new "Next commit message" -append }

                if ($message -eq "diff" -or $message -eq "?") {
                    Write-Host "Diff will be paginated. Press ENTER to show more and 'q' in the end" -ForegroundColor Yellow
                    Write-Host "-------------------------------------------------------------------" -ForegroundColor Yellow
                    git diff HEAD
                    Write-Host "-------------------------------------------------------------------" -ForegroundColor Yellow
                    $message = $null
                    continue
                }

                if ($message -eq "difftool" -or $message -eq "??") {
                    git difftool -d HEAD
                    $message = $null
                    continue
                }

                if ($message -eq "skip" -or $message -eq "-") {
                    $ready = $true
                    $skip = $true
                    $message = $null
                    continue
                }

                if ($message -eq "discard" -or $message -eq "!") {
                    $ready = $true
                    $skip = $true
                    $message = $null
                    discard
                    continue
                }

                if ((Test-Path -Type Container $repo/.git) -and $commit_message_pattern -and $message -notmatch $commit_message_pattern) {
                    Write-Host "Commit message should have format '$commit_message_example'" -ForegroundColor Red
                    $message = $null
                    continue
                }

                $ready = $true
            }
        }

        if (!$skip) {
            git add --all .

            if ($LastExitCode -ne 0) {
                out "{Red:Unable to add some files, see error details above}"
                exit 1
            }

            if ($unmerged -eq 0) {
                if ($empty) { $allow_empty = "--allow-empty" }
                git commit -m "$($message -replace '"', "'")" $allow_empty
                $unpushed ++
            } else {
                if (Test-Path .git/MERGE_HEAD) {
                    git commit --file .git/MERGE_MSG
                    $unpushed ++
                }
            }
        }
    }

    if ($mr -or ($unpushed -and $push)) {
        if ($squash -and $unpushed -gt 1) {
            $messages = git log --format=format:%s --reverse origin/$branch..$branch
            $aggregated_message = SquashMessages $messages
            git reset --quiet --soft HEAD~$unpushed
            if ($empty) { $allow_empty = "--allow-empty" }
            git commit -m ($aggregated_message -replace '"', "'") $allow_empty
        }

        if ($branch -ne $default_branch -and $unmerged -eq 0 -and !$nomerge -and (confirm "Do you want to merge {{$default_branch}} into {{$branch}}")) {
            ChangeBranch $default_branch
            git pull
            ChangeBranch $branch
            git merge $default_branch
        }

        $arguments = @("push")

        if ($minor) {
            $arguments += "-o ci.skip"
        }

        if ($mr) {
            $arguments += "-o merge_request.create"

            if (!$message) {
                $prev_message = GetPrevMessage
                $message = ask -value $prev_message -old "Prev commit message" -new "Next commit message" -append
            }

            if ($draft) {
                $arguments += "-o merge_request.title=`"Draft: $message`""
                $arguments += "-o merge_request.label=`"do not merge`""
            } else {
                $arguments += "-o merge_request.title=`"$message`""

                if ((Test-Path -Type Container $repo/.git) -and $commit_message_pattern) {
                    $issue = [Regex]::Matches($message, $commit_message_pattern).Groups[1].Value
                    $arguments += "-o merge_request.description=`"\[$issue\]`""
                }
            }

            if (!$unpushed) {
                git commit -m $message --allow-empty
            }
        }

        Write-Host "git $arguments"
        iex "git $arguments"
    }
}

Function SquashMessages($messages) {
    $map = @{}
    $keys = @()

    $messages | % {
        $parts = $_ -split '\s\*\s+'
        $key = $parts[0]

        if (!$map[$key]) {
            $map[$key] = @()
            $keys += $key
        }

        $map[$key] += $parts[1..($parts.Length-1)]
    }

    return ($keys | % {
        ((@($_) + $map[$_]) | Select -Unique) -join " * "
    }) -join "`n"
}
