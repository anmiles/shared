<#
.DESCRIPTION
	Generate a sample video
.PARAMETER color
	Color of the video
.PARAMETER size
	Size of the video square
.PARAMETER duration
	Duration in seconds
.PARAMETER tone
	Audio tone in tone
.PARAMETER output
	Output file
.EXAMPLE
	generate-video
	# generates 1-second video of black 100px square and audio tone A0 into a file black_100px_400hz_1s.mp4
.EXAMPLE
	generate-video -color red -size 150 -duration 1.5 -tone 660 -output mi.mp4
	# generates 1.5-seconds video of red 150px square and audio tone E1 into a file mi.mp4
#>

Param (
	[string]$color = "white",
	[float]$size = 100,
	[float]$duration = 1,
	[float]$tone = 440,
	[string]$output
)

if (!$output) {
	$output = "$($color)_$($size)px_$($tone)hz_$($duration)s.mp4"
}

ffmpeg `
-f lavfi -i color=c=$($color):s=$($size)x$($size):r=30:d=$($duration) `
-f lavfi -i sine=frequency=$($tone):duration=$($duration) `
-c:v libx264 -pix_fmt yuv420p -c:a aac `
$output
