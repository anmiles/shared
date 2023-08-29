$mock = @{
	<# ConvertVideo #>
	"H:\photos\mp4video.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:01") }
	"H:\photos\avivideo.avi" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:02") }

	<# Rename #>
	"H:\photos\IMG_20121226.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:03") }
	"H:\photos\2012_0003.colorized.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:04") }
	"H:\photos\2012.03_0004.colorized.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:05") }
	"H:\photos\2012.12.26_0002 - edited.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:06") }
	"H:\photos\IMG_2012.12.26_07.41.07_1 (3)+.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:07") }
	"H:\photos\IMG_2012.12.26_07.41.07_1 (3)-.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:07") }
	"H:\photos\VID_2012.12.26_07.41.08++ small.jpeg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:08") }

	<# ValidateExtension #>
	"H:\photos\IMG_20121226.cs" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:09") }

	<# SyncDate #>
	"H:\photos\2012.12.26_07.40.10.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:10"); Approve = $false }
	"H:\photos\2012.12.26_07.40.11.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:11"); Approve = $true }
	"H:\photos\2012.12.26_0012.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:12"); Approve = $false }
	"H:\photos\2012.12.26_0013.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:13"); Approve = $true }
	"H:\photos\IMG_1234.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:14"); Approve = $false }
	"H:\photos\IMG_1235.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:15"); Approve = $true }
	"H:\photos\20121226_074016_portrait.jpg" = @{ Taken = $null; Approve = $false }
	"H:\photos\1356507617000.jpg" = @{ Taken = $null; Approve = $true }
	"H:\photos\M2U01234.mpg" = @{ Taken = $null }
}

$expected_result = @{
	<# ConvertVideo #>
	"H:\photos\mp4video.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:01") }
	"H:\photos\avivideo.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:02") }

	<# Rename #>
	"H:\photos\IMG_20121226.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:03") }
	"H:\photos\2012_0003.colorized.jpg" = @{ Taken = [DateTime]::Parse("2012.01.01 00:00:03") }
	"H:\photos\2012.03_0004.colorized.jpg" = @{ Taken = [DateTime]::Parse("2012.03.01 00:00:04") }
	"H:\photos\2012.12.26_0002 - edited.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 00:00:02") }
	"H:\photos\IMG_2012.12.26_07.41.07_1 (3)+.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:41:07") }
	"H:\photos\2012.12.26_07.41.07.mp4" = @{ Taken = [DateTime]::Parse("2012.12.26 07:41:07") }
	"H:\photos\2012.12.26_07.41.08 small.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:41:08") }

	<# ValidateExtension #>
	"H:\photos\IMG_20121226.cs" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:09") }

	<# SyncDate #>
	"H:\photos\2012.12.26_07.40.10.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:10") }
	"H:\photos\2012.12.26_07.40.11.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:11") }
	"H:\photos\2012.12.26_0012.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 00:00:12") }
	"H:\photos\2012.12.26_07.40.13.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:13") }
	"H:\photos\IMG_1234.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:14") }
	"H:\photos\2012.12.26_07.40.15.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:15") }
	"H:\photos\2012.12.26_07.40.16_portrait.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:16") }
	"H:\photos\2012.12.26_07.40.17.jpg" = @{ Taken = [DateTime]::Parse("2012.12.26 07:40:17") }
	"H:\photos\M2U01234.mp4" = @{ Taken = $null }
}

$actual_result = media -mock $mock -catchErrors:$true

$actual_keys = $actual_result.Keys
$expected_keys = $actual_result.Keys

$actual_result.Keys | % {
	if (!$expected_result[$_]) {
		out "File is not expected {Yellow:$_}" -ForegroundColor Red
	}
}

$expected_result.Keys | % {
	if (!$actual_result[$_]) {
		out "File is missing {Yellow:$_}" -ForegroundColor Red
	} else {
		if ($actual_result[$_].Taken -ne $expected_result[$_].Taken) {
			out "Taken date is wrong for file {Yellow:$_}: {DarkYellow:$($actual_result[$_].Taken.ToString("yyyy.MM.dd_HH.mm.ss"))} (should be {Green:$($expected_result[$_].Taken.ToString("yyyy.MM.dd_HH.mm.ss"))})" -ForegroundColor Red
		}

		if ($actual_result[$_].LastWriteTime -ne $expected_result[$_].Taken) {
			if (!$actual_result[$_].LastWriteTime) {
				out "LastWriteTime is missing for file {Yellow:$_} (should be {Green:$($expected_result[$_].Taken.ToString("yyyy.MM.dd_HH.mm.ss"))})" -ForegroundColor Red
			} else {
				out "LastWriteTime is wrong for file {Yellow:$_}: {DarkYellow:$($actual_result[$_].LastWriteTime.ToString("yyyy.MM.dd_HH.mm.ss"))} (should be {Green:$($expected_result[$_].Taken.ToString("yyyy.MM.dd_HH.mm.ss"))})" -ForegroundColor Red
			}
		}
	}
}

