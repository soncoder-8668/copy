# Offline Image + Audio to Video Tool

This repository provides a fully offline tool to turn a folder of images and a single audio file into a 16:9, high-quality video with smooth transitions.

## Requirements

- **Windows**
- **FFmpeg installed and available in PATH** (no automatic download)
- **PowerShell** (built into Windows)

## Quick Start (Double-click)

1. Create a folder named `images` next to the scripts.
2. Put all images inside `images` (supports `.png`, `.jpg`, `.jpeg`, `.bmp`, `.gif`, `.tif`, `.tiff`).
3. Put a single audio file next to the scripts (supports `.wav`, `.mp3`, `.m4a`, `.aac`, `.flac`).
4. Double-click `run_make_video.bat`.

The tool will create `output.mp4` in the same folder.

## Behavior

- Each image is displayed for **10 seconds**.
- Smooth transitions between images (default: `fade` for 1 second).
- Output video is **1920x1080 (16:9)**.
- Image order is determined by the **first number found in each filename**. If a file has no number, it is sorted last by name.
- Audio is automatically detected (first supported audio file in the folder). If no audio is found, the video is created without sound.

## Advanced Usage (PowerShell)

You can run the script directly with custom settings:

```powershell
./make_video.ps1 -AudioPath "my_audio.wav" -ImagesDir "images" -Output "my_video.mp4" -ImageDuration 10 -TransitionDuration 1 -Transition "fade"
```

### Transition Options

FFmpeg supports many `xfade` transitions, such as:

- `fade`
- `wipeleft`
- `wiperight`
- `slideleft`
- `slideright`
- `circleopen`

Example:

```powershell
./make_video.ps1 -Transition "slideleft"
```

## Notes

- The tool is fully offline and will never download dependencies.
- For large image sets (hundreds of files), the script is designed to scale and will generate a single FFmpeg command.
