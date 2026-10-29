#!/bin/sh
# Build dist/Canon-LBP2900.pkg from the binaries produced by ./build.sh.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
OUT="$ROOT/build/arm64"
STAGE="$ROOT/build/pkg-root"
SUPPORT="$STAGE/Library/Application Support/Canon LBP2900"
DIST="$ROOT/dist"

for file in "$OUT/rastertocapt" "$OUT/captusb" "$OUT/CanonLBP-2900-3000.ppd"; do
  if [ ! -f "$file" ]; then
    echo "Missing $file. Run ./build.sh first." >&2
    exit 1
  fi
done

rm -rf "$STAGE" "$ROOT/build/CanonLBP2900-component.pkg"
mkdir -p \
  "$STAGE/usr/libexec/cups/filter" \
  "$STAGE/usr/libexec/cups/backend" \
  "$STAGE/Library/Printers/PPDs/Contents/Resources" \
  "$STAGE/Library/LaunchDaemons" \
  "$SUPPORT" \
  "$DIST"

cp "$OUT/rastertocapt" "$STAGE/usr/libexec/cups/filter/rastertocapt"
cp "$OUT/captusb" "$STAGE/usr/libexec/cups/backend/captusb"
cp "$OUT/CanonLBP-2900-3000.ppd" "$STAGE/Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd"
cp "$OUT/rastertocapt" "$SUPPORT/rastertocapt"
cp "$OUT/captusb" "$SUPPORT/captusb"
cp "$OUT/CanonLBP-2900-3000.ppd" "$SUPPORT/CanonLBP-2900-3000.ppd"
cp "$ROOT/scripts/setup-queue.sh" "$SUPPORT/setup-queue.sh"
cp "$ROOT/scripts/heal.sh" "$SUPPORT/heal.sh"
cp "$ROOT/package/org.capt.lbp2900.heal.plist" "$STAGE/Library/LaunchDaemons/org.capt.lbp2900.heal.plist"

chmod 755 \
  "$STAGE/usr/libexec/cups/filter/rastertocapt" \
  "$SUPPORT/rastertocapt" \
  "$SUPPORT/setup-queue.sh" \
  "$SUPPORT/heal.sh" \
  "$ROOT/package/scripts/postinstall"
chmod 700 "$STAGE/usr/libexec/cups/backend/captusb" "$SUPPORT/captusb"
chmod 644 \
  "$STAGE/Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd" \
  "$SUPPORT/CanonLBP-2900-3000.ppd" \
  "$STAGE/Library/LaunchDaemons/org.capt.lbp2900.heal.plist"

pkgbuild \
  --root "$STAGE" \
  --scripts "$ROOT/package/scripts" \
  --identifier org.capt.lbp2900 \
  --version 1.0.0 \
  --ownership recommended \
  --install-location / \
  "$ROOT/build/CanonLBP2900-component.pkg"

productbuild \
  --distribution "$ROOT/package/Distribution.xml" \
  --resources "$ROOT/package" \
  --package-path "$ROOT/build" \
  "$DIST/Canon-LBP2900.pkg"

rm -f "$ROOT/build/CanonLBP2900-component.pkg"
echo "Wrote $DIST/Canon-LBP2900.pkg"
