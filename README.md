tanklights
==========

Tanklights is a fun project for adding moonlight lighting effects to a fish tank, or other environment where having an undulating lighting effect is desirable.  When properly laid out, the lighting is meant to be a rough simulation of what moonlight might look like under water.

The hardware/LEDs are wired up in a charlieplexed format.  Using just 3 pins of the micro controller (an Atmel ATTiny13), 6 LEDs can be individually controller.

The formula for the total number of LEDs is given by n^2-n, where n is the number of pins.  So, 3^2-3 = 6.

Read more about charlieplexing here: https://en.wikipedia.org/wiki/Charlieplexing

The lighting effects are accomplished by very fast switching of the LED matrix, so that persistence of vision plays a key role in the apparent light levels of the LEDs.

## building
The project has a simple Makefile.  It is currently configured to compiled under Linux only (but could be easily modified for other operating systems).  You will need to install AVRA, which is the open source equivalent of the Atmel AVR Assembler, avrasm.exe, that is included with AVR Studio for Windows.

### AVRA
Avra can also be installed easily on Linux:  `apt install -y avra` for Debian based systems.  The AVRA project home is here: http://avra.sourceforge.net/

### Atmel AVR Assembler
http://www.atmel.com/webdoc/avrassembler/index.html


### Other notes
The main idea with this project is not to build yet another LED blinking hello-world type of application, but is more a demonstration of what you can build using assembly and very lower powered micro-controllers.  Current code size is 640 bytes, or 320 words.  The timers on the ATTiny13 are used to advance or cycle through the lighting pattern, while the main charlieplexing display driver code is left to run at full speed.

