<#
.SYNOPSIS
    Wait for pipeline to be finished
.PARAMETER repo
	Repository name
.PARAMETER id
    Pipeline id
.PARAMETER quiet
	Whether to not output current repository and branch name
#>

Param (
    [Parameter(Mandatory = $true)][string]$repo,
    [Parameter(Mandatory = $true)][int]$id,
	[switch]$quiet
)

Add-Type -AssemblyName PresentationFramework

# TODO: add github support
gitselect -github { throw "Github is not supported yet for 'jobs' script" }

repo -name $repo -quiet:$quiet -action {
    gitservice -exec {
        while ($true) {
            $url = "https://$env:GITLAB_HOST/api/v4/projects/$($repository.id)/pipelines/$id"
            $pipeline = Load-GitService $url

            if (@("failed", "success", "canceled", "skipped").Contains($pipeline.status)) {
                break;
            }
            out "Waiting pipeline #$id [$($pipeline.status)]..."
            Start-Sleep 5
        }

        $status = switch($pipeline.status) {
            "failed" { "error" }
            "success" { "info" }
            "canceled" { "warning" }
            "skipped" { "warning" }
            default { "error" }
        }

        $color = switch($pipeline.status) {
            "failed" { "DarkRed" }
            "success" { "DarkGreen" }
            "canceled" { "DarkGray" }
            "skipped" { "DarkGray" }
            default { "DarkYellow" }
        }

        $message = $pipeline.status.ToUpper()
        $title = "Pipeline #$id"

        push $message $title -status $status
    }
}
