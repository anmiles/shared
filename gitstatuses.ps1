<#
.DESCRIPTION
	Generates a git repo with a files of a different statuses. Useful for debugging scripts that use git commands
.PARAMETER name
	Name of the new git repo
.PARAMETER root
	Path to where git repo will be created (default = current directory)
#>

Param (
	[string]$name = [Guid]::NewGuid().ToString(),
	[string]$root = "."
)

$path = "$root/$name"
if (Test-Path $path) {
	if (!(confirm "Do you want to re-create directory $path")) {
		exit 1
	}
	Remove-Item $path -Force -Recurse
}

mkdir $path | Out-Null

out "{Green:> init repository}"
git -C $path init | Out-Null
git -C $path checkout -b mine | Out-Null

out "{Green:> prepare ignored files}"

file "$path/.gitignore" "ignored.txt"
file "$path/ignored.txt" "ignored"

out "{Green:> add files to mine branch}"

file "$prepare/unchanged.txt" "unchanged"
file "$path/changed.txt" "change"
file "$path/changed_staged.txt" "change_staged"
file "$path/rename.txt" "renamed"
file "$path/rename_staged.txt" "renamed_staged"
file "$path/removed.txt" "removed"
file "$path/removed_staged.txt" "removed_staged"

file "$path/merged_modified_both.txt" "merged_modify_both"
file "$path/merged_conflicted_both.txt" "merged_conflict_both"
file "$path/merged_deleted_mine.txt" "merged_deleted_mine"
file "$path/merged_deleted_theirs.txt" "merged_deleted_theirs"
file "$path/merged_deleted_both.txt" "merged_deleted_both"

git -C $path add --all . | Out-Null
git -C $path commit -m "add files to mine branch" | Out-Null

out "{Green:> change files in theirs branch}"

git -C $path checkout -b theirs | Out-Null
file "$path/merged_added_theirs.txt" "merged_added_theirs"
file "$path/merged_added_both.txt" "merged_added_both"
file "$path/merged_modified_both.txt" "merged_modified_both"
file "$path/merged_conflicted_both.txt" "merged_conflicted1_both"
Remove-Item "$path/merged_deleted_theirs.txt"
Remove-Item "$path/merged_deleted_both.txt"
git -C $path add --all . | Out-Null
git -C $path commit -m "change files in theirs branch" | Out-Null

out "{Green:> prepare staged files}"

git -C $path checkout mine | Out-Null

file "$path/added_staged.txt" "added_staged"
file "$path/changed_staged.txt" "changed_staged"
Move-Item "$path/rename_staged.txt" "$path/renamed_staged.txt"
Remove-Item "$path/removed_staged.txt"

git -C $path add --all . | Out-Null

out "{Green:> prepare unstaged files}"

file "$path/added.txt" "added"
file "$path/changed.txt" "changed"
Move-Item "$path/rename.txt" "$path/renamed.txt"
Remove-Item "$path/removed.txt"

out "{Green:> change files in main branch}"

file "$path/merged_added_mine.txt" "merged_added_mine"
file "$path/merged_added_both.txt" "merged_added_both"
file "$path/merged_modified_both.txt" "merged_modified_both"
file "$path/merged_conflicted_both.txt" "merged_conflicted2_both"
Remove-Item "$path/merged_deleted_mine.txt"
Remove-Item "$path/merged_deleted_both.txt"

git -C $path merge theirs | Out-Null

out "{Green:> done} {Yellow:$(Resolve-Path $path)}"
git -C $path status --short --untracked-files --renames


