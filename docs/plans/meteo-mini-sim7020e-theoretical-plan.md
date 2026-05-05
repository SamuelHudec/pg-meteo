# Meteo Mini + SIM7020E Theoretical Plan

This document is a theoretical integration plan for replacing Wi-Fi with an `NB-IoT` modem on the existing `LaskaKit Meteo Mini` weather station.

It is intentionally separate from the current project documentation and does not change the current Wi-Fi based implementation.

## Goal

Use an external `SIM7020E` modem as the uplink for the station so the device can send measurements through an operator network instead of local Wi-Fi.

## Why SIM7020E Looks Interesting

The `SIM7020E` is attractive for this use case because it is:

- low power compared to older GSM modules
- intended for small IoT payloads
- controlled over `UART` with `AT` commands
- suitable for Europe on `NB-IoT`

This makes it a much better fit than `SIM800L` for a battery-powered outdoor sensor.

## What Makes This Different From Wi-Fi

This is not a drop-in hardware swap.

The current station architecture assumes:

- native Wi-Fi on the ESP32-C3
- HTTP upload over the onboard network stack
- OTA checks over Wi-Fi

With `SIM7020E`, the network path changes:

- the ESP32 no longer sends data directly through its own Wi-Fi stack
- the modem must be powered, initialized, registered to the network, and controlled over `UART`
- HTTP or other uplink traffic must be done through modem commands or through a reworked transport layer

## Hardware Feasibility

At a high level, the integration is feasible.

The `LaskaKit Meteo Mini v4.1` exposes:

- `µŠup I2C`: `IO19`, `IO18`
- `µŠup SPI`: `IO3`, `IO7`, `IO6`, `IO2`
- `µŠup IO`: `IO1`, `IO10`

That gives enough usable pins for a simple modem connection.

Important project-specific note:

- `µŠup IO: IO1, IO10` are already occupied by the anemometer and wind direction sensor in the existing station concept

This means those two pins should be treated as unavailable unless the sensor wiring is redesigned.

## Minimal Signal Set

A practical minimum connection would be:

- `TX` from Meteo Mini to modem `RX`
- `RX` from Meteo Mini to modem `TX`
- `GND`
- modem power

Strongly recommended control lines:

- `PWRKEY` or equivalent modem power-on control
- optional `RESET`
- optional `DTR` for sleep control

## Candidate Pin Mapping

This is only a planning suggestion, not a committed wiring standard, and it assumes the current wind sensor assignments would need to change:

| Meteo Mini pin | Suggested modem signal | Notes |
|---|---|---|
| `IO1` | modem `RX` | ESP transmit to modem |
| `IO10` | modem `TX` | ESP receive from modem |
| `IO3` | `PWRKEY` | if SPI is not needed |
| `IO2` | `RESET` or `DTR` | optional control |
| `GND` | `GND` | shared ground |

Alternative mappings are possible depending on which existing peripherals remain attached.

Given the current project wiring, a more realistic direction would be to look for modem control signals on pins exposed through the `µŠup SPI` header, because `IO1` and `IO10` are not free.

## Power Design Concerns

This is the most important hardware risk.

The modem should not be treated like a tiny sensor peripheral.

Key points:

- do not assume the regular `3.3V` peripheral rail is automatically enough
- modem current spikes need to be handled cleanly
- the power path must be validated against the real board design
- shared ground is mandatory

The safest theoretical approach is:

- power the modem from a battery-capable rail that can tolerate burst current
- keep the ESP and modem on a common ground
- add local bulk capacitance near the modem

Before any build, the exact power topology of the chosen `SIM7020E` board should be reviewed carefully.

## Software Impact

This is where most of the work is.

The current project is centered on `ESPHome`, which is great for Wi-Fi sensors but not a natural fit for a cellular modem transport stack.

Expected software consequences:

- `ESPHome` may no longer be the best main runtime if the modem becomes the primary uplink
- upload logic may need to move to custom ESP-IDF or Arduino code
- modem state handling must be added:
  - boot
  - SIM ready
  - network registration
  - PDP/session setup if needed
  - HTTP or MQTT send
  - low-power return
- OTA strategy likely needs redesign

## Architecture Options

There are three realistic paths.

### 1. Keep ESPHome and Add a Custom Modem Bridge

Pros:

- keeps more of the current measurement logic
- smaller conceptual change at first

Cons:

- likely awkward
- modem integration may fight the framework
- OTA and reliability may remain messy

### 2. Rebuild the Node Around ESP-IDF or Arduino

Pros:

- clean control over modem, sleep, retries, and timing
- better long-term fit for `NB-IoT`

Cons:

- larger rewrite
- more engineering effort up front

### 3. Split Responsibilities

Possible idea:

- Meteo Mini remains a measurement node
- a second controller or modem-side board handles uplink

Pros:

- can isolate modem complexity

Cons:

- more hardware
- usually not worth it unless there is a strong reason

## Recommended Direction

If this ever moves from theory to implementation, the most sensible path would likely be:

1. keep the current Wi-Fi station untouched
2. build a separate modem experiment first
3. validate network registration, low-power behavior, and HTTP upload
4. only then decide whether to migrate the full station away from Wi-Fi

This reduces project risk a lot.

## Main Risks

- modem power instability
- poor `NB-IoT` coverage in the exact deployment location
- difficult integration with the current `ESPHome`-based codebase
- higher implementation effort than the hardware simplicity initially suggests
- redesign needed for OTA updates

## Why LoRa Is Still Simpler

Compared with `SIM7020E`, LoRa stays closer to a simple peripheral:

- no SIM card
- no operator dependency
- no network registration sequence
- easier power behavior

That is why LoRa is simpler for a reusable experimental radio layer, even if `NB-IoT` is more attractive from an internet-connectivity perspective.

## Practical Recommendation

Treat `SIM7020E + Meteo Mini` as a separate future branch of the project, not as a small patch to the current design.

If revisited later, the first real prototype should focus only on:

1. modem power and boot
2. UART control
3. network registration
4. one successful payload upload
5. return to low power

Only after that should sensor integration and production firmware migration be considered.

## Reference Links

- LaskaKit Meteo Mini: https://www.laskakit.cz/en/laskakit-meteo-mini/
- Waveshare Pico-SIM7020E wiki: https://www.waveshare.com/wiki/Pico-SIM7020E-NB-IoT
- Waveshare SIM7020E HAT wiki: https://www.waveshare.com/wiki/SIM7020E_NB-IoT_HAT
