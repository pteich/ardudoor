Ardudoor - Arduino powered door opener
======================================

Ardudoor is a small and low-cost Arduino project to to unlock two doors using an Intranet website.
There's no need to remain a computer turned on all the time if this can be achieved more efficient with a small
microcontroller electronic device.

This version uses a LCD for additional status information and DS1820 1-Wire temperature sensor (without any need, just for fun).

Ardudoor obtains its IP address with DHCP and displays it on LCD. It then serves a simple web-frontend with buttons to open the doors and the current temperature.

Attention, there's no further security to allow only authorized users access to Ardudoor. It is meant to be used in a secure intranet.

Electronic parts
--------------------------------------
- Arduino (Duemilanove, Uno or any other)
- Ethernet shield
- DS1820 1-Wire temperature sensor
- 2x16 LCD display (parallel interface with Hitachi HD44780 compatible driver)
- 2 small relays (in my case 12 V versions because I found them on my desk)
- 2 diodes (e.g. 1N4004 or any other)
- 2 NPN transistors (e.g. 2N2222)
- 2 1k Ohm resistors
- some wires, perfboard or stripboard or custom made PCB

Arduino Libraries
---------------------------------------
- SPI
- Ethernet
- OneWire
- EthernetDHCP (http://gkaindl.com/software/arduino-ethernet/dhcp)
- DallasTemperature (http://milesburton.com/Dallas_Temperature_Control_Library)
- LiquidCrystal



