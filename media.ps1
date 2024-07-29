Param (
	[string]$path,
	[HashTable]$mock,
    [ValidateSet('', 'convert', 'rename', 'resize', 'date')][string[]]$only,
    [ValidateSet('', 'convert', 'rename', 'resize', 'date')][string[]]$skip,
	[switch]$catchErrors = $true
)

$requiredActions = @("validate")

$defaultPhotoExtension = ".jpg"
$defaultVideoExtension = ".mp4"
$mediaExtensions = @($defaultPhotoExtension, $defaultVideoExtension)
$allVideoExtensions = @(".3gp", ".avi", ".flv", ".m2t", ".m2ts", ".m4v", ".mkv", ".mov", ".mp4", ".mpeg", ".mpg", ".mts", ".ogv", ".qt", ".swf", ".ts", ".vob", ".webm", ".wmv")
$ignoreExtensions = @(".txt", ".ps1", ".psd", ".wav")

Import-Module $env:MODULES_ROOT\media.ps1 -Force

if ($path) { Push-Location $path }

<# UTIL FUNCTIONS #>

Function GetFiles([string[]]$filter) {
	if ($mock) {
		$filtered = @()
		$patterns = $filter | % { ConvertFilterToRegex($_.Trim()) }

		$mock.Keys | % {
			$key = $_
			$isMatch = ($patterns | ? { $key -match $_ }).Length -gt 0

			if ($isMatch) {
				ParseMock($key)
				$filtered += $mock[$key]
			}
		}

		return $filtered
	} else {
		return Get-ChildItem -File -Recurse $filter
	}
}

Function GetFile($filename) {
	if ($mock) {
		return $mock[$filename]
	} else {
		return Get-Item -LiteralPath $filename
	}
}

Function ParseMock($key) {
	$mock[$key].Parsed = $true
	$mock[$key].FullName = $key
	$mock[$key].Name = Split-Path $key -Leaf
	$mock[$key].Extension = [System.IO.Path]::GetExtension($key)
}

Function ConvertFilterToRegex($filter) {
	$asteriskParts = $filter -split '\*'

	$asteriskParts = $asteriskParts | % {
		$questionParts = $_ -split '\?'

		$questionParts = $questionParts | % {
			return [Regex]::Escape($_)
		}

		return $questionParts -join "."
	}

	return $asteriskParts -join '.*'
}

Function FileExists($filename) {
	if ($mock) {
		return $mock.Keys | ? { $_ -eq $filename }
	} else {
		return Test-Path -LiteralPath $filename
	}
}

Function CopyFile($filename, $filename_new) {
	if ($mock) {
		$mock[$filename_new] = $mock[$filename]
		ParseMock($filename_new)
	} else {
		Copy-Item -LiteralPath $filename $filename_new
	}
}

Function RenameFile($filename, $filename_new) {
	if ($filename -ne $filename_new -and (FileExists $filename_new)) {
		throw "Cannot rename {Yellow:$filename} => {Green:$filename_new} (file already exists)"
	}

	if ($mock) {
		CopyFile $filename $filename_new
		$mock.Remove($filename)
	} else {
		Rename-Item -LiteralPath $filename $filename_new
	}
}

Function RemoveFile($filename) {
	if ($mock) {
		$mock.Remove($filename)
	} else {
		Remove-Item -LiteralPath $filename -Force
	}
}

Function CutVideo($filename, $prefix) {
	if ($mock) {
		$filename_converted = GetConvertedFilename $filename $prefix
		CopyFile $filename $filename_converted
	} else {
		cut $filename -prefix $prefix -silent
	}
}

Function IsX264($filename) {
	if ($mock) {
		return $false
	}

	if ([System.IO.Path]::GetExtension($filename) -ne $defaultVideoExtension) {
		return $false
	}

	$library = mediainfo $filename | grep "Writing library"
	return ($library -match "x264")
}

