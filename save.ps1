<#
.SYNOPSIS
    Save changes to git
.DESCRIPTION
    Add all changes to stage, commit if needed (asks commit message) and push repository in current branch.
    Can skip commits particular repositories by specifiying "skip" or "-" as commit message
    Can revert all changes by specifying "discard" or "!" as commit message
    Can show diff by specifying "diff" or "=" as commit message
    Can show difftool by specifying "difftool" or "==" as commit message
    Can accept different messages for each file by specifying "split" or "+" as commit message
    Can open editor by specifying "edit" or "~" as commit message
    Can show help for all actions above by specifying "help" or "?" as commit message
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified
.PARAMETER message
    Commit message
.PARAMETER merge
    Whether to pull changes from default branch and ask to merge: "none" - never; "mine" - if current branch is mine; "all" - always
.PARAMETER quiet
    Whether to not output current repository and branch name
.PARAMETER empty
    Whether to allow empty commits
.PARAMETER request
    Whether to automatically create pull request on Github / merge request on GitLab
.PARAMETER draft
    Whether request is draft
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
    [ValidateSet('none', 'mine', 'all')][string]$merge = "none",
    [switch]$quiet,
    [switch]$empty,
    [switch]$request,
    [switch]$draft,
    [switch]$push,
    [switch]$squash,
    [switch]$minor
)

$commit_message_example = "ABC-123 Description"
$commit_message_pattern = switch($env:COMMIT_MESSAGE_STRICT) {
    "1" { "^([A-Z]+\-\d+) [^$]" }
    default { "" }
}

$min_length = 3

$username = $(git config --get user.name)

function AddAndCommit($message, $filenames) {
    if ($filenames -is [String]) {
        $filenames = @($filenames)
    }

    $filenames | % {
        git add --all $_
    }

    if ($LastExitCode -ne 0) {
        out "{Red:Unable to add some files, see error details above}"
        exit 1
    }

    if ($unmerged -eq 0) {
        if ($empty) { $allow_empty = "--allow-empty" }

        if ($empty -or $message) {
            $escaped_message = $message -replace '"', "'" -replace '\$', '\$'
            git commit -m $escaped_message $allow_empty
            [Environment]::SetEnvironmentVariable("RECENT_COMMIT", (git rev-parse HEAD), "Process")
        }
    } else {
        if (Test-Path .git/MERGE_HEAD) {
            git commit --file .git/MERGE_MSG | Out-Null
        }
    }
}

Function GetPrevMessages([int]$count) {
    return @(git log --pretty=format:%B) | ? { $_ -and !$_.StartsWith("Merge branch") -and $_ -notmatch '^\d+\.\d+\.\d+$' } | Select -First $count
}

