# Canon LBP2900 for macOS

CUPS driver for the **Canon LASER SHOT / i-SENSYS LBP2900** (USB ID `04a9:2676`) on Apple Silicon.

The printer has no PCL or PostScript interpreter. It speaks Canon CAPT 2.1 over USB. Canon’s current Mac CAPT package starts at the LBP3000 and cannot drive this model.

This project is unofficial and is not affiliated with Canon.

## Install

1. Turn the printer on and connect it with USB.
2. Open `dist/Canon-LBP2900.pkg`.
3. Enter an administrator password when macOS asks.
4. Print to **Canon LBP2900**. The default paper size is A4 at 600 dpi.

The package adds only that queue. It does not change the system default printer and does not modify any other queue.

The driver is a normal set of files on the Mac. A restart does not remove it. After you log in, the Canon LBP2900 queue is still there.

To install the same driver again later, open `Canon-LBP2900.pkg` again. You do not need to build anything.

## Remove

```bash
./uninstall.sh
```

## Build the package

Apple Silicon, with Xcode or the Command Line Tools, plus Homebrew `autoconf`, `automake`, and `libtool`:

```bash
./build.sh
./package.sh
```

`build.sh` clones the commits in `sources.lock` and compiles:

- `rastertocapt` from [ValdikSS/captdriver](https://github.com/ValdikSS/captdriver)
- `captusb`, the OpenPrinting CUPS 2.4.17 USB backend, installed under its own name so Apple’s `usb` backend is left unchanged

`./install.sh` copies a local build into CUPS. The package is the installer to keep and hand to someone else.

## What gets installed

| Path | Role |
| --- | --- |
| `/usr/libexec/cups/filter/rastertocapt` | Turns a page into CAPT |
| `/usr/libexec/cups/backend/captusb` | Bidirectional USB transport |
| `/Library/Printers/PPDs/Contents/Resources/CanonLBP-2900-3000.ppd` | Paper sizes and print options |
| `/Library/Application Support/Canon LBP2900/` | Copy used to restore the files above |
| `org.capt.lbp2900.heal` | Runs once at boot and puts the files back if a macOS update removed them |

No kernel extension and no DriverKit driver. A third-party DriverKit extension cannot claim Canon’s USB vendor ID.

## License

GPL-3.0-or-later, the same license as captdriver. The USB backend is Apache-2.0, from OpenPrinting CUPS. See `LICENSE` and `THIRD_PARTY_NOTICES.md`. Source for the pinned commits is downloaded by `build.sh`; this repository does not vendor those trees.
