# DIY weather station based on LaskaKit ESP32

This repository contains the ESPHome configuration and firmware publishing flow for weather stations in this project.

Hardware base board: [LaskaKit Meteo Mini](https://www.laskakit.cz/laskakit-meteo-mini/?variantId=10473)

## Components

Main prototype parts with rough price estimates:

- [LaskaKit Meteo Mini](https://www.laskakit.cz/laskakit-meteo-mini/) - about `398 CZK`
- [GeB LiPol battery 603048 900mAh 3.7V](https://www.laskakit.cz/ehao-lipol-baterie-603048-900mah-3-7v/) - about `100 CZK`
- [WH-SP-WS01 wind speed sensor / anemometer](https://www.laskakit.cz/wh-sp-ws01-cidlo-rychlosti-vetru-anemometr/) - about `228 CZK`
- [WH-SP-WD wind direction sensor](https://www.laskakit.cz/wh-sp-wd-cidlo-smeru-vetru/) - about `288 CZK`
- [LaskaKit SHT40 temperature and humidity sensor](https://www.laskakit.cz/laskakit-sht40-senzor-teploty-a-vlhkosti-vzduchu/) - about `88 CZK`
- [Connfly DS1133-03-S40B RJ11 6/4 connector](https://www.gme.cz/v/1502422/connfly-ds1133-03-s40b-konektor-rj11-6-4) - about `10 CZK`
- [Solar panel 5V 7W with wall mount](https://www.laskakit.cz/solarni-panel-5v-7w-s-drzakem-na-zed/) - about `608 CZK`
- [Pigtail MHF3/IPEX3 to SMA Female, 15cm](https://www.laskakit.cz/pigtail-mhf3-ipex3-sma-female--kabel-1-15mm--15cm/) - about `48 CZK`
- [2.4 GHz antenna 5dBi 19cm](https://www.laskakit.cz/antena-5dbi-19cm-2-4g-bila/) - about `68 CZK`
- [USB-C to JST-PH-2 power cable, 10cm](https://www.laskakit.cz/napajeci-kabel-jq-118j-usb-c-do-jst-ph-2-2mm-10cm/) - about `28 CZK`
- [JST-SH 3-pin cable, 10cm](https://www.laskakit.cz/--sup-io-jst-sh-3-pin-kabel-10cm/) - about `18 CZK`
- [Yageo MFR-25FTE52 metal oxide resistor, 1/4W, 1%](https://www.laskakit.cz/metal-oxidovy-rezistor-yageo-mfr-25fte52-1-4w-1-/?variantId=19979) - about `1 CZK`

Rough total for the listed electronics is about `1,900 CZK`.

This is only a rough parts estimate. It does not include printed parts, fasteners, shipping, or any replacement/alternative components.

3D printable parts are also included in the repository:
- enclosure models in `3D/enclosure/`
- mounting arms and holders in `3D/mount/`

## What the station does

The production device behavior is:

1. Wake up from deep sleep.
2. Power sensors and wait briefly for stabilization.
3. Measure:
   - temperature
   - humidity
   - wind speed
   - wind direction
4. Keep Wi-Fi off during the measurement window to save energy.
5. Aggregate one payload for Windguru:
   - temperature
   - humidity
   - average wind speed
   - maximum wind speed
   - wind direction
6. Enable Wi-Fi only after measurement is complete.
7. Send the payload to `windguru.cz`.
8. Check for OTA updates at most once per day.
9. Go back to deep sleep.

For tuning and debugging, `main.test.yaml` keeps the development-oriented always-on behavior.

## OTA update behavior

In the production config, the device:

1. enables Wi-Fi only after the measurement phase
2. checks the published firmware manifest in this repo at most once per day
3. if a newer version is available, it downloads and installs the update automatically

The OTA manifest is hosted from this repository and referenced by the ESPHome config in `skalka/esp_config/main.yaml`.

## Manual flashing with ESPHome

For a first flash or a recovery flash:

1. Build firmware from this repo or use an already published binary from `skalka/firmware/`.
2. Open `https://web.esphome.io/` in a Chromium-based browser.
3. Connect the ESP32 board over USB.
4. Choose `firmware.factory.bin`
5. Flash the device from the browser UI.

## Firmware publish

Prerequisites:
- Docker deamon is running (if you do not have Docker download and install for your OS)
- `git` and `python3` are installed

Run from repo root:

```bash
./scripts/publish.sh <station>
```

To publish the tuning/test config instead:

```bash
./scripts/publish.sh <station> test
```

Example:

```bash
./scripts/publish.sh skalka
```

What the script does:
1. Compiles `<station>/esp_config/main.yaml` by default, or `<station>/esp_config/main.test.yaml` when `test` is passed as the second argument.
2. Copies built firmware images to:
   - `<station>/firmware/firmware.factory.bin`
   - `<station>/firmware/firmware.ota.bin`
3. Generates `<station>/firmware/manifest.json` with version and md5 hashes.
4. Stages, commits, and pushes firmware artifacts and manifest to `origin/main`.

Note:
- `./scripts/publish.sh <station> test` still publishes to the same `<station>/firmware/` files and manifest as the normal publish flow, so it temporarily replaces the regular published firmware until the next standard publish.
- For quick development checks, use `./scripts/verify.sh <station>` or `./scripts/verify.sh <station> test` instead. It compiles the selected config and validates that OTA and factory binaries were produced, but it does not copy firmware, generate manifests, commit, or push anything.

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

## Current implementation notes

- Wind speed is measured continuously from the anemometer pulse input.
- Wind direction is derived from the vane resistance through an ADC -> resistance -> heading mapping.
- Temperature and humidity are read from the SHT4x sensor.
- A local/fake Windguru sender currently exists for testing.
- `skalka/esp_config/main.yaml` is the production-oriented config with measure-first, Wi-Fi-late, deep-sleep behavior.
- `skalka/esp_config/main.test.yaml` is the tuning-oriented config with the development behavior.
- The production flow sends one payload per wake cycle, including vector-averaged wind direction.
