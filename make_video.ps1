param(
  [string]$AudioPath = "",
  [string]$ImagesDir = "images",
  [string]$Output = "output.mp4",
  [int]$ImageDuration = 10,
  [int]$TransitionDuration = 1,
  [string]$Transition = "fade"
)

$ErrorActionPreference = "Stop"

function Get-OrderedImages {
  param([string]$Dir)

  if (-not (Test-Path -LiteralPath $Dir)) {
    throw "Images directory not found: $Dir"
  }

  $images = Get-ChildItem -Path $Dir -File -Include *.png,*.jpg,*.jpeg,*.bmp,*.gif,*.tif,*.tiff | ForEach-Object {
    $match = [regex]::Match($_.BaseName, '\d+')
    [pscustomobject]@{
      File = $_
      Number = if ($match.Success) { [int]$match.Value } else { [int]::MaxValue }
      Name = $_.Name
    }
  }

  return $images | Sort-Object Number, Name | ForEach-Object { $_.File }
}

function Resolve-AudioPath {
  param([string]$AudioArg)

  if ($AudioArg -and (Test-Path -LiteralPath $AudioArg)) {
    return (Resolve-Path -LiteralPath $AudioArg).Path
  }

  $audio = Get-ChildItem -Path . -File -Include *.wav,*.mp3,*.m4a,*.aac,*.flac | Select-Object -First 1
  if ($audio) {
    return $audio.FullName
  }

  return ""
}

$ffmpeg = Get-Command ffmpeg -ErrorAction SilentlyContinue
if (-not $ffmpeg) {
  throw "ffmpeg not found in PATH. Please install FFmpeg and make sure it is available in PATH."
}

$images = Get-OrderedImages -Dir $ImagesDir
if (-not $images -or $images.Count -lt 1) {
  throw "No images found in $ImagesDir"
}

$audioPath = Resolve-AudioPath -AudioArg $AudioPath

$ffmpegArgs = @()
foreach ($image in $images) {
  $ffmpegArgs += "-loop"
  $ffmpegArgs += "1"
  $ffmpegArgs += "-t"
  $ffmpegArgs += "$ImageDuration"
  $ffmpegArgs += "-i"
  $ffmpegArgs += $image.FullName
}

$audioIndex = $null
if ($audioPath) {
  $audioIndex = $images.Count
  $ffmpegArgs += "-i"
  $ffmpegArgs += $audioPath
}

$scaleFilter = "scale=1920:1080:force_original_aspect_ratio=decrease,pad=1920:1080:(ow-iw)/2:(oh-ih)/2,setsar=1"

$filterParts = @()
for ($i = 0; $i -lt $images.Count; $i++) {
  $filterParts += "[$i:v]$scaleFilter,format=yuv420p[v$i]"
}

$transition = $Transition
$transitionDuration = [double]$TransitionDuration
$imageDuration = [double]$ImageDuration

if ($images.Count -eq 1) {
  $filterParts += "[v0]copy[vout]"
} else {
  $offsetBase = $imageDuration - $transitionDuration
  if ($offsetBase -lt 0.1) {
    throw "Transition duration must be shorter than image duration."
  }

  $currentLabel = "v0"
  for ($i = 1; $i -lt $images.Count; $i++) {
    $offset = ($imageDuration * $i) - $transitionDuration
    $nextLabel = "x$i"
    $filterParts += "[$currentLabel][v$i]xfade=transition=$transition:duration=$transitionDuration:offset=$offset[$nextLabel]"
    $currentLabel = $nextLabel
  }
  $filterParts += "[$currentLabel]copy[vout]"
}

$filterComplex = $filterParts -join ";"
$ffmpegArgs += "-filter_complex"
$ffmpegArgs += $filterComplex
$ffmpegArgs += "-map"
$ffmpegArgs += "[vout]"

if ($audioIndex -ne $null) {
  $ffmpegArgs += "-map"
  $ffmpegArgs += "$audioIndex:a"
  $ffmpegArgs += "-shortest"
}

$ffmpegArgs += "-r"
$ffmpegArgs += "30"
$ffmpegArgs += "-c:v"
$ffmpegArgs += "libx264"
$ffmpegArgs += "-preset"
$ffmpegArgs += "slow"
$ffmpegArgs += "-crf"
$ffmpegArgs += "18"
$ffmpegArgs += "-movflags"
$ffmpegArgs += "+faststart"
$ffmpegArgs += $Output

Write-Host "Running FFmpeg with $($images.Count) images..."
Write-Host "Output: $Output"
if ($audioPath) {
  Write-Host "Audio: $audioPath"
}

& $ffmpeg @ffmpegArgs

Write-Host "Done."
