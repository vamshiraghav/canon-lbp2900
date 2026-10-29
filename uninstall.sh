#!/bin/sh
# Remove the LBP2900 queue and the files this driver installed.
# Leaves every other printer, and Canon's own software, in place.
set -eu

QUEUE="Canon_LBP2900"
PLIST="/Library/LaunchDaemons/org.capt.lbp2900.heal.plist"

as_root() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

as_root launchctl bootout system "$PLIST" 2>/dev/null || true

if lpstat -p "$QUEUE" >/dev/null 2>&1; then
  cancel -a "$QUEUE" 2>/dev/null || true
  as_root lpadmin -x "$QUEUE"
fi

as_root rm -f \
  /usr/libexec/cups/filter/rastertocapt \
  /usr/libexec/cups/backend/captusb \
  /Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd \
  "$PLIST"
as_root rm -rf "/Library/Application Support/Canon LBP2900"

echo "Removed the Canon LBP2900 queue and driver files."