repo -name $name -quiet:$quiet -action {
    $is_my_branch = git for-each-ref --format='%(authorname) %09 %(refname)' | grep "refs/remotes/origin/$branch" | grep $username

    $unpushed, $uncommitted, $unmerged, $problems = batch @(
        "git log --format=format:%H origin/$branch..$branch",
        "git status --short --untracked-files --renames",
        "git diff --name-status --diff-filter=U",
        "git diff --check"
    ) | % { $_.Length }

    if ($problems -gt 0) {
        git diff --check
        if (!(confirm "Do you want to ignore problems")) { exit 1 }
    }

    if ($empty -or $uncommitted -gt 0) {
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor Yellow
        git status --short --untracked-files --renames
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor Yellow

        $flags = @{
            ready = $false
            skip = $false
        }

        if ($unmerged -eq 0) {
            $prev_messages = GetPrevMessages 10
            $flags.ready = $false

            $actions = @(
                [PSCustomObject]@{ message = "help"; alias = "?"; description = "Show actions help"; action = {
                    $actions | Format-Table -Property @( "message", "alias", "description" )
                } }
                [PSCustomObject]@{ message = "diff"; alias = "="; description = "Show diff"; action = {
                    Write-Host "Diff will be paged. Press ENTER to show more or 'q' to stop or 'h' to help" -ForegroundColor Yellow
                    Write-Host "==========================================================================" -ForegroundColor Yellow
                    git diff --color=always HEAD
                    git ls-files --others --exclude-standard | % { git diff --no-index --color=always /dev/null $_ }
                    Write-Host "==========================================================================" -ForegroundColor Yellow
                } }
                [PSCustomObject]@{ message = "diffs"; alias = "=="; description = "Show diff without pager"; action = {
                    Write-Host "==========================================================================" -ForegroundColor Yellow
                    git --no-pager diff --color=always HEAD
                    git ls-files --others --exclude-standard | % { git --no-pager diff --no-index --color=always /dev/null $_ }
                    Write-Host "==========================================================================" -ForegroundColor Yellow
                } }
                [PSCustomObject]@{ message = "difftool"; alias = "$"; description = "Show diff using difftool"; action = {
                    git difftool -d HEAD
                } }
                [PSCustomObject]@{ message = "skip"; alias = "-"; description = "Skip this repository"; action = {
                    $flags.ready = $true
                    $flags.skip = $true
                } }
                [PSCustomObject]@{ message = "discard"; alias = "!"; description = "Discard all changes in repository"; action = {
                    $flags.ready = $true
                    $flags.skip = $true
                    discard
                } }
                [PSCustomObject]@{ message = "edit"; alias = "~"; description = "Open repository in the editor"; action = {
                    edit
                } }
                [PSCustomObject]@{ message = "select"; alias = "#"; description = "Select from previous commit messages"; action = {
                    $i = 0
                    $prev_messages | % {
                        out "{Green:$i} $_"
                        $i++
                    }
                } }
                [PSCustomObject]@{ message = "split"; alias = "+"; description = "Split changes between commits"; action = {
                    $flags.ready = $true
                    $splitfile = Join-Path $env:TEMP "COMMIT_SPLIT"
                    $lines = git status --short --untracked-files --renames
                    $maxLength = ($lines | % { $_.Length } | Measure-Object -Maximum).Maximum
                    $lines | % {
                        $space = (" " * ($maxLength - $_.Length))
                        ($_ -replace "^(\s*\S+\s+)", ('$1' + $space)) + " "
                    } > $splitfile
                    iex "cmd /c $(git config core.editor) $splitfile"
                    $files = @{}

                    Get-Content $splitfile | % {
                        ($none, $status, $message) = $_ -split "^(.{$maxLength}) "
                        $filename = $status -replace "^(\s*\S+\s+)", ""

                        if (!$files[$message]) {
                            $files[$message] = @()
                        }

                        $files[$message] += $filename
                        $unpushed++
                    }

                    $files.Keys | % {
                        AddAndCommit $_ $files[$_]
                    }

                    Remove-Item -Force $splitfile
                } }
            )

            while (!$flags.ready) {
                if (!$message) { $message = ask -value $prev_messages[0] -old "Prev commit message" -new "Next commit message" -append }

                $action = $actions | ? { $_.message -eq $message -or $_.alias -eq $message}

                if ($action) {
                    out "{DarkYellow:$($action.description)}"
                    $action.action.Invoke()
                    $message = $null
                    continue
                }

                if ($message -match '^\d+$') {
                    $prev_message = $prev_messages[$message]

                    if (!$prev_message) {
                        Write-Host "Previous message #$message not found" -ForegroundColor Red
                        $message = $null
                    } else {
                        $message = $prev_message
                        $flags.ready = $true
                    }

                    continue
                }

                if ($message.Length -lt $min_length) {
                    Write-Host "Commit message should be at least $min_length symbols long" -ForegroundColor Red
                    $message = $null
                    continue
                }

                if ((Test-Path -Type Container $repo/.git) -and $commit_message_pattern -and $message -notmatch $commit_message_pattern) {
                    Write-Host "Commit message should have format '$commit_message_example'" -ForegroundColor Red
                    $message = $null
                    continue
                }

                $flags.ready = $true
            }
        }

        if (!$flags.skip) {
            AddAndCommit $message .
            $unpushed += (git log --format=format:%H origin/$branch..$branch).Length
        }
    }

    if ($request -or ($unpushed -and ($push -or $is_my_branch))) {
        if ($squash -and $unpushed -gt 1) {
            $messages = git log --format=format:%s --reverse origin/$branch..$branch
            $aggregated_message = SquashMessages $messages
            git reset --quiet --soft HEAD~$unpushed
            if ($empty) { $allow_empty = "--allow-empty" }
            $escaped_message = $aggregated_message -replace '"', "'" -replace '\$', '\$'
            git commit -m $escaped_message $allow_empty
        }

        if ($branch -ne $default_branch -and $unmerged -eq 0 -and (($merge -eq "all") -or ($merge -eq "mine" -and $is_my_branch)) -and (confirm "Do you want to merge {{$default_branch}} into {{$branch}}")) {
            ChangeBranch $default_branch
            git pull
            ChangeBranch $branch
            git merge $default_branch
        }

        $arguments = @("push")

        # TODO: add github support below

        if ($minor) {
            gitselect -github { throw "Github is not supported yet for creating pull requests" }
            $arguments += "-o ci.skip"
        }
        if ($request) {
            gitselect -github { throw "Github is not supported yet for creating pull requests" }
            $arguments += "-o merge_request.create"

            if (!$message) {
                $prev_message = GetPrevMessages 1
                $message = ask -value $prev_message -old "Prev commit message" -new "Next commit message" -append
            }

            $request_name = [Regex]::Replace($branch, '(^.*?\d+)(.*)$', { param($match) $match.Groups[1].Value + $match.Groups[2].Value.Replace("-", " ") }, 'IgnoreCase')
            # $request_name = ask -new "Request name"

            if ($draft) {
                $arguments += "-o merge_request.title=`"Draft: $request_name`""
            } else {
                $arguments += "-o merge_request.title=`"$request_name`""

                if ((Test-Path -Type Container $repo/.git) -and $commit_message_pattern) {
                    $issue = [Regex]::Matches($message, $commit_message_pattern).Groups[1].Value
                }
            }

            if (!$unpushed) {
                git commit -m $escaped_message --allow-empty
            }
        }

        Write-Host "git $arguments"
        iex "git $arguments" | Tee-Object -Variable push_answer
        [Environment]::SetEnvironmentVariable("RECENT_PUSH", $push_answer, "Process")
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