Function GetConvertedFilename($filename, $prefix) {
	$parent = Split-Path $filename -Parent
	$name = Split-Path $filename -Leaf
	$ext = [System.IO.Path]::GetExtension($name)
	$name = $name -replace $ext, $defaultVideoExtension
	$filename_converted = Join-Path $parent ($prefix + $name)
	return $filename_converted
}

Function Mogrify($filename) {
	if ($mock) {
		$filename_clean = $filename.Replace($file.Extension, $file.Extension + "~")
		$mock[$filename_clean] = $mock[$filename]
	} else {
		& magick mogrify -resize 3000x3000> $filename
	}
}

Function TooLarge($filename) {
	if ($mock) {
		return $true
	}

	if ($filename.EndsWith("big.jpg")) {
		return $false
	}

	$dimensions = (magick identify -format "%wx%h" $filename) -split "x"
	return ($dimensions | ? { [float]$_ -gt 3000 }).Length -gt 0
}

Function GetTaken($filename) {
	if ($mock) {
		return $mock[$filename].Taken
	}

	$exif = exiftool -DateTimeOriginal $filename
	$value = $exif -replace 'Date/Time Original\s*:\s*', ''

	if (!$value) { return $null }

	$p = $value -split '\D+' | % { [int]$_ }
	return [DateTime]::new($p[0], $p[1], $p[2], $p[3], $p[4], $p[5])
}

Function SetTaken($filename, [DateTime]$date) {
	if ($mock) {
		$mock[$filename].Taken = $date
		return
	}

	$dateString = $date.ToString("yyyy:MM:dd HH:mm:ss")
	$result = exiftool -DateTimeOriginal="$dateString" -overwrite_original $filename
	return $result
}

Function DeleteTaken($filename) {
	if ($mock) {
		$mock[$filename].Taken = $null
		return
	}

	$result = exiftool -DateTimeOriginal= -overwrite_original $filename

	if (($result -join " ").Contains("1 image files unchanged")) {
		$result = exiftool -all= -overwrite_original $filename
	}

	return $result
}

Function ConfirmRename($file, $date, $taken, $diff) {
	$filename = $file.FullName
	$answer = $null

	if ($mock) {
		$answer = !!$mock[$filename].Approve
	}

	$diffSuffix = ""

	if ($diff) {
		$sign = ""

		if ($diff.TotalSeconds -gt 0) {
			$sign = "+"
		}

		if ([Math]::Abs($diff.TotalSeconds) -le 2) {
			$answer = $true
		}

		$diffSuffix = " ({Cyan:$sign$($diff.TotalSeconds)} seconds)"
	}

	$question = "Do you want to rename {DarkYellow:$filename} using taken date {Green:$($taken.ToString("yyyy.MM.dd_HH.mm.ss"))}$diffSuffix"
	$approve = confirm $question -result $answer

	if ($approve) {
		$filename_new = $filename.Replace($file.Name, $taken.ToString("yyyy.MM.dd_HH.mm.ss") + $file.Extension)
		out "Rename {Yellow:$filename} => {Green:$filename_new}"
		RenameFile $filename $filename_new
		$filename = $filename_new
		$file = GetFile $filename
		$date = $taken
	} else {
		if ($date) {
			out "Set original date to {Green:$($date.ToString("yyyy.MM.dd_HH.mm.ss"))} for {Yellow:$filename}"
			SetTaken $filename $date
		} else {
			$date = $taken
		}
	}

	return @{
		File = $file
		Date = $date
	}
}

Function GetExceptionMessage($err) {
	$ex = $err.Exception
	while ($ex.InnerException) {
		$ex = $ex.InnerException
	}

	return $ex.Message
}

<# PROCESS FUNCTIONS #>

Function ConvertVideo($file) {
	$filename = $file.FullName
	$date = $file.LastWriteTime
	$prefix = "converted-"

	if (IsX264 $filename) { return }

	out "Convert video {Yellow:$filename}"
	CutVideo $filename -prefix $prefix

	RemoveFile $filename
	$filename_converted = GetConvertedFilename $filename $prefix
	$filename_new = $filename_converted.Replace("converted-", "")
	RenameFile $filename_converted $filename_new
	(GetFile $filename_new).LastWriteTime = $date
}

