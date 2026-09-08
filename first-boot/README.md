# Files that go on `FLY-SETUP`

The named Fly Lite image exposes a small **FAT32** partition labelled `FLY-SETUP`. Windows, macOS, and Linux can read it after flash (replug the reader if the imager ejected the card).

| File | Role |
| --- | --- |
| [`fly-net.txt`](fly-net.txt) | Headless Wi-Fi. Placeholder SSID is ignored until edited. |
| [`README.txt`](README.txt) | Plain-text setup for a new user (Wi-Fi file, serial, HDMI+keyboard). |

`scripts/prepare-sd.sh` copies both onto a mounted FAT volume and, for stock Armbian, also writes `armbian_first_run.txt`.

Serial notes for Windows (COM4, DTR): [`windows.md`](windows.md).
