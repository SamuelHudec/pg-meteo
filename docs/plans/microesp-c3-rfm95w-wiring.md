# ESP32-C3-LPKit + RFM95W 868 MHz Wiring Guide

This note is a practical wiring guide for building a small universal LoRa radio prototype from:

- `LaskaKit ESP32-C3-LPKit`
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

- `LaskaKit ESP32-C3-LPKit`
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

The `RFM95W` uses `SPI` plus a few control pins. On the `ESP32-C3-LPKit`, the simplest practical setup is to connect the radio over `SPI` and use a few free GPIOs for chip select, reset, and interrupt.

The important idea is:

- use `SPI` for `SCK`, `MISO`, and `MOSI`
- use one GPIO for `NSS` or `CS`
- use one GPIO for `RESET`
- use one GPIO for `DIO0`

Recommended mapping:

| ESP32-C3-LPKit pin | ESP32-C3 GPIO | RFM95W pin | Purpose |
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

| ESP32-C3-LPKit pin | ESP32-C3 GPIO | RFM95W pin | Purpose |
|---|---:|---|---|
| `IO8` on I2C header | 8 | `DIO1` | optional interrupt |

Notes:

- On this board, `SPI` is the correct and recommended way to connect the `RFM95W`.
- The external labels `RX` and `TX` are practical to use as normal GPIO once your firmware is running.
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

1. Solder or place the `ESP32-C3-LPKit`.
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

## LoRaWAN Coverage Tester Idea

For this project, a very practical next step is not a full weather station node, but a small handheld `LoRaWAN` test gadget.

The main question this device should answer is:

- can the planned weather station location reliably reach an existing `LoRaWAN` gateway

This is important because the long-term goal is to send weather station data to the internet without building a custom `LoRa` receiver.

## Why Build This First

A dedicated test node helps answer the most important deployment question early:

- is there usable `LoRaWAN` coverage at the chosen place

It also gives you a reusable diagnostic tool for:

- comparing multiple mounting locations
- checking antenna orientation effects
- testing near the final enclosure
- validating coverage before building the complete station

This keeps early testing focused on connectivity instead of mixing in sensors, station firmware, and power-management problems.

## Architecture Assumption

This plan assumes the preferred path is:

- use an existing public, community, or commercial `LoRaWAN` network if coverage exists

That means the communication chain should look like:

- `test gadget or weather station -> LoRaWAN gateway -> internet -> application/backend -> Windguru`

So this gadget is not meant to talk to a custom local receiver. It is meant to prove that the chosen site can join and send uplinks through an existing `LoRaWAN` network.

## Suggested V1 Hardware

For the first version, keep it minimal:

- `LaskaKit ESP32-C3-LPKit`
- `HopeRF RFM95W 868 MHz`
- `868 MHz antenna`
- `1 push button` for send
- `1 LED` for status
- optional second LED or buzzer later
- `USB power bank` or USB cable for power during first tests

Do not optimize for final battery life in this phase. The main job is to produce repeatable `LoRaWAN` uplinks.

## Suggested V1 Behavior

The firmware can stay intentionally small:

- on boot, blink the LED to show the device is alive
- try to join the configured `LoRaWAN` network
- indicate join success or failure using the LED
- short button press sends one uplink
- long button press sends multiple uplinks with a small delay between them

Example behavior:

1. boot and attempt network join
2. LED shows whether join succeeded
3. short press sends `1` uplink
4. long press sends `10` uplinks, one every few seconds
5. each uplink increments a counter

This makes field testing easy even without a screen.

## Suggested Payload Content

Each transmitted payload should be easy to inspect in the `LoRaWAN` backend.

Suggested fields:

- `device_id`
- `packet_counter`
- `uptime_ms` or simple time since boot
- `button_mode`
- optional `battery_voltage`

This is enough to confirm:

- the node joined successfully
- uplinks are arriving
- uplinks are not duplicated unexpectedly
- packet loss rate can be estimated
- the device stayed powered and operating correctly

## What To Verify

During field testing, the most useful checks are:

- whether the node can join the `LoRaWAN` network from that place
- whether uplinks appear consistently in the backend
- how often packets are lost
- whether signal quality stays acceptable
- whether moving the device or antenna changes reliability

## What Not To Add Yet

For the first coverage tester, avoid extra complexity:

- no weather sensors yet
- no display unless truly needed
- no battery optimization yet
- no station enclosure constraints yet
- no final weather-station firmware yet

The faster this prototype becomes usable, the faster you can learn whether the planned station location is viable for `LoRaWAN`.

## Recommended Development Path

The most sensible order is:

1. build the `ESP32-C3-LPKit + RFM95W` radio prototype connected over `SPI`
2. add a button and LED
3. choose a target `LoRaWAN` network
4. configure the device for network join
5. test the gadget at home in Prague, where `LoRaWAN` coverage should be much more likely
6. send a known uplink on demand
7. verify uplinks in the network backend
8. once the gadget works reliably at home, test from the planned weather station location
9. only then start integrating `LoRaWAN` into the real weather station design

## Home-First Test Plan

Before going to terrain, first prove that the gadget itself is working in a place where `LoRaWAN` coverage is expected to be available.

The purpose of the home test in Prague is to separate two questions:

- does the gadget and network setup work at all
- does the target field location have enough `LoRaWAN` coverage

This matters because a failure in terrain can otherwise be ambiguous. It may be caused by:

- wrong wiring
- firmware problem
- bad device registration
- antenna issue
- no `LoRaWAN` coverage at the field location

Testing at home first makes debugging much easier.

Recommended home test sequence:

1. power the gadget at home
2. verify that it can join the chosen `LoRaWAN` network
3. press the button and send one uplink
4. confirm that the uplink appears in the backend
5. repeat several times to check reliability
6. try a few positions such as near a window, inside a room, and outside if practical

Only after this works reliably should the same gadget be taken to the planned station location for a real coverage test.

## Result

If this test gadget works well, it becomes a reusable tool for the whole project:

- `LoRaWAN` coverage tester
- bring-up transmitter
- troubleshooting device
- reference hardware for later station integration

## Sources

- LaskaKit ESP32-C3-LPKit product page
- HopeRF RFM95W product page: https://www.laskakit.cz/hoperf-rfm95w-868mhz-komunikacni-modul/
