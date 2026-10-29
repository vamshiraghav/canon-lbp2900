#!/bin/sh
# Build the Canon LBP2900 CUPS filter and a bidirectional USB backend.
set -eu

ROOT="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
BUILD="$ROOT/build"
SRC="$BUILD/src"
OUT="$BUILD/arm64"
LOCK="$ROOT/sources.lock"
JOBS="$(sysctl -n hw.logicalcpu 2>/dev/null || echo 4)"

. "$LOCK"

for tool in git autoreconf aclocal automake autoconf make ppdc clang; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "Missing build tool: $tool" >&2
    echo "Install the autotools with: brew install autoconf automake libtool" >&2
    exit 1
  fi
done

mkdir -p "$SRC" "$OUT"

if [ ! -d "$SRC/captdriver/.git" ]; then
  git clone "$CAPT_REPOSITORY" "$SRC/captdriver"
fi
git -C "$SRC/captdriver" fetch --depth 1 origin "$CAPT_COMMIT"
git -C "$SRC/captdriver" checkout --detach "$CAPT_COMMIT"
git -C "$SRC/captdriver" reset --hard "$CAPT_COMMIT"
for patch in "$ROOT"/patches/*.patch; do
  [ -f "$patch" ] || continue
  patch -d "$SRC/captdriver" -p1 --forward --batch < "$patch"
done

echo "Building rastertocapt from captdriver $CAPT_COMMIT"
(
  cd "$SRC/captdriver"
  autoreconf -fi
  ./configure CPPFLAGS="-D_DARWIN_C_SOURCE"
  make -j"$JOBS"
  make ppd
)

if [ ! -d "$SRC/cups/.git" ]; then
  git clone --branch "$CUPS_TAG" --depth 1 "$CUPS_REPOSITORY" "$SRC/cups"
fi
git -C "$SRC/cups" fetch --depth 1 origin "$CUPS_COMMIT"
git -C "$SRC/cups" checkout --detach "$CUPS_COMMIT"

CUPS_HEAD="$(git -C "$SRC/cups" rev-parse HEAD)"
if [ "$CUPS_HEAD" != "$CUPS_COMMIT" ]; then
  echo "CUPS checkout is $CUPS_HEAD, expected $CUPS_COMMIT" >&2
  exit 1
fi

echo "Building captusb from OpenPrinting CUPS $CUPS_TAG ($CUPS_COMMIT)"
CUPS_STAGE="$BUILD/cups-stage"
# Darwin USB, not libusb. Apple's own usb backend does not return CAPT
# replies; this is the OpenPrinting 2.4.17 Darwin backend, installed under
# another name so Apple's backend stays in place.
(
  cd "$SRC/cups"
  ./configure --prefix="$CUPS_STAGE" --disable-gssapi --disable-libusb
  make -C cups libcups.a -j"$JOBS"
  make -C cups libcups.2.dylib -j"$JOBS"
  make -C backend usb -j"$JOBS"
)

install_name_tool -change "$CUPS_STAGE/lib/libcups.2.dylib" \
  /usr/lib/libcups.2.dylib "$SRC/cups/backend/usb"

codesign -f -s - "$SRC/captdriver/src/rastertocapt"
codesign -f -s - "$SRC/cups/backend/usb"

cp "$SRC/captdriver/src/rastertocapt" "$OUT/rastertocapt"
cp "$SRC/cups/backend/usb" "$OUT/captusb"
cp "$SRC/captdriver/ppd/CanonLBP-2900-3000.ppd" "$OUT/CanonLBP-2900-3000.ppd"

file "$OUT/rastertocapt" "$OUT/captusb"
echo "Built $OUT"
