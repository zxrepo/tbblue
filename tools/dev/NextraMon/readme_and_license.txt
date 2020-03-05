Nextramon is (c) 1982 - 2020 by Simon N Goodwin. Latest version 
is always located at: simon.mooli.org.uk/nextech/index.html

Nextramon is released under the CC-BY-NC-SA version 4 License
(https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode)

Nextramon - semi-intelligent disassembler and memory monitor
============================================================

Nextramon.bas - a NextBASIC disassembler and memory monitor, 
capable of disassembling all the Z80N instructions including 
Nextras, Floating point calculator (FPC) language codes, 
Sinclair reports and Interface 1, GDOS and Unidos hook codes. 
Memory areas can also be displayed as text, hex or decimal.

This is a major update and bugfix for Spectramon, a Z80 
disassembler written in ZX BASIC first published in ZX Computing
 magazine. Simon wrote the original on his new Spectrum in 1982, 
in a three-day marathon attempt to get to grips with keyword 
entry and adapt from TRS-80 BASIC.

The original program was documented and listed in the April/May
and June/July 1983 issues of ZX Computing, and later sold on 
cassette by Argus Press Software. Just for good measure, Argus 
also ran it, over nine pages, in the Spring 1984 issue of 
Personal Software magazine. An extended version for Sam Coupe 
appeared in issue 33 of the Sam Supplement disc magazine.

The Next version is faster (though still not as fast as a 
disassembler written well in machine code - select 28 MHz 
clock speed or type RUN AT 3 before running it, to take full 
advantage of the Next's optional CPU acceleration). It still 
gives nonsensical results, like any disassembler, if you 
disassemble memory that does not contain valid Z80 code. You can
avoid this by checking with the A or N options. Adresses may be
entered in decimal or hex - add a H suffix if the hex address 
contains no letters, to avoid ambiguity.

Nextramon automatically switches between Z80N and FPC machine 
language byte encodings after a RST 56 instruction which 
switches the Spectrum to expect FPC code, but sometimes FPC 
code is entered directly via a branch from other FPC code. 
The F option allows you to start disassembly in FPC mode, 
whereas D defaults to Z80N instructions. FPC code is extensively
used in the original Spectrum ROM and generated code from ZX 
compilers that support Sinclair's five-byte floating point 
format. The rendering of embedded floating-point constants in 
FPC code is still a bit ragged - please let Simon know if you
find problems with this, or (better still) fixes!

Nextramon uses Timex 2068 hires mode (Layer 1,3) for a 65-column
display. It supports the Alphacom and ZX printers, and possibly 
other printers which are compatible with NextBASIC. Once again, 
I recommend you run this with your Next accelerated to 28 MHz as
it's written in NextBASIC and so quite slow at the original 
Spectrum clock rate.