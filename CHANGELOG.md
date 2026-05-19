# Changelog

Notable project changes are tracked here.

## Unreleased

- Started the project changelog and backfilled Skalka notes from older commit messages.

## 2026-05-19

- Increased the Skalka anemometer pulse debounce filter from `5ms` to `10ms` to reduce false maximum wind speed spikes caused by contact bounce.

## 2026-05-11

- Bumped the Skalka firmware version.
- Added minimum wind speed handling.

## 2026-05-08

- Added median and moving-average filtering for Skalka wind speed readings.
- Updated Skalka Wi-Fi configuration.

## 2026-05-05

- Added planning notes for communication module replacement and version updates.

## 2026-04-20

- Fixed clean output handling.

## 2026-04-19

- Added Windguru upload work for Skalka.
- Added LoRa manual notes and free Wi-Fi notes for Skalka.
- Fixed logging behavior.

## 2026-04-08

- Added first production-oriented Skalka firmware version.

## 2026-03-26

- Fixed Balcony update handling and changed the Skalka IP configuration.

## 2026-03-25

- Raised the Skalka anemometer calibration factor.

## 2026-03-23

- Added anemometer denoising.

## 2026-03-18

- Added Skalka main production config.
- Added the verification script.

## 2026-03-17

- Split Skalka development and production ESPHome configs.
- Added battery level sensor work.
- Polished ignore rules.

## 2026-03-15

- Added average and maximum wind speed handling.
- Reduced log output.
- Updated description and reset button behavior.
- Added enclosure and map updates.

## 2026-03-04

- Expanded ignore rules.

## 2026-03-03

- Added I2C upload work.

## 2026-03-01

- Added HTTP GET testing.
- Added firmware export support and working HTTP update flow.

## 2026-02-13

- Added publish script.
- Added initial Skalka ESPHome config.

## 2026-02-11

- Added initial Skalka sketch.
