<#
.SYNOPSIS
    Quiz for multiplication table
.DESCRIPTION
    Output questions for multiplication and then draw a kitty
.PARAMETER from
    Start number
.PARAMETER to
    End number
.EXAMPLE
    multable 5 7
    # generate quiz for multiplication table from 5 till 7
#>

Param (
    [Parameter(Mandatory = $true)][int]$from,
    [Parameter(Mandatory = $true)][int]$to
)

Import-Module $env:MODULES_ROOT\progress.ps1 -Force

$x1 = 2;
$x2 = 9;
$y1 = $from;
$y2 = $to

$combinations = @()

for ($x = $x1; $x -le $x2; $x++) {
    for ($y = $y1; $y -le $y2; $y++) {
        $combinations += "$x x $y"
        $combinations += "$y x $x"
    }
}

$quiz = $combinations | Sort-Object | Get-Unique | Get-Random -Count $combinations.Length

cls
[console]::CursorVisible = $false

$progress = Start-Progress -count $quiz.Length -length ($quiz.Length + 7)

$quiz | % {
    [void](Read-Host)
	[console]::SetCursorPosition([console]::CursorLeft, [console]::CursorTop - 1)
    $progress.Tick(1, " " + $_ + " ")
}

$progress.Set($quiz.Length, "")

$cat_width = 9
$cat_height = 5
$width = [console]::WindowWidth
$height = [console]::WindowHeight

$left_offset = [Math]::Floor(($width - $cat_width) / 2)
$left = (1..$left_offset) | % {""}

$top_offset = [Math]::Floor(($height - $cat_height) / 2)
$top = (1..$top_offset) | % {""}

$top
out "$left  /\_/\" Red
out "$left ( o.o )" DarkYellow
out "$left  > v <" Yellow
out "$left /  |  \" Green
out "$left(_/   \_)" Blue

Read-Host
[console]::CursorVisible = $true
