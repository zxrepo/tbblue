-include ../../Config.mk
-include ../../Config2.mk

PREFIX ?= arm-none-eabi-
FLASHBAUD ?= 115200

ARMGNU ?= $(PREFIX)

COPS = -Wall -O2 -nostdlib -nostartfiles -ffreestanding -DDEFAULTBAUD=$(FLASHBAUD)

all: nextload.img

clean :
	rm -f *.o
	rm -f *.elf
	rm -f *.lst
	rm -f nextload.img

vectors.o : vectors.s
	$(ARMGNU)as vectors.s -o vectors.o

nextload.o : nextload.c BCM2835.h periph.h uart.h
	$(ARMGNU)gcc $(COPS) -c nextload.c -o nextload.o -DAARCH=32

periph.o : periph.c BCM2835.h periph.h uart.h
	$(ARMGNU)gcc $(COPS) -c periph.c -o periph.o -DAARCH=32

uart.o : uart.c BCM2835.h periph.h uart.h
	$(ARMGNU)gcc $(COPS) -c uart.c -o uart.o -DAARCH=32

stage3.img :
	make -C "../stage3"
	cp ../stage2/Nextccel.img stage3.img

stage3.bin : stage3.img
	tail -c +5 stage3.img > stage3.bin

nextload.img : loader vectors.o periph.o uart.o nextload.o stage3.bin
	$(ARMGNU)ld vectors.o periph.o uart.o nextload.o -T loader -o nextload.elf
	$(ARMGNU)objcopy nextload.elf -O binary nextload.img

install : nextload.img
	@cp -v nextload.img /Volumes/boot/nextccel.img


# Original "stage1" code taken from "bootloader creation" 
#  at https://github.com/rsta2/circle/tree/master/tools/bootloader
# Original Licence: GPLv3 
# This Licence:     GPLv3
