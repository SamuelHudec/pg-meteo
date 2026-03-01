# DIY weather station based on laskakit ESP32

## Firmware publish (Docker)

Run from repo root:

```bash
./scripts/publish.sh skalka
```

Prerequisites:
- Docker is running
- `git` and `python3` are installed

What the script does:
1. Compiles `skalka/esp_config/main.yaml` using Docker ESPHome image.
2. Copies built firmware images to:
   - `skalka/firmware/firmware.factory.bin` (first USB/web flash)
   - `skalka/firmware/firmware.ota.bin` (OTA updates)
3. Generates `skalka/firmware/manifest.json` with version + md5 hashes for both images.
4. Stages, commits, and pushes firmware artifacts + manifest to `origin/main`.

Binary types:
- `firmware.factory.bin`: use for the first flash to a new/blank device.
- `firmware.ota.bin`: use only for updates on a device that already runs ESPHome firmware.

todo: add a flag --push
