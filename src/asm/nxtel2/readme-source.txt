HOW TO BUILD NXTEL DEMO 2 (WINDOWS)
===================================

Download Zeus for Windows from http://www.desdes.com/products/oldfiles/zeustest.exe. 
Note this is an experimental version of Zeus Z80 containing some Next features. Use at your own risk, and not for regular Z80 assembly.

Unzip source.zip to a directory.
Open src\main.asm in Zeus.
Click Assemble to build.
NXtel.sna will be created in the bin directory.

Running on the Next hardware (or ZEsarUX)
-----------------------------------------

Copy NXtel.sna to your SD card.
Boot into the the Next or Next LG machine configuration.
User the broswser to find NXtel.sna, and hit ENTER to open it.
Alternatively, from BASIC do: SPECTRUM "c:/path/to/NXtel.sna".

Running in CSpect
-----------------

Copy the contents of the latest Next distro into the sd directory (this is probably where you got this demo from).
Edit the build/zesarux.bat file, and change "C:\Program Files (x86)\CSpect1_14\CSpect.exe" to the full path of your CSpect location.
Check the CSpect box in Zeus (at the bottom of the main code window) and click Assemble once more.
CSpect should start with NXTel already running.

Acknowledgements
----------------

Contains fonts stored in FZX v1.0 - a bitmap font format.
Copyright (c) 2013 Andrew Owen.

FZX is a royalty-free compact font file format designed primarily for storing
bitmap fonts for 8 bit computers, primarily the Sinclair ZX Spectrum, although
also adopting it for other platforms is welcome and encouraged!

See docs\FZX.txt for details.