Function Rename($file) {
	$filename = $file.FullName

	$result = NormalizeMediaFilename $file.Name

	if ($file.Name -cne $result.Name) {
		$filename_new = $filename.Replace($file.Name, $result.Name)
		out "Rename {Yellow:$filename} => {Green:$filename_new}"
		RenameFile $filename $filename_new
	}
}

Function ValidateExtension($file) {
	$filename = $file.FullName

	if (!$mediaExtensions.Contains($file.Extension)) {
		throw "Non-supported extension {DarkYellow:$($file.Extension)} for {Yellow:$filename}"
	}
}

Function ResizePhoto($file) {
	$filename = $file.FullName
	$date = $file.LastWriteTime
	$ext = [System.IO.Path]::GetExtension($filename)

	if ($ext -ne $defaultPhotoExtension) { return }
	if (!(TooLarge $filename)) { return }

	out "Resize photo {Yellow:$filename}"
	Mogrify $filename

	(GetFile $filename).LastWriteTime = $date

	$filename_clean = $filename.Replace($file.Extension, $file.Extension + "~")

	if (FileExists $filename_clean) {
		RemoveFile $filename_clean
	}
}

Function SyncDate($file) {
	$filename = $file.FullName
	$result = NormalizeMediaFilename $file.Name
	$taken = GetTaken $filename
	$date = $taken

	if ($taken) {
		if ($result.Date) {
			$diff = $result.Date - $taken

			if ($diff.TotalSeconds) {
				$result = ConfirmRename -file $file -date $result.Date -taken $taken -diff $diff
				$file = $result.File
				$date = $result.Date
			}
		} else {
			$result = ConfirmRename -file $file -taken $taken
			$file = $result.File
			$date = $result.Date
		}
	} else {
		if ($result.Date) {
			out "Set original date to {Green:$($result.Date.ToString("yyyy.MM.dd_HH.mm.ss"))} for {Yellow:$filename}"
			SetTaken $filename $result.Date
			$date = $result.Date
		}
	}

	if ($date) {
		$file.LastWriteTime = $date
	}
}

<# PROCESSOR #>

Function ShouldProcess($name) {
	if ($skip -and $skip.Contains($name)) { return $false }
	if ($only -and !$only.Contains($name)) { return $false }
	return $true
}

Function ProcessFiles([string]$action, [ScriptBlock]$func, [string[]]$filter = "*.*", [switch]$showDirs, [switch]$showFiles) {
	if (!$requiredActions.Contains($action) -and !(ShouldProcess $action)) { return }
	out "{Green:> $($action.ToUpper())}"

	$errors = 0
	$directory = $null

	GetFiles $filter | ? { !$ignoreExtensions.Contains($_.Extension) } | % {
		if ($showDirs) {
			$thisDirectory = Split-Path $_.FullName -Parent

			if ($thisDirectory -ne $directory) {
				$directory = $thisDirectory
				out $directory -ForegroundColor DarkGray
			}
		}

		if ($showFiles) {
			out $_.FullName -ForegroundColor DarkGray
		}

		if ($catchErrors) {
			try {
				$func.Invoke($_)
			} catch {
				$ex = GetExceptionMessage $_
				out $ex -ForegroundColor Red
				$errors ++
			}
		} else {
			$func.Invoke($_)
		}
	}

	if (!$mock -and $errors) {
		out "`nCaught {DarkYellow:$errors} errors" -ForegroundColor Red
		exit 1
	}
}

<# MAIN #>

ProcessFiles "convert"  $function:ConvertVideo       -showDirs -filter ($allVideoExtensions | % { "*$_" })
ProcessFiles "rename"   $function:Rename
ProcessFiles "validate" $function:ValidateExtension
ProcessFiles "resize"   $function:ResizePhoto        -showDirs -filter "*$defaultPhotoExtension"
ProcessFiles "date"     $function:SyncDate           -showDirs

<# DONE #>

out "{Green:Done!}"
if ($path) { Pop-Location }

if ($mock) {
	$mock
}
