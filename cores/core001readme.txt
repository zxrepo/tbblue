Experimental secondary 128K core by Victor Trucco

What works:
PS/2 keyboard, VGA, HDMI, 1 x AY, divMMC (including esxDOS 0.8.5)

Place the core001.bit file in the root folder of your card.

Press and hold C then F1. In the core update menu select Y and let it update.
Power down and restart.

You'll boot normally but once you're in NextZXOS (or any personality you've chosen)
give: OUT 9275,16: OUT 9531,255 (must be given together)

Keys within the secondary core:

F1: Hard Reset
F4: Reset
F10: NMI menu
Space+F10 after an F1: Initialise esxDOS

You will need esxDOS 0.8.5 from www.esxdos.org



