#
# Makefile
#

CIRCLEHOME = ../../../../circle

OBJS	= main.o Nextccel.o kernel.o

LIBS	= $(CIRCLEHOME)/lib/libcircle.a \
		  $(CIRCLEHOME)/lib/fs/fat/libfatfs.a \
		  $(CIRCLEHOME)/lib/fs/libfs.a \
		  $(CIRCLEHOME)/addon/SDCard/libsdcard.a \
		  ../libs/unlib/libunlib.a

include $(CIRCLEHOME)/Rules.mk

-include $(DEPS)

minicom: flash
	minicom -o


# Original "stage1" code taken from "bootloader creation" 
#  at https://github.com/rsta2/circle/tree/master/app/template
# Original Licence: GPLv3 
# This Licence:     GPLv3
