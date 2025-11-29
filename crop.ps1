<#
.SYNOPSIS
	Returns the crop for the requested rectangle
.PARAMETER src_width
	Width of the source
.PARAMETER src_height
	Height of the source
.PARAMETER rect
	Rectangle to crop. Specified as array of [x1, y1, x2, y2] as visible on the primary screen. Will be recalculated according to src_width and src_height
#>

Param (
	[int]$src_width,
	[int]$src_height,
	[int[]]$rect
)

$screen = [System.Windows.Forms.Screen]::AllScreens | ? { $_.Primary }
$screen_width = $screen.Bounds.Size.Width
$screen_height = $screen.Bounds.Size.Height

$x1, $y1, $x2, $y2 = $rect

# ""
# '$x1, $y1, $x2, $y2'
# $x1, $y1, $x2, $y2

$xc1 = $x1 - $screen_width / 2
$xc2 = $x2 - $screen_width / 2
$yc1 = $y1 - $screen_height / 2
$yc2 = $y2 - $screen_height / 2

# ""
# '$xc1, $yc1, $xc2, $yc2'
# $xc1, $yc1, $xc2, $yc2

$max_ratio = [Math]::Max($src_width / $screen_width, $src_height / $screen_height)

$xc1 = [Math]::Round($xc1 * $max_ratio)
$xc2 = [Math]::Round($xc2 * $max_ratio)
$yc1 = [Math]::Round($yc1 * $max_ratio)
$yc2 = [Math]::Round($yc2 * $max_ratio)

# ""
# '$xc1, $yc1, $xc2, $yc2'
# $xc1, $yc1, $xc2, $yc2

$x1 = $xc1 + $src_width / 2
$x2 = $xc2 + $src_width / 2
$y1 = $yc1 + $src_height / 2
$y2 = $yc2 + $src_height / 2

# ""
# '$x1, $y1, $x2, $y2'
# $x1, $y1, $x2, $y2

$x1 = [Math]::Max($x1, 0)
$x2 = [Math]::Min($x2, $src_width)
$y1 = [Math]::Max($y1, 0)
$y2 = [Math]::Min($y2, $src_height)

# ""
# '$x1, $y1, $x2, $y2'
# $x1, $y1, $x2, $y2

$width = $x2 - $x1
$height = $y2 - $y1

"$($width):$($height):$($x1):$($y1)"
