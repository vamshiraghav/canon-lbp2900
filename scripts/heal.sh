#!/bin/sh
# Restore driver files if a macOS update removed them. Safe to run more than once.
set -eu

SUPPORT="/Library/Application Support/Canon LBP2900"
FILTER="/usr/libexec/cups/filter/rastertocapt"
BACKEND="/usr/libexec/cups/backend/captusb"
PPD="/Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd"
QUEUE="Canon_LBP2900"

install_file() {
  src="$1"
  dst="$2"
  mode="$3"
  if [ ! -e "$dst" ]; then
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
    chown root:wheel "$dst"
    chmod "$mode" "$dst"
  fi
}

install_file "$SUPPORT/rastertocapt" "$FILTER" 755
install_file "$SUPPORT/captusb" "$BACKEND" 700
install_file "$SUPPORT/CanonLBP-2900-3000.ppd" "$PPD" 644

if ! lpstat -p "$QUEUE" >/dev/null 2>&1; then
  /bin/sh "$SUPPORT/setup-queue.sh"
fi
