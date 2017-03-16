tanklights
==========

Tanklights is a fun project for adding moonlight lighting effects to a fish tank, or other environment where having an undulating lighting effect is desirable.  When properly laid out, the lighting is meant to be a rough simulation of what moonlight might look like under water.

The hardware/LEDs are wired up in a charlieplexed format.  Using just 3 pins of the micro controller (an Atmel ATTiny13), 6 LEDs can be individually controller.

The formula for the total number of LEDs is given by n^2-n, where n is the number of pins.  So, 3^2-3 = 6.

Read more about charlieplexing here: https://en.wikipedia.org/wiki/Charlieplexing

The lighting effects are accomplished by very fast switching of the LED matrix, so that persistence of vision plays a key role in the apparent light levels of the LEDs.

