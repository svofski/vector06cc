This is a quick and dirty adaptation of TinyUSB HID example.

TODO: everything. But it works well already.

Prerequisites 
=============
 * pico-sdk (on Windows install pico-sdk under WSL2)
 * picotool (picotool.exe is a part of arduino rp2040 package)

Building
========
```
mkdir build && cd build && cmake ..
picotool load v06c_usbhid.elf
```

The OTG connector will now accept a USB keyboard, or at least some of them. 

Connection diagram
==================

UART TX pin is GP0. Gowin RX pin is 25. They can be connected directly with a wire.
The 5V power for the pipico and connected devices is leeched from VBUS. 

Tang Nano9K pinout: https://wiki.sipeed.com/hardware/en/tang/Tang-Nano-9K/Nano-9K.html
RP2040-Zero pinout: https://www.waveshare.com/rp2040-zero.htm

                          _____
                     +---| OTG |---+
to Nano9K 5V pin <-- o 5V      GP0 o --> to Nano9K pin 25 (IOB8A)
                 |-- o GND     GP1 o
                     o             o
                         .  ..  .



