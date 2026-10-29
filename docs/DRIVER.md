# How the driver works

The LBP2900 is a host-based laser printer. The Mac rasterizes the page. `rastertocapt` compresses it with Canon Hi-SCoA and speaks CAPT 2.1. `captusb` carries that conversation on the USB bulk pipes and returns the printer’s replies.

CAPT is bidirectional. The host sends a band, then waits until the printer has room. A one-way USB backend drops those replies, and the page never starts. Apple’s built-in `usb` backend is left installed for other printers. This driver uses a separate backend name, `captusb`, built from OpenPrinting CUPS 2.4.17’s Darwin USB code, which is the release that keeps the CAPT drain handshake from stalling.

The printer identifies itself with USB vendor `04a9`, product `2676`, and an IEEE 1284 device id whose model is `LBP2900`, command is `CAPT`, and version is `2.1`. The queue is created from whatever device the backend lists at install time. Nothing in this project hardcodes a serial number or a computer name.

Canon’s LBP3000 CAPT monitor (`cnbma2`) uses a later protocol. If that monitor is attached to an LBP2900, the installer stops that process so it releases the USB port. Other printers are not touched.
