# README #

This is the code repository for the XBlast's Xbox Legal "OS".

It is a replacement firmware or "BIOS" to run on the Original Xbox video game console. It also serves as software control interface for the "Xblast" line of modding devices for Xbox.

This code is based on the excellent Gentoox Loader software which is based on Cromwell.
#### This software contains no copyrighted code ####
#### This software cannot circumvent security mechanism of an Xbox console ####

## RAM testing

256MB and 128MB RAM tests are supported within the BIOS menus. There is also a special **RAMTESTER** version of the BIOS which checks the original 4 RAM chips in either a `Stock` machine or an Xbox with `256Mbit` memory.

### RAMTESTER version

Press power button to start the test. Press eject to launch Xblast OS as usual.

There is no video output - the test result is seen on the LED.

If the Xbox reboots 3 times and then the LEDs blink red and green, then suspect RAM bank 1.

If the Xbox shuts off super quickly (LEDs don't light, fan twitches) then you probably have a short circuit.

LED codes:

* Test completed, no failures = green blinking
* RAM bank 1 test stuck = orange blinking
* RAM bank 2 test stuck = red, off, green, off
* RAM bank 3 test stuck = red and green slow
* RAM bank 4 test stuck = orange and green fast
* RAM bank 1 failed = LEDs off
* RAM bank 2 failed = red blinking
* RAM bank 3 failed = red, orange, off
* RAM bank 4 failed = red, green, orange, off

RAM chip bank locations can be found [here](RAM locations/Stock memory chip locations.jpg).

### 128MB and 256MB tests

These are the normal tests available via the Tools menu in Xblast OS. RAM chip bank locations can be found [here](RAM locations/Extended memory chip locations.jpg).

### Required setup to build ###

x86 or x86_64 Linux system with gcc installed

ia32 compatiblity layer packages must also be installed on x86_64 systems

Currently building successfully with gcc-9.

Windows users can use WSL.

### Who do I talk to? ###

* Prehistoricman on OGXbox/xbox-scene forums
* bennydiamond on AssemblerGames forums
* psyko_chewbacca on XBMC4Xbox forums


### Implemented features ###

This project is available in both "BIOS" and "XBE"(Xbox executable) form. The features for the 2 versions are not all the same. Generally speaking, the XBE version contains less feature.

Also note that this software can detect if a firmware replacement device is inserted onto the LPC port. Certain options specifically related to XBlast Mod will not be available if the proper hardware is not detected. However, HD44780 LCD ouput is supported on the whole range of SmartXX devices and on Xecuter 3(CE).

Notable feature available on both versions are:

* Change video settings (includes DVD,Game and Video region).
* 128MB and 256MB RAM tester
* Reset user settings in Xbox EEPROM
* Flash LPC/TSOP with image from HDD/CD/HTTP (limited to current bank on non XBlast mod)
* Lock/Unlock HDD, Display HDD info, format drives (64KB clusters supported)

Notable features only available in BIOS version

* LCD ouput supported on all SmartXX/Xecuter3 and XBlast mod
* Save OS settings and backup eeprom to flash (not supported on SmartXX)

Notable features only available on XBlast mod

* Control multiple flash banks
* Custom names for flash banks(outputs on LCD too)
* Quickboot bank(bypass OS)
* TSOP control for multiple BIOS banks (Xbox 1.0/1.1 only).

