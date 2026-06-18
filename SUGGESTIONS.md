# Suggestions

Ideas noticed while porting from the HiFive1/FE310 to the XIAO ESP32-C6. None
were requested; they are candidate improvements, not commitments.

## Battery monitoring via the onboard SAR ADC

`DESIGN.md` notes this: the FE310 had no ADC, so the original plan put pack
voltage on an external I²C ADS1115. The ESP32-C6 has a SAR ADC on the lower
header pins (D0–D2 / GPIO0–GPIO2), which the current pin assignment keeps free
for exactly this. A resistor divider into one of those reads pack voltage
directly and removes a part from the BOM. The ADS1115 stays an option if higher
resolution or a dedicated channel is wanted.

## Wireless pump control / telemetry

The ESP32-C6 has WiFi 6, BLE and 802.15.4 (Thread/Zigbee) on-chip. The pump could
expose remote start/stop/rate or report status and battery state over a radio
with no extra hardware. Out of scope for the initial bring-up.

## Host-side tests for the motor math, emul for future sensors

The period/duty arithmetic in `app/src/motor.c` (`start_train`, the `steps`
duration calc) is pure logic and could be unit-tested on `native_sim` with ztest,
independent of hardware. If I²C sensors are added later, Zephyr's `emul`
framework can model them in software so driver and app logic are testable in CI
without the physical parts.
