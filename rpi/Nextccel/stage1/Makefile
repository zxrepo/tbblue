#
# Download the firmware files to be required for boot (requires wget)
#
# These files must be copied along with the generated kernel.img
#     onto a SD(HC) card with FAT file system.
#

# Use most recent firmware test revision
#FIRMWARE = master

# Use firmware revision built/committed on: Feb 12 2020
FIRMWARE ?= f4b58692fef0b9c16bd4564edb980fff73a758b3

BASEURL = https://github.com/raspberrypi/firmware/blob/$(FIRMWARE)/boot

firmware: 
	rm -f fixup*.dat start*.elf armstub*.bin LICENCE.broadcom COPYING.linux
	wget -q -O LICENCE.broadcom $(BASEURL)/LICENCE.broadcom?raw=true
	wget -q -O COPYING.linux $(BASEURL)/COPYING.linux?raw=true
	wget -q -O fixup.dat $(BASEURL)/fixup.dat?raw=true
	wget -q -O start.elf $(BASEURL)/start.elf?raw=true

all: firmware 

clean:
	rm -f fixup*.dat start*.elf kernel*.img armstub*.bin LICENCE.broadcom COPYING.linux
	make clean -C "../stage2"
	make clean -C armstub

# Original "stage1" code taken from "bootloader creation" 
#  at https://github.com/rsta2/circle/tree/master/boot
# Original Licence: GPLv3 
# This Licence:     GPLv3
