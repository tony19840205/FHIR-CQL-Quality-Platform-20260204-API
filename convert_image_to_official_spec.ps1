param(
    [Parameter(Mandatory = $true)]
    [string]$InputImage,

    [string]$OutputImage = "",

    [int]$Dpi = 300,

    [double]$MinMegapixels = 4.0
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Test-Path $InputImage)) {
    throw "Input image not found: $InputImage"
}

Add-Type -AssemblyName System.Drawing

function Get-ImageFormat {
    param([string]$Path)

    $ext = [System.IO.Path]::GetExtension($Path).ToLowerInvariant()
    switch ($ext) {
        ".jpg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".jpeg" { return [System.Drawing.Imaging.ImageFormat]::Jpeg }
        ".png" { return [System.Drawing.Imaging.ImageFormat]::Png }
        ".bmp" { return [System.Drawing.Imaging.ImageFormat]::Bmp }
        ".gif" { return [System.Drawing.Imaging.ImageFormat]::Gif }
        default { return [System.Drawing.Imaging.ImageFormat]::Png }
    }
}

function Get-EdgeAverageColor {
    param([System.Drawing.Image]$Image)

    $bmp = New-Object System.Drawing.Bitmap($Image)
    try {
        $w = $bmp.Width
        $h = $bmp.Height
        $band = [int][Math]::Max(6, [Math]::Min(40, [Math]::Floor([Math]::Min($w, $h) * 0.03)))

        $sumR = 0L
        $sumG = 0L
        $sumB = 0L
        $count = 0L

        for ($y = 0; $y -lt $h; $y++) {
            for ($x = 0; $x -lt $w; $x++) {
                $isEdge = ($x -lt $band) -or ($x -ge ($w - $band)) -or ($y -lt $band) -or ($y -ge ($h - $band))
                if ($isEdge) {
                    $c = $bmp.GetPixel($x, $y)
                    $sumR += [int64]$c.R
                    $sumG += [int64]$c.G
                    $sumB += [int64]$c.B
                    $count++
                }
            }
        }

        if ($count -eq 0) {
            return [System.Drawing.Color]::Black
        }

        $avgR = [int][Math]::Round($sumR / [double]$count)
        $avgG = [int][Math]::Round($sumG / [double]$count)
        $avgB = [int][Math]::Round($sumB / [double]$count)
        return [System.Drawing.Color]::FromArgb($avgR, $avgG, $avgB)
    }
    finally {
        $bmp.Dispose()
    }
}

$inputFullPath = (Resolve-Path $InputImage).Path
if ([string]::IsNullOrWhiteSpace($OutputImage)) {
    $dir = [Environment]::GetFolderPath("Desktop")
    $name = [System.IO.Path]::GetFileNameWithoutExtension($inputFullPath)
    $ext = [System.IO.Path]::GetExtension($inputFullPath)
    $OutputImage = Join-Path $dir ("{0}_official{1}" -f $name, $ext)
}

$img = [System.Drawing.Image]::FromFile($inputFullPath)
try {
    $srcW = [int]$img.Width
    $srcH = [int]$img.Height
    $paddingColor = Get-EdgeAverageColor -Image $img

    # Ensure landscape canvas. For square/portrait images, use a 4:3 landscape canvas.
    $canvasW = $srcW
    $canvasH = $srcH
    $wasPaddedToLandscape = $false
    if ($srcW -le $srcH) {
        $canvasH = $srcH
        $canvasW = [int][Math]::Ceiling($canvasH * (4.0 / 3.0))
        if ($canvasW -le $canvasH) {
            $canvasW = $canvasH + 1
        }
        $wasPaddedToLandscape = $true
    }

    $srcPixels = [double]$canvasW * [double]$canvasH
    $minPixels = $MinMegapixels * 1000000.0

    if ($srcPixels -ge $minPixels) {
        $targetW = $canvasW
        $targetH = $canvasH
    }
    else {
        $scale = [Math]::Sqrt($minPixels / $srcPixels)
        $targetW = [int][Math]::Ceiling($canvasW * $scale)
        $targetH = [int][Math]::Ceiling($canvasH * $scale)
    }

    $bmp = New-Object System.Drawing.Bitmap($targetW, $targetH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $bmp.SetResolution($Dpi, $Dpi)

        $g = [System.Drawing.Graphics]::FromImage($bmp)
        try {
            $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $g.Clear($paddingColor)

            # Fit source image into landscape canvas and center it (keeps full content, no cropping).
            $fitScale = [Math]::Min(([double]$targetW / [double]$srcW), ([double]$targetH / [double]$srcH))
            $drawW = [int][Math]::Round([double]$srcW * $fitScale)
            $drawH = [int][Math]::Round([double]$srcH * $fitScale)
            $drawX = [int][Math]::Floor(($targetW - $drawW) / 2.0)
            $drawY = [int][Math]::Floor(($targetH - $drawH) / 2.0)
            $g.DrawImage($img, $drawX, $drawY, $drawW, $drawH)
        }
        finally {
            $g.Dispose()
        }

        $format = Get-ImageFormat -Path $OutputImage
        $bmp.Save($OutputImage, $format)
    }
    finally {
        $bmp.Dispose()
    }

    $newPixels = [double]$targetW * [double]$targetH
    Write-Host "Converted successfully"
    Write-Host ("Input : {0} ({1}x{2})" -f $inputFullPath, $srcW, $srcH)
    Write-Host ("Padding color: RGB({0},{1},{2})" -f $paddingColor.R, $paddingColor.G, $paddingColor.B)
    if ($wasPaddedToLandscape) {
        Write-Host ("Canvas: auto landscape padding applied ({0}x{1})" -f $canvasW, $canvasH)
    }
    Write-Host ("Output: {0} ({1}x{2}, {3:N0} px, {4} dpi)" -f $OutputImage, $targetW, $targetH, $newPixels, $Dpi)
}
finally {
    $img.Dispose()
}
