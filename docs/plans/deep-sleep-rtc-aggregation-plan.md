# Deep Sleep RTC Wind Aggregation Plan

## Summary

Create a staged implementation for Skalka production firmware.

The planned behavior is:

- Keep the existing Windguru upload, OTA update check, manifest URL, retry behavior, and firmware publishing flow unchanged.
- Change only the wake/measurement cycle so one Windguru payload represents 5 deep-sleep sub-measurements.
- Use 5 x 12s wind measurement windows per report.
- Use RTC-retained state for temporary wind aggregation across deep sleep, avoiding frequent flash writes.
- Aggregate wind only: average wind speed, min wind speed, max wind speed, and vector-averaged wind direction.
- Leave temperature and humidity as final-cycle sensor snapshots for this first version.

## Implementation Changes

- Add a small RTC aggregation helper for Skalka, preferably `skalka/esp_config/rtc_wind_aggregation.h`, using an `RTC_DATA_ATTR` state struct with:
  - magic/version field
  - completed sub-measurement count
  - wind speed weighted sum
  - wind speed sample count
  - wind speed min/max
  - wind direction sin/cos sums
  - wind direction sample count
  - invalid/reset marker for cold boot, OTA boot, or version mismatch

- Update `skalka/esp_config/main.yaml` measurement flow:
  - On boot, disable Wi-Fi and power sensors as today.
  - Measure wind for `12s` after the existing `sensor_boot_stabilization_delay`.
  - Merge the current wake's volatile measurement stats into RTC aggregation.
  - If fewer than `5` sub-measurements are complete, skip Wi-Fi entirely and enter deep sleep for about `105s`.
  - If the 5th sub-measurement is complete, finalize the RTC aggregate into the existing report sensors, then continue into the existing Wi-Fi, SNTP, Windguru send, OTA check, and sleep path.

- Keep these production areas behaviorally unchanged:
  - `send_windguru`
  - Windguru URL/hash/query construction
  - `update.check` / OTA install logic
  - retry behavior
  - publish and verify scripts
  - firmware manifest structure

- Refactor measurement reset behavior carefully:
  - Per-wake volatile stats reset before each 12s measurement.
  - RTC aggregate reset only after a completed upload flow, a failed final upload flow, or invalid RTC state.
  - Non-final sub-measurement cycles must not clear RTC aggregate.

- Keep rollback practical for a mountain deployment:
  - Increment `fw_version` only when publishing a test or production build.
  - Preserve the last known-good `skalka/firmware/firmware.ota.bin` and `manifest.json` before publishing.
  - Since OTA checks remain unchanged, reverting means republishing the older working firmware/manifest with a newer version string if the station is still reaching Wi-Fi.

## Test Plan

- First implement and validate on `skalka/esp_config/main.test.yaml` or a bench device before production publishing.
- Run:
  - `./scripts/verify.sh skalka test`
  - `./scripts/verify.sh skalka`
- Add temporary INFO logs during validation showing:
  - current sub-measurement number
  - current wake sample counts
  - retained RTC aggregate counts
  - whether the cycle is sleeping without Wi-Fi or performing final upload
  - finalized wind avg/min/max/direction
- Bench-test expected cycle sequence:
  - wake 1-4: measure, merge, no Wi-Fi, deep sleep
  - wake 5: measure, merge, Wi-Fi on, upload path runs, OTA path runs, aggregate resets
- Test cold boot / power loss:
  - RTC state initializes cleanly
  - no bogus aggregate is uploaded
- Test OTA rollback path before mountain deployment:
  - publish test firmware
  - confirm the device can still check the manifest
  - publish older known-good firmware with a newer version string
  - confirm OTA can return the device to older behavior

## Assumptions

- Target reporting cadence remains approximately one payload per 10 minutes.
- The selected sampling shape is 5 x 12s.
- Temperature and humidity remain final-cycle readings in this version.
- RTC-retained state should be implemented with explicit RTC memory rather than ESPHome restored globals, because ESPHome restored globals may save state through the preferences mechanism and the goal is to avoid repeated flash writes.
- ESPHome deep sleep and globals behavior were checked against official docs:
  - https://esphome.io/components/deep_sleep/
  - https://esphome.io/components/globals/
