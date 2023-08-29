<#
.SYNOPSIS
    Show progress in manual removing files from the specified directory
.PARAMETER path
    Path to directory
#>

Param (
    [Parameter(Mandatory = $true)][string]$path
)

Function GetFilesCount($path) {
	return (Get-ChildItem $path -File -Recurse).Length
}

$files_initial = GetFilesCount $path

Function UpdateStat {
	$files_remain = GetFilesCount $path
	$files_done = $files_initial - $files_remain
	$progress = $files_done / $files_initial
	$percent = [string]([Math]::Floor($progress * 10000) / 100)
	$text = "$percent%"

	$width = [console]::WindowWidth
	$height = [console]::WindowHeight
	$center_width = $text.Length + 4
	$center_height = 3
	$size = $width * $height - $center_width * $center_height
	$current = [int][Math]::Floor($size * $progress)


	$x0 = [string][char]0x2591
	$x1 = [string][char]0x2588
	$i = 0
	$output = ""

	$center_row0 = [Math]::Floor(($height - $center_height) / 2)
	$center_row1 = $center_row0 + $center_height
	$center_col0 = [Math]::Floor(($width - $center_width) / 2)
	$center_col1 = $center_col0 + $center_width

	for ($y = 0; $y -lt $height; $y ++) {
		for ($x = 0; $x -lt $width; $x ++) {
			$dx = $x - $center_col0
			$dy = $y - $center_row0
			if ($x -gt $center_col0 -and $x -le $center_col1 -and $y -gt $center_row0 -and $y -le $center_row1) {
				if ($dy -eq 2 -and $dx -gt 2 -and $dx -le $center_width - 2) {
					$sym = $dx - 3
					$output += $text[$dx - 3]
				} else {
					$output += " "
				}
			} else {
				$i ++
				$symbol = ""
				if ($i -le $size) { $symbol = $x0 }
				if ($i -le $current) { $symbol = $x1 }
				$output += $symbol
			}
		}
	}

	[console]::SetCursorPosition(0, 0)
	[console]::Write($output)
}

UpdateStat

try
{
	$watcher = New-Object -TypeName IO.FileSystemWatcher -ArgumentList $path, "*" -Property @{
		IncludeSubdirectories = $true
		NotifyFilter = @([IO.NotifyFilters]::FileName, [IO.NotifyFilters]::DirectoryName)
	}

	do
	{
		$result = $watcher.WaitForChanged(@([System.IO.WatcherChangeTypes]::All), 1000)
		if ($result.TimedOut) { continue }
		UpdateStat
	} while ($true)
}
finally
{
	$watcher.Dispose()
}
