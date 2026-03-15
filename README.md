# DIY weather station based on LaskaKit ESP32

This repository contains the ESPHome configuration and firmware publishing flow for weather stations in this project.

Hardware base board: [LaskaKit Meteo Mini](https://www.laskakit.cz/laskakit-meteo-mini/?variantId=10473)

## What the station does

The intended device behavior is:

1. Wake up from deep sleep.
2. Wait briefly for sensor and Wi-Fi stabilization.
3. Measure:
   - temperature
   - humidity
   - wind speed
   - wind direction
4. Aggregate one payload for Windguru:
   - temperature
   - humidity
   - average wind speed
   - maximum wind speed
   - wind direction
5. Send the payload to `windguru.cz`.
6. Go back to deep sleep.

During development, deep sleep can stay disabled so the short-period measurement and upload flow can be validated while the node remains awake.

## OTA update behavior

On boot, the device:

1. waits for Wi-Fi for a limited time
2. checks the published firmware manifest in this repo
3. if a newer version is available, it downloads and installs the update automatically

The OTA manifest is hosted from this repository and referenced by the ESPHome config in `skalka/esp_config/main.yaml`.

## Manual flashing with ESPHome

For a first flash or a recovery flash:

1. Build firmware from this repo or use an already published binary from `skalka/firmware/`.
2. Open `https://web.esphome.io/` in a Chromium-based browser.
3. Connect the ESP32 board over USB.
4. Choose `firmware.factory.bin`
5. Flash the device from the browser UI.

## Multiple weather stations

- The repository is prepared so the same workflow can be reused for more than one weather station.
- The weather station name is passed as a parameter to the publish script.

Current example:

```bash
./scripts/publish.sh skalka
```

## Firmware publish (Docker)

Run from repo root:

```bash
./scripts/publish.sh skalka
```

Prerequisites:
- Docker deamon is running (if you do not have Docker download and install for your OS)
- `git` and `python3` are installed

What the script does:
1. Compiles `skalka/esp_config/main.yaml` using the Docker ESPHome image.
2. Copies built firmware images to:
   - `skalka/firmware/firmware.factory.bin`
   - `skalka/firmware/firmware.ota.bin`
3. Generates `skalka/firmware/manifest.json` with version and md5 hashes.
4. Stages, commits, and pushes firmware artifacts and manifest to `origin/main`.

## Firmware file types

- `skalka/firmware/firmware.factory.bin`: use for first flash, USB flash, browser flash, or recovery flash
- `skalka/firmware/firmware.ota.bin`: use for OTA updates on a device already running ESPHome
- `skalka/firmware/manifest.json`: OTA manifest used by the device to detect and download new firmware

## Local test server

The repository includes a small fake Windguru server for local validation.

Run it from the repo root:

```bash
python3 test_server/fake_windguru_server.py
```

It listens on:

```text
http://0.0.0.0:8080/upload/api.php
```

What it does:
- accepts Windguru-like GET requests
- returns `200 OK`
- logs each request to `windguru_log.jsonl`
- prints a short summary to the terminal

This is useful while validating the measurement and upload flow before switching to the real `windguru.cz` endpoint.

## 3D printable parts

The repository also contains 3D models for printed hardware parts in the [`3D/`](3D) folder.

Included assets:
- enclosure models in `3D/enclosure/`
- mounting arms and holders in `3D/mount/`

## Current implementation notes

- Wind speed is measured continuously from the anemometer pulse input.
- Wind direction is derived from the vane resistance through an ADC -> resistance -> heading mapping.
- Temperature and humidity are read from the SHT4x sensor.
- A local/fake Windguru sender currently exists for testing.
- Deep sleep is still commented out while the short active measurement cycle is being validated.
- Final production aggregation should send one payload per wake cycle, including vector-averaged wind direction.
