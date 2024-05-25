<#
.SYNOPSIS
    Execute command in bash console
.PARAMETER command
    Command to execute
.PARAMETER title
    Set custom title for the opened console, if empty - set title equals to cmomand 
.PARAMETER path
    Set working directory for the console
.PARAMETER shell
    Shell to use (if not specified - use Git bash)
.PARAMETER new
    Whether to open new window
.PARAMETER wait
    Whether to wait after executing command passed
.PARAMETER background
    Whether new window should be opened in background
.PARAMETER debug
    Whether to output the command passed
.EXAMPLE
    sh
    # open sh console in the current directory
.EXAMPLE
    sh "npm install"
    # open sh console in the current directory and execure command "npm install"
.EXAMPLE
    sh "eslint ." "lint"
    # open sh console in the current directory, sets title "lint" and execute command "eslint ."
.EXAMPLE
    sh "npm run test" "test" "api"
    # open sh console in the directory "api", sets title "test" and execute command "npm run test"
#>

Param (
    [string]$command,
    [string]$title,
    [string]$path = ".",
    [ValidateSet('', 'git', 'wsl', 'cygwin')][string]$shell,
    [HashTable]$envars = @{},
    [switch]$new,
    [switch]$wait,
    [switch]$background,
    [switch]$debug
)

& $env:MODULES_ROOT\sh.ps1 `
-command $command `
-title $title `
-path $path `
-shell $shell `
-envars $envars `
-new:$new `
-wait:$wait `
-background:$background `
-debug:$debug

exit $LastExitCode
