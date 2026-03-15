# DIY weather station based on LaskaKit ESP32

This repository contains the ESPHome configuration and firmware publishing flow for weather stations in this project.

The repository is structured so it can support more than one weather station over time. The station name is passed as a parameter where needed, for example during firmware publishing.

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
2. checks the published firmware manifest
3. if a newer version is available, it downloads and installs the update automatically

The OTA manifest is hosted from this repository and referenced by the ESPHome config in `skalka/esp_config/main.yaml`.

## Manual flashing with ESPHome

### Option 1: ESPHome Web

For a first flash or a recovery flash:

1. Build firmware from this repo or use an already published binary from `skalka/firmware/`.
2. Open `https://web.esphome.io/` in a Chromium-based browser.
3. Connect the ESP32 board over USB.
4. Choose:
   - `skalka/firmware/firmware.factory.bin` for first flash
   - `skalka/firmware/firmware.factory.bin` for recovery if OTA is no longer working
5. Flash the device from the browser UI.

Use the `factory` binary for any manual USB/web flashing.

### Option 2: ESPHome CLI

If you have ESPHome installed locally, you can compile and upload directly from the config:

```bash
esphome run skalka/esp_config/main.yaml
```

This is useful when the board is connected by USB and you want ESPHome to compile and flash in one step.

To only compile:

```bash
esphome compile skalka/esp_config/main.yaml
```

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
- Docker is running
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

## Current implementation notes

- Wind speed is measured continuously from the anemometer pulse input.
- Wind direction is derived from the vane resistance through an ADC -> resistance -> heading mapping.
- Temperature and humidity are read from the SHT4x sensor.
- A local/fake Windguru sender currently exists for testing.
- Deep sleep is still commented out while the short active measurement cycle is being validated.
- Final production aggregation should send one payload per wake cycle, including vector-averaged wind direction.
