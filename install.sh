#!/bin/sh
# Install from a local build. The package in dist/ is the same driver.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/build/arm64"

for file in "$OUT/rastertocapt" "$OUT/captusb" "$OUT/CanonLBP-2900-3000.ppd"; do
  if [ ! -f "$file" ]; then
    echo "Missing $file. Run ./build.sh first." >&2
    exit 1
  fi
done

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

echo "Installing the CAPT filter, USB backend, and PPD."
as_root install -o root -g wheel -m 755 "$OUT/rastertocapt" /usr/libexec/cups/filter/rastertocapt
as_root install -o root -g wheel -m 700 "$OUT/captusb" /usr/libexec/cups/backend/captusb
as_root mkdir -p /Library/Printers/PPDs/Contents/Resources
as_root install -o root -g wheel -m 644 "$OUT/CanonLBP-2900-3000.ppd" \
  /Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd

SUPPORT="/Library/Application Support/Canon LBP2900"
as_root mkdir -p "$SUPPORT"
as_root install -o root -g wheel -m 755 "$OUT/rastertocapt" "$SUPPORT/rastertocapt"
as_root install -o root -g wheel -m 700 "$OUT/captusb" "$SUPPORT/captusb"
as_root install -o root -g wheel -m 644 "$OUT/CanonLBP-2900-3000.ppd" "$SUPPORT/CanonLBP-2900-3000.ppd"
as_root install -o root -g wheel -m 755 "$ROOT/scripts/setup-queue.sh" "$SUPPORT/setup-queue.sh"
as_root install -o root -g wheel -m 755 "$ROOT/scripts/heal.sh" "$SUPPORT/heal.sh"
as_root install -o root -g wheel -m 644 "$ROOT/package/org.capt.lbp2900.heal.plist" \
  /Library/LaunchDaemons/org.capt.lbp2900.heal.plist

as_root /bin/sh "$SUPPORT/setup-queue.sh"

PLIST="/Library/LaunchDaemons/org.capt.lbp2900.heal.plist"
as_root launchctl bootout system "$PLIST" 2>/dev/null || true
as_root launchctl bootstrap system "$PLIST" 2>/dev/null || as_root launchctl load -w "$PLIST"
