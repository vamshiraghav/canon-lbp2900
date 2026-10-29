#!/bin/sh
# Create or replace the Canon LBP2900 queue. Does not change any other printer.
set -eu

QUEUE="Canon_LBP2900"
BACKEND="/usr/libexec/cups/backend/captusb"
PPD="/Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd"

if [ ! -x "$BACKEND" ] || [ ! -f "$PPD" ]; then
  echo "The LBP2900 driver files are not installed." >&2
  exit 1
fi

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  cancel -a "$QUEUE" 2>/dev/null || true
fi

# No serial is stored here. If a printer is plugged in, use the URI the
# backend reports. Otherwise leave a URI that matches the next LBP2900.
DEVICE_URI="captusb://Canon/LBP2900"
USB_URI="$("$BACKEND" 2>/dev/null | awk '$1 == "direct" && $2 ~ /^usb:\/\/Canon\/LBP2900([?]|$)/ { print $2; exit }')"
if [ -n "$USB_URI" ]; then
  DEVICE_URI="$(printf '%s\n' "$USB_URI" | sed 's#^usb://#captusb://#')"
fi

lpadmin -p "$QUEUE" -E -v "$DEVICE_URI" -P "$PPD" \
  -D "Canon LBP2900" \
  -o PageSize=A4 \
  -o Resolution=600dpi \
  -o printer-is-shared=false
cupsenable "$QUEUE"
cupsaccept "$QUEUE"

# Canon's LBP3000-era monitor holds the USB port and cannot speak CAPT 2.1.
for pid in $(ps ax -o pid=,command= | awk '/captmon/ && /LBP2900/ { print $1 }'); do
  kill "$pid" 2>/dev/null || true
done

if ! lpstat -p "$QUEUE" >/dev/null 2>&1; then
  echo "CUPS did not keep the $QUEUE queue." >&2
  exit 1
fi

echo "Canon LBP2900 is ready. Print to that queue."
