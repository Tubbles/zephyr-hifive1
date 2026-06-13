#!/usr/bin/env bash
#
# Print the HiFive1 Rev B serial console. The onboard J-Link OB exposes the
# board UART as a USB CDC-ACM device (/dev/ttyACM*). This is a read-only
# monitor built only on coreutils (stty + cat); Ctrl-C to stop.
#
# Usage:
#   ./console.sh                 # auto-pick the first /dev/ttyACM*, 115200 baud
#   ./console.sh /dev/ttyACM1    # explicit device
#   ./console.sh /dev/ttyACM0 9600
#
# Needs read access to the device: add yourself to the 'dialout' group once
# (sudo usermod -aG dialout $USER, then log out/in) or run this with sudo.
set -euo pipefail

DEVICE="${1:-}"
BAUD="${2:-115200}"

# Auto-detect the device if none was given: take the first /dev/ttyACM*.
if [ -z "$DEVICE" ]; then
  shopt -s nullglob
  candidates=(/dev/ttyACM*)
  shopt -u nullglob
  if [ ${#candidates[@]} -eq 0 ]; then
    echo "error: no /dev/ttyACM* found. Is the board plugged in?" >&2
    exit 1
  fi
  DEVICE="${candidates[0]}"
  if [ ${#candidates[@]} -gt 1 ]; then
    echo ">> multiple devices: ${candidates[*]}; using $DEVICE (pass one to override)" >&2
  fi
fi

if [ ! -e "$DEVICE" ]; then
  echo "error: $DEVICE does not exist" >&2
  exit 1
fi
if [ ! -r "$DEVICE" ]; then
  echo "error: cannot read $DEVICE (add yourself to the 'dialout' group or use sudo)" >&2
  exit 1
fi

echo ">> reading $DEVICE at $BAUD baud (Ctrl-C to stop)" >&2

# Configure the line: raw mode, 8N1, no echo, no flow control, ignore modem
# control lines (clocal) so a board reset doesn't drop the read.
stty -F "$DEVICE" "$BAUD" raw -echo cs8 -parenb -cstopb clocal -crtscts

# Stream incoming bytes to stdout.
exec cat "$DEVICE"
