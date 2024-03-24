<#
.SYNOPSIS
    Get CI status of own github repositories
.PARAMETER name
    Name of the repository. Use "this" for current repositories or "all" for all repositories
#>

Param (
    [string]$name = "this"
)

gitservice -token actions -exec {
    repo $name -quiet {
        try {
            $result = Load-GitService "https://api.github.com/repos/anmiles/$name/actions/runs" -data @{ event = "push"; per_page = 1 }
        } catch {
            $result = @{
                workflow_runs = @()
            }
        }

        $status = "      "

        if ($result.workflow_runs.Count -gt 0) {
            $run = $result.workflow_runs[0]

            switch ($run.status) {
                "completed" {
                    switch ($run.conclusion) {
                        "success" { $status = fmt " PASS " Black Green }
                        "failure" { $status = fmt " FAIL " White Red }
                        "neutral" { $status = fmt " NONE " Black Gray }
                        "cancelled" { $status = fmt " STOP " Black DarkYellow }
                        "skipped" { $status = fmt " SKIP " Black DarkGray }
                        "timed_out" { $status = fmt " TIME " White DarkRed }
                        "action_required" { $status = fmt " WAIT " Black Yellow }
                        default { $status = fmt " ???? " Black Magenta }
                    }
                }
                default {
                    $status = fmt " RUNS " Black Yellow
                }
            }
        }

        out "$status $name"
    }
}
