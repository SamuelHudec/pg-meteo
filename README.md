# DIY weather station based on laskakit ESP32

## OTA publish (Docker)

Run from repo root:

```bash
./scripts/publish.sh skalka
```

Prerequisites:
- Docker is running
- `git` and `python3` are installed

What the script does:
1. Compiles `skalka/esp_config/main.yaml` using Docker ESPHome image.
2. Finds built firmware binary and copies it to `skalka/firmware/firmware.ota.bin`.
3. Generates `skalka/firmware/manifest.json` with version + md5.
4. Stages, commits, and pushes firmware + manifest to `origin/main`.
