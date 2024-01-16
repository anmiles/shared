<#
.DESCRIPTION
    Open coverage report
#>

repo this -quiet {
	& ./coverage/lcov-report/index.html
}
