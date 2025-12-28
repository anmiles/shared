<#
.SYNOPSIS
    Requests the rectangle
#>

$first = @{}
$second = @{}
$current = @{}
$label_gap = 16

[void][System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

Function CreateForm($screen) {
	$form = New-Object System.Windows.Forms.Form
	$form.Location = $screen.Bounds.Location
	$form.Size = $screen.Bounds.Size
	$form.FormBorderStyle = "None"
	$form.ShowInTaskbar = $false
	$form.ShowIcon = $false
	$form.TopMost = $true
	$form.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
	$form.Opacity = 0.5
	$form.Cursor = [System.Windows.Forms.Cursors]::Hand
	return $form
}

Function CreateLabel($form, $color) {
	$label = [Windows.Forms.Label]::new()
	$label.AutoSize = $true

	$label.BackColor = $form.BackColor
	$label.ForeColor = $color
	$label.Visible = $false
	$form.Controls.Add($label)
	return $label
}

Function DrawLabel($form, $label, $mode) {
	$label.Visible = switch($mode) {
		"rect" {
			[Math]::Abs($current.X - $first.X) -gt $label.Width `
			-and `
			[Math]::Abs($current.Y - $first.Y) -gt $label.Height
		}
		default { $true }
	}

	$label.Text = switch($mode) {
		"rect" { "$([Math]::Abs($current.X - $first.X)) x $([Math]::Abs($current.Y - $first.Y))" }
		default { "$($current.X), $($current.Y)" }
	}

	$closeToXEdge = switch($mode) {
		"begin" { $width -lt $current.X }
		"end" { $width -gt ($form.Size.Width - $current.X) }
	}

	$closeToYEdge = switch($mode) {
		"begin" { $height -lt $current.X }
		"end" { $height -gt ($form.Size.Width - $current.X) }
	}

	$label.Left = if ($mode -eq "rect") {
		($current.X + $first.X - $label.Width) / 2
	} else {
		if ($closeToXEdge) {
			$current.X - $label_begin.Width - $label_gap
		} else {
			$current.X + $label_gap
		}
	}

	$label.Top = if ($mode -eq "rect") {
		($current.Y + $first.Y - $label.Height) / 2
	} else {
		if ($closeToYEdge) {
			$current.Y - $label_begin.Height - $label_gap
		} else {
			$current.Y + $label_gap
		}
	}
}

Function SetFirst($point) {
	$first.X = $point.X
	$first.Y = $point.Y
}

Function SetSecond($point) {
	$second.X = $point.X
	$second.Y = $point.Y
	$form.Close()
}

Function DrawRectangle($point, $is_keyboard) {
	$current.X = $point.X
	$current.Y = $point.Y

	if ($is_keyboard) {
		$flags.SkipMouseMove = $true
		[System.Windows.Forms.Cursor]::Position = $point
	}

	$graphics.Clear($form.BackColor)

	if ($first.X) {
		$x0 = [Math]::Min($first.X, $point.X)
		$x1 = [Math]::Max($first.X, $point.X)
		$y0 = [Math]::Min($first.Y, $point.Y)
		$y1 = [Math]::Max($first.Y, $point.Y)
		$graphics.DrawRectangle($pen, $x0, $y0, $x1 - $x0, $y1 - $y0)
		DrawLabel $form $label_end "end"
		DrawLabel $form $label_rect "rect"
	} else {
		$graphics.DrawLine($pen, $point.X, $form.Location.Y, $point.X, $form.Location.Y + $form.Size.Height)
		$graphics.DrawLine($pen, $form.Location.X, $point.Y, $form.Location.X + $form.Size.Width, $point.Y)
		DrawLabel $form $label_begin "begin"
	}
}

$color = [System.Drawing.Color]::FromArgb(255, 255, 0, 0)
$screen = [System.Windows.Forms.Screen]::AllScreens | ? { $_.Primary }
$form = CreateForm $screen
$label_begin = CreateLabel $form $color
$label_end = CreateLabel $form $color
$label_rect = CreateLabel $form $color
$graphics = $form.CreateGraphics()
$pen = [System.Drawing.Pen]::new($color)
$flags = @{ SkipMouseMove = $false }

$form.add_MouseDown({
	SetFirst $_
})

$form.add_MouseUp({
	SetSecond $_
})

$form.add_MouseMove({
	if ($flags.SkipMouseMove) {
		$flags.SkipMouseMove = $false
		return
	}
	DrawRectangle $_
})

$form.add_KeyDown({
	if ($_.KeyCode -eq "Up") {
		$current.Y--
		DrawRectangle $current $true
	}
	if ($_.KeyCode -eq "Down") {
		$current.Y++
		DrawRectangle $current $true
	}
	if ($_.KeyCode -eq "Left") {
		$current.X--
		DrawRectangle $current $true
	}
	if ($_.KeyCode -eq "Right") {
		$current.X++
		DrawRectangle $current $true
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

@($first.X, $first.Y, $second.X, $second.Y)
