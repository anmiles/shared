<#
.SYNOPSIS
    Apply tag to repository
.DESCRIPTION
    Create or move tag to repository both locally and remotely
.PARAMETER name
    Apply script only for specified repository name or for current working directory if nothing specified, or apply for all repositories if "all" specified.
    Doesn't work if "root" specified
    Confirms non-default branch
.PARAMETER tag
    Tag names
.PARAMETER root
    Whether to apply tag to the exact path instead of searching repository by its name.
    Doesn't ask about non-default branches
.PARAMETER commit
    Commit to apply the tag (by default last commit in the current branch used, although non-default branch will be confirmed if "name" specified)
.PARAMETER delete
    Whether to just delete tag
.PARAMETER force
    Whether to suppress confirmation about tagging non-default branch
.PARAMETER quiet
    Whether to not output current repository and branch name
.EXAMPLE
    tag release
    # create or move tag "release" for current repository both locally and remotely
.EXAMPLE
    tag repo static
    # create or move tag "static" for repository "repo" both locally and remotely
#>

Param (
    [string]$name,
    [string[]]$tags,
    [string]$root,
    [string]$commit,
    [switch]$delete,
    [switch]$force,
    [switch]$quiet
)

Function Set-Tag {
    Param (
        [string]$root
    )

    git -C $root fetch --tags --force

    if (!$commit) { $commit = "HEAD"}
    $revision = $(git -C $root rev-list -n 1 $commit)

    $affected_delete = $false
    $affected_create = $false
    $deleted_tags = @()

    $tags | % {
        $tag = $_
        $tag_revision = $null
        
        if (git -C $root tag | ? {$_ -eq $tag}) {
            $tag_revision = $(git -C $root rev-list -n 1 $tag)
        }
        
        if (($revision -ne $tag_revision -or $delete) -and $tag_revision) {
            Write-Host "Delete old $tag..." -ForegroundColor Green
            git -C $root tag -d $tag
            $deleted_tags += $tag
            $affected_delete = $true
        }

        if ($revision -ne $tag_revision -and !$delete) {
            Write-Host "Set new $tag..." -ForegroundColor Green
            git -C $root tag $tag $revision
            $affected_create = $true
        }
    }

    if ($affected_delete) {
        if ($deleted_tags.Count -gt 0) {
            Write-Host "Delete tags remotely..." -ForegroundColor Green
            git -C $root push -d origin $deleted_tags
        }
    }

    if ($affected_create) {
        Write-Host "Set tags remotely..." -ForegroundColor Green
        git -C $root push --tags
    }
}

if ($name) {
    repo -name $name -quiet:$quiet -action {
        if (!$commit) {
            if ($branch -ne $default_branch -and !$force -and !(confirm "Current branch is {{$branch}}. Do you prefer to tag it with {{$tags}} rather than {{$default_branch}}")) {
                $commit = $default_branch
            } else {
                $commit = $branch
                save -quiet
            }
        }
        Set-Tag -root $repo
    }
} else {
    Set-Tag -root $root
}
