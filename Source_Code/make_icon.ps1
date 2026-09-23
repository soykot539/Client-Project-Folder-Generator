Add-Type -AssemblyName System.Drawing

$outputPath = Join-Path $PSScriptRoot "app.ico"
$sizes = @(256, 64, 48, 32, 16)
$pngBytesList = @()

foreach ($sz in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($sz, $sz, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)

    $scale = [float]$sz / 256.0

    # Background rounded badge
    $rectBadge = New-Object System.Drawing.RectangleF((10.0 * $scale), (10.0 * $scale), (236.0 * $scale), (236.0 * $scale))
    $brushBg = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        $rectBadge,
        [System.Drawing.Color]::FromArgb(28, 32, 45),
        [System.Drawing.Color]::FromArgb(12, 15, 24),
        [System.Drawing.Drawing2D.LinearGradientMode]::ForwardDiagonal
    )
    
    $pathBg = New-Object System.Drawing.Drawing2D.GraphicsPath
    $rad = 48.0 * $scale
    $pathBg.AddArc($rectBadge.X, $rectBadge.Y, $rad, $rad, 180.0, 90.0)
    $pathBg.AddArc(($rectBadge.Right - $rad), $rectBadge.Y, $rad, $rad, 270.0, 90.0)
    $pathBg.AddArc(($rectBadge.Right - $rad), ($rectBadge.Bottom - $rad), $rad, $rad, 0.0, 90.0)
    $pathBg.AddArc($rectBadge.X, ($rectBadge.Bottom - $rad), $rad, $rad, 90.0, 90.0)
    $pathBg.CloseFigure()
    
    $g.FillPath($brushBg, $pathBg)

    # Border Glow
    $penBorder = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(65, 130, 240), (4.0 * $scale))
    $g.DrawPath($penBorder, $pathBg)

    # Folder Icon Shape (Cyan / Electric Blue Gradient)
    $fX = 35.0 * $scale
    $fY = 72.0 * $scale
    $fW = 186.0 * $scale
    $fH = 128.0 * $scale
    $fRad = 18.0 * $scale

    $folderBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF($fX, $fY, $fW, $fH)),
        [System.Drawing.Color]::FromArgb(40, 160, 255),
        [System.Drawing.Color]::FromArgb(0, 90, 210),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )

    $folderPath = New-Object System.Drawing.Drawing2D.GraphicsPath
    $folderPath.AddLine(($fX + 15.0*$scale), ($fY - 16.0*$scale), ($fX + 75.0*$scale), ($fY - 16.0*$scale))
    $folderPath.AddLine(($fX + 90.0*$scale), $fY, ($fX + $fW - $fRad), $fY)
    $folderPath.AddArc(($fX + $fW - $fRad), $fY, $fRad, $fRad, 270.0, 90.0)
    $folderPath.AddLine(($fX + $fW), ($fY + $fH - $fRad), ($fX + $fW), ($fY + $fH - $fRad))
    $folderPath.AddArc(($fX + $fW - $fRad), ($fY + $fH - $fRad), $fRad, $fRad, 0.0, 90.0)
    $folderPath.AddLine(($fX + $fW - $fRad), ($fY + $fH), ($fX + $fRad), ($fY + $fH))
    $folderPath.AddArc($fX, ($fY + $fH - $fRad), $fRad, $fRad, 90.0, 90.0)
    $folderPath.AddLine($fX, ($fY + $fRad), $fX, ($fY - 4.0*$scale))
    $folderPath.AddArc($fX, ($fY - 16.0*$scale), (15.0*$scale), (15.0*$scale), 180.0, 90.0)
    $folderPath.CloseFigure()

    $g.FillPath($folderBrush, $folderPath)

    # Lightning Bolt (Gold / Yellow Electric Bolt)
    $boltBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
        (New-Object System.Drawing.RectangleF((90.0 * $scale), (75.0 * $scale), (76.0 * $scale), (115.0 * $scale))),
        [System.Drawing.Color]::FromArgb(255, 235, 80),
        [System.Drawing.Color]::FromArgb(255, 160, 20),
        [System.Drawing.Drawing2D.LinearGradientMode]::Vertical
    )

    $boltPts = @(
        (New-Object System.Drawing.PointF((138.0 * $scale), (75.0 * $scale))),
        (New-Object System.Drawing.PointF((96.0 * $scale), (135.0 * $scale))),
        (New-Object System.Drawing.PointF((128.0 * $scale), (135.0 * $scale))),
        (New-Object System.Drawing.PointF((114.0 * $scale), (192.0 * $scale))),
        (New-Object System.Drawing.PointF((162.0 * $scale), (122.0 * $scale))),
        (New-Object System.Drawing.PointF((132.0 * $scale), (122.0 * $scale)))
    )
    $g.FillPolygon($boltBrush, $boltPts)

    $boltPen = New-Object System.Drawing.Pen([System.Drawing.Color]::FromArgb(255, 255, 220), (2.0 * $scale))
    $g.DrawPolygon($boltPen, $boltPts)

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += ,$ms.ToArray()
    $g.Dispose()
    $bmp.Dispose()
}

# Build Multi-Res ICO
$fs = New-Object System.IO.FileStream($outputPath, [System.IO.FileMode]::Create)
$bw = New-Object System.IO.BinaryWriter($fs)

$bw.Write([UInt16]0) # Reserved
$bw.Write([UInt16]1) # Type 1 = Icon
$bw.Write([UInt16]$sizes.Length) # Image count

$offset = 6 + (16 * $sizes.Length)
for ($i = 0; $i -lt $sizes.Length; $i++) {
    $s = $sizes[$i]
    $bytes = $pngBytesList[$i]
    $w = if ($s -ge 256) { 0 } else { [byte]$s }
    $h = if ($s -ge 256) { 0 } else { [byte]$s }

    $bw.Write([byte]$w)
    $bw.Write([byte]$h)
    $bw.Write([byte]0) # Color count
    $bw.Write([byte]0) # Reserved
    $bw.Write([UInt16]1) # Color planes
    $bw.Write([UInt16]32) # Bit depth
    $bw.Write([UInt32]$bytes.Length)
    $bw.Write([UInt32]$offset)
    $offset += $bytes.Length
}

for ($i = 0; $i -lt $sizes.Length; $i++) {
    $bw.Write($pngBytesList[$i])
}

$bw.Flush()
$fs.Close()
Write-Host "ICON_GENERATED_SUCCESS"
