<#
.SYNOPSIS
    Executes command with arguments, waits for exit and returns output, error and exit code
.PARAMETER command
    Command
.PARAMETER arguments
    Arguments
#>

Param (
    [string]$command,
    [Parameter(ValueFromRemainingArguments = $true)][string[]]$arguments = @()
)

$process = New-Object -TypeName System.Diagnostics.Process
$process.StartInfo.WorkingDirectory = (Get-Location).Path
$process.StartInfo.FileName = $command
$process.StartInfo.Arguments = $arguments
$process.StartInfo.UseShellExecute = $false
$process.StartInfo.RedirectStandardOutput = $true
$process.StartInfo.RedirectStandardError = $true
$null = $process.Start()
$process.WaitForExit()
$output = $process.StandardOutput.ReadToEnd().TrimEnd("`r`n")
$err = $process.StandardError.ReadToEnd().TrimEnd("`r`n")
$exitCode = $process.ExitCode

@{
    output = $output
    err = $err
    exitCode = $exitCode
}

