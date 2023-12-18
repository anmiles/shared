<#
.SYNOPSIS
    Requests the crop rectangle
.PARAMETER width
    Original width. If specified, recalculates result from screen width to the specified width
.PARAMETER height
    Original height. If specified, recalculates result from screen height to the specified height
#>

Param (
    [int]$width = 0,
    [int]$height = 0
)

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
# $screen = [System.Windows.Forms.Screen]::AllScreens | Sort { $_.Bounds.X } | Select -Last 1
$screen = [System.Windows.Forms.Screen]::AllScreens | ? { $_.Primary }
$form = New-Object System.Windows.Forms.Form
$form.Location = $screen.Bounds.Location
$form.Size = $screen.Bounds.Size
$form.FormBorderStyle = "None"
$form.StartPosition = "Manual"
$form.ShowInTaskbar = $false
$form.ShowIcon = $false
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$form.Opacity = 0.5

$first = @{}
$second = @{}
$current = @{}
$manual = @{}
$result = @{}
$graphics = $form.CreateGraphics()
$pen = [System.Drawing.Pen]::new([System.Drawing.Color]::Red)

Function SetFirst($point) {
	$first.X = $point.X
	$first.Y = $point.Y
}

Function SetSecond($point) {
	$second.X = $point.X
	$second.Y = $point.Y
	$form.Close()
}

Function DrawRectangle($point, $is_manual) {
	$current.X = $point.X
	$current.Y = $point.Y

	$graphics.Clear($form.BackColor)

	if ($first.X) {
		$x0 = [Math]::Min($first.X, $point.X)
		$x1 = [Math]::Max($first.X, $point.X)
		$y0 = [Math]::Min($first.Y, $point.Y)
		$y1 = [Math]::Max($first.Y, $point.Y)
		$graphics.DrawRectangle($pen, $x0, $y0, $x1 - $x0, $y1 - $y0)
	} else {
		$graphics.DrawLine($pen, $point.X, $form.Location.Y, $point.X, $form.Location.Y + $form.Size.Height)
		$graphics.DrawLine($pen, $form.Location.X, $point.Y, $form.Location.X + $form.Size.Width, $point.Y)
	}
}

$form.add_MouseDown({
	SetFirst $_
})

$form.add_MouseUp({
	SetSecond $_
})

$form.add_MouseMove({
	DrawRectangle $_
})

$form.add_KeyDown({
	if ($_.KeyCode -eq "Up") {
		$current.Y--
		DrawRectangle $current
	}
	if ($_.KeyCode -eq "Down") {
		$current.Y++
		DrawRectangle $current
	}
	if ($_.KeyCode -eq "Left") {
		$current.X--
		DrawRectangle $current
	}
	if ($_.KeyCode -eq "Right") {
		$current.X++
		DrawRectangle $current
	}
	if ($_.KeyCode -eq "Escape") {
		$form.Close()
	}
	if ($_.KeyCode -eq "Enter") {
		if ($first.X) {
			SetSecond $current
		} else {
			SetFirst $current
		}
	}
})

[void]$form.ShowDialog()

$first.X = [Math]::Min($first.X, $second.X)
$second.X = [Math]::Max($first.X, $second.X)
$first.Y = [Math]::Min($first.Y, $second.Y)
$second.Y = [Math]::Max($first.Y, $second.Y)

if ($width -or $height) {
	$ratio = 1.0
	if ($width) { $ratio = [Math]::Min($ratio, $width / $screen.Bounds.Size.Width) }
	if ($height) { $ratio = [Math]::Max($ratio, $height / $screen.Bounds.Size.Height) }

	$first.X = [Math]::Round($first.X * $ratio)
	$second.X = [Math]::Round($second.X * $ratio)
	$first.Y = [Math]::Round($first.Y * $ratio)
	$second.Y = [Math]::Round($second.Y * $ratio)
}

"$($second.X - $first.X):$($second.Y - $first.Y):$($first.X):$($first.Y)"
