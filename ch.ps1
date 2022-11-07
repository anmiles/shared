<#
.SYNOPSIS
    Change branch
.DESCRIPTION
    Checkout another branch given loaded branches of current repository
.PARAMETER new_branch
    Name of new branch or just part of it, if this parameter is empty or many branches matches - all of them will be shown to choose one
.PARAMETER next
    Whether to switch onto the next branch in the list of branches
.PARAMETER prev
    Whether to switch onto the previous branch in the list of branches
.EXAMPLE
    ch
    # checkout branch of the current repository or show all of them if many
.EXAMPLE
    ch master
    # checkout branch "master" of the current repository
.EXAMPLE
    ch use
    # checkout branch "use" or show all branches that contains "use" if many (case-insensitive)
.EXAMPLE
    ch -next
    # checkout next branch in the list of branches
.EXAMPLE
    ch -prev
    # checkout previous branch in the list of branches
#>

Param (
    $new_branch = "",
    [switch]$next,
    [switch]$prev
)

repo -name this -new_branch $new_branch -quiet:$quiet -action {
    function PrintBranches {
        out "{Yellow:Branches:}"

        $new_branches | % {$i = 1} {
            PrintBranch "$i) $_" -next
            $i ++
        }
    }

    function CheckInput($selected) {
        $index = 1
        if ([int]::TryParse($selected, [ref]$index)) {
            if ($index -ge 1) {
                $index = ($index - 1) % $new_branches.Length
                return $new_branches[$index]
            }
        }

        if ($new_branches.IndexOf($selected) -ne -1) {
            return $selected
        }

        $filtered_branches = $new_branch | ? { $_.ToLower().Contains($selected.ToLower()) }

        if ($filtered_branches.Length -eq 0) { return $new_branches }
        if ($filtered_branches.Length -eq 1) { return $filtered_branches[0] }
        return $filtered_branches
    }

    if ($new_branches.Count -eq 1) {
        $new_branch = $new_branches[0]
        $selected = ask -old "This branch" -new "Next branch" -value $branch -new_value $new_branch
    } else {
        $index = $new_branches.IndexOf($branch)

        if ($prev -or $next) {
            if ($prev) { $index -- }
            if ($next) { $index ++ }
            if ($index -lt 0) { $index = $new_branches.Count - 1 }
            if ($index -gt $new_branches.Count - 1) { $index = 0 }
            $new_branch = $new_branches[$index]
            $selected = ask -old "This branch" -new "Next branch" -value $branch -new_value $new_branch
        } else {
            do {
                PrintBranches
                $selected = ask -old "This branch" -new "Next branch" -value $branch -default_new_value ($index + 2)
                $new_branch = CheckInput $selected
            } while ($new_branch -is [string] -and !$new_branch -or !($new_branch -is [string]) -and $new_branch.Length -ne 1)

            [console]::SetCursorPosition([console]::CursorLeft, [console]::CursorTop - 1)
            Write-Host "Next branch: $new_branch" -ForegroundColor Green
        }

        ChangeBranch $new_branch -quiet
    }

    ChangeBranch $new_branch -quiet

    if ($LastExitCode -ne 0) {
        out "{Red:Could not switch to $new_branch}"
        exit 1
    }
}
