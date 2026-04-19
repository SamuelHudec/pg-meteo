# microESP-C3 + RFM95W 868 MHz Wiring Guide

This note is a practical wiring guide for building a small universal LoRa radio prototype from:

- `LaskaKit microESP-C3 v3.1`
- `HopeRF RFM95W 868 MHz`
- `868 MHz antenna`

The goal is a reusable radio block that you can later connect to different ESP-based probes or devices.

## What This Prototype Is

This is not a finished weather station node. It is a reusable `ESP32 + LoRa` base that should let you:

- verify that the radio link works
- send simple packets first
- later attach your own sensors or other logic

For the first bring-up, keep it minimal:

- no sensors
- no battery optimization yet
- no LoRaWAN first
- just `ESP32 <-> RFM95W`

Once this works, everything else becomes much easier.

## Parts

- `LaskaKit microESP-C3 v3.1`
- `HopeRF RFM95W 868 MHz`
- `868 MHz antenna`
- short wires
- breadboard or perfboard
- optional `10 uF` to `47 uF` electrolytic or ceramic capacitor near the radio module

## Important Safety Notes

- Power the `RFM95W` only from `3.3V`.
- Do not connect any radio pin directly to `5V`.
- Always connect the antenna before transmitting.
- Keep wires between ESP and radio short.
- Make sure `GND` is shared between the board and the radio.

## Recommended Wiring

The `RFM95W` uses `SPI` plus a few control pins. On the `microESP-C3`, the simplest practical setup is to use the side GPIOs and the exposed `RX` / `TX` pins.

Recommended mapping:

| microESP-C3 pin | ESP32-C3 GPIO | RFM95W pin | Purpose |
|---|---:|---|---|
| `GPIO4` | 4 | `SCK` | SPI clock |
| `GPIO5` | 5 | `MISO` | SPI MISO |
| `TX` | 21 | `MOSI` | SPI MOSI |
| `GPIO3` | 3 | `NSS` / `CS` | chip select |
| `GPIO2` | 2 | `RESET` | radio reset |
| `RX` | 20 | `DIO0` | interrupt from radio |
| `3V3` | - | `3.3V` | power |
| `GND` | - | `GND` | ground |

Optional later:

| microESP-C3 pin | ESP32-C3 GPIO | RFM95W pin | Purpose |
|---|---:|---|---|
| `IO8` on I2C header | 8 | `DIO1` | optional interrupt |

Notes:

- On this board, the external labels `RX` and `TX` are practical to use as normal GPIO once your firmware is running.
- For the first prototype, `DIO0` is the important interrupt pin. `DIO1` can wait.
- If you prefer, `MOSI` and `DIO0` can be reassigned later in software. The pinout above is just a clean starting point.

## RFM95W Pins You Actually Need

For a first working prototype, connect only these radio pins:

- `3.3V`
- `GND`
- `SCK`
- `MISO`
- `MOSI`
- `NSS` or `CS`
- `RESET`
- `DIO0`

You do not need to wire every pin on the module for the first test.

## Physical Build Order

Build it in this order:

1. Solder or place the `microESP-C3`.
2. Place the `RFM95W` so the SPI wires stay short.
3. Connect `3V3` and `GND` first.
4. Connect `SCK`, `MISO`, `MOSI`.
5. Connect `NSS`, `RESET`, `DIO0`.
6. Connect the antenna.
7. Only then start flashing and testing.

If you add a capacitor, place it close to the radio:

- capacitor `+` to `3V3`
- capacitor `-` to `GND`

This helps when the radio draws short current peaks during transmit.

## Minimal Wiring Checklist

Before power-up, verify:

- `3V3 -> 3.3V`
- `GND -> GND`
- `GPIO4 -> SCK`
- `GPIO5 -> MISO`
- `TX -> MOSI`
- `GPIO3 -> NSS`
- `GPIO2 -> RESET`
- `RX -> DIO0`
- antenna attached

## Suggested Firmware Pin Defines

If you later write firmware in Arduino style, these defines match the wiring above:

```cpp
#define PIN_LORA_SCK   4
#define PIN_LORA_MISO  5
#define PIN_LORA_MOSI  21
#define PIN_LORA_CS    3
#define PIN_LORA_RST   2
#define PIN_LORA_DIO0  20
```

If your library supports an optional `DIO1`, you can later add:

```cpp
#define PIN_LORA_DIO1  8
```

## First Test Strategy

Do not start with LoRaWAN. First prove that the radio hardware works.

Recommended test sequence:

1. Flash a simple `LoRa send hello` example.
2. Verify the module initializes successfully.
3. Send a counter every few seconds.
4. Confirm reception on the other side.
5. Only then add your own payload format.
6. Only after that consider LoRaWAN.

This keeps debugging manageable.

## Why This Pinout Is Good for a Universal Prototype

This layout leaves the prototype easy to reuse:

- SPI is grouped on a small set of pins
- the radio has dedicated `CS`, `RESET`, and `DIO0`
- the I2C header stays mostly free for future sensors
- the radio block can later be moved to another ESP32 board with only firmware pin changes

That makes it a good base for a general-purpose transmitter module.

## Common Mistakes

- powering the radio from `5V`
- transmitting without antenna
- forgetting shared ground
- using long loose wires that make SPI unstable
- trying to debug radio, sensors, and network stack all at once

## Practical Next Step

Once the `RFM95W` arrives, the most sensible next step is:

1. wire exactly the pins above
2. flash a minimal packet transmit test
3. if the radio initializes correctly, freeze this pinout as your standard adapter layout

If you want, the next iteration of this file can include:

- a matching receiver wiring guide
- a minimal Arduino sketch
- a `RadioLib` example based on this exact pinout

## Sources

- LaskaKit microESP-C3 product page: https://www.laskakit.cz/laskakit-microesp/
- HopeRF RFM95W product page: https://www.laskakit.cz/hoperf-rfm95w-868mhz-komunikacni-modul/
