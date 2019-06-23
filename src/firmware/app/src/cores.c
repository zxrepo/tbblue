/*
TBBlue / ZX Spectrum Next project

Copyright (c) 2015 Fabio Belavenuto & Victor Trucco

Fixes and enhancements since v1.05: Garry Lancaster

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "hardware.h"
#include "vdp.h"
#include "ffro.h"			// read-only
#include "spi.h"
#include "misc.h"
#include "config.h"

#define NEXT_CORE_FILE   "CORE001.BIT"

const char ce[5]   = "\\|/-";

// EPCS4 cmds
const unsigned char cmd_write_enable	= 0x06;
const unsigned char cmd_write_disable	= 0x04;
const unsigned char cmd_read_status		= 0x05;
const unsigned char cmd_read_bytes		= 0x03;
const unsigned char cmd_read_id			= 0xAB;
const unsigned char cmd_fast_read		= 0x0B;
const unsigned char cmd_write_status	= 0x01;
const unsigned char cmd_write_bytes		= 0x02;
const unsigned char cmd_erase_bulk		= 0xC7;
const unsigned char cmd_erase_block64	= 0xD8;		// Block Erase 64K

FATFS		FatFs;		/* FatFs work area needed for each volume */
FIL		Fil;		/* File object needed for each open file */
FRESULT		res;

unsigned char	t[256], buffer[512];
unsigned char	mach_id, mach_version,mach_version_sub;
unsigned char 	mach_ab = 0;
unsigned char 	cLed = 0;
unsigned char	l, file_mach_id, file_mach_version, vma, vmi, cs, csc;
unsigned int	bl, i, j;
unsigned long	fsize, dsize;


static unsigned char wait_resp() {
	unsigned char r = 0;
	unsigned char bts = 0;

	REG_NUM = REG_ANTIBRICK;

	while (1) {
		// key Y
		if ((HROW5 & (1 << 4)) == 0) {
			r = 2;
			while(!(HROW1 & 0x02));
			break;
		}
		// key N
		if ((HROW7 & (1 << 3)) == 0) {
			r = 3;
			while(!(HROW7 & 0x08));
			break;
		}

		bts = REG_VAL;


		if ( bts & 1 > 0) //MF button, same as N
		{
			r = 3;
			break;
		}

		if ( bts & 2 > 0) //Drive button, same as Y
		{
			r = 2;
			break;
		}


	}
	return r;
}

void main() {

	//turn off the debug cLed
	REG_NUM = REG_DEBUG;
	REG_VAL = 0;

	REG_NUM = REG_TURBO;
	REG_VAL = 0;

	REG_NUM = REG_MACHID;
	mach_id = REG_VAL;
	REG_NUM = REG_VERSION;
	mach_version = REG_VAL;

	REG_NUM = REG_VERSION_SUB;
	mach_version_sub = REG_VAL;


	if (mach_id == HWID_ZXNEXT_AB)
	{
		//can't work with AB, so hang
		while (1){}
	}

	vdp_init();

	// Read config.ini and honour the video settings.
	load_config();
	update_video_settings();

	vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
	vdp_prints(TITLE);


		vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_LGREEN);
		vdp_gotoxy(7, 2);
		vdp_prints("Extra Cores Updater\n\n");


	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);


	memset(buffer, 0, 512);

	f_mount(&FatFs, "", 0);				/* Give a work area to the default drive */

	res = f_open(&Fil, NEXT_CORE_FILE, FA_READ);

	if (res != FR_OK)
	{
		display_error("Error opening " NEXT_CORE_FILE " file");
	}

	f_close(&Fil);


	vdp_setfg(COLOR_WHITE);

	vdp_gotoxy(16,16);

	l = 0;
	for(i=0;i<1500;i++) // Wait a little
	{
		vdp_putchar(ce[l]);
		vdp_putchar(8);
		l = (l + 1) & 0x03;
	};

	vdp_gotoxy(1,16);

	vdp_prints("Do you want to upgrade? (y/n)");

	//turn on the debug cLed
	LED = 0;

	if (wait_resp() != 2 ) {
		REG_NUM = REG_RESET;
		REG_VAL = RESET_HARD;			// Hard-reset
	}
	vdp_prints("y\n\n");


	// Read flash ID
	// EPCS4     = 0x12
	// W25Q32BV  = 0x15
	// W25Q128JV = 0x17
	buffer[0] = cmd_read_id;
	l = SPI_send4bytes_recv(buffer);

	//if (l != 0x12 && l != 0x15 && l != 0x17)
	if ( l != 0x15 && l != 0x17 )
	{
		display_error("Flash not detected!");
	}

//	sprintf(t, "detected 0x%02x\n", l);
//	vdp_prints(t);




	REG_NUM = REG_DEBUG;


	vdp_prints("Erasing Flash: ");

	if (mach_id == HWID_ZXNEXT)
	{

		buffer[0] = cmd_erase_block64;
		buffer[1] = 0x10; // 0x100000 - first core sector
		buffer[2] = 0x00;
		buffer[3] = 0x00;

		for (i = 0; i < 8; i++)
		{
			SPI_sendcmd(cmd_write_enable);
			SPI_send4bytes(buffer); // send the command to erase a 64kb block
			++buffer[1]; // next 64kb block
			while ((SPI_sendcmd_recv(cmd_read_status) & 0x01) == 1) ;

			//repeat 8 times, to erase a 512kb block
		}
	}


	l = 0;
	while ((SPI_sendcmd_recv(cmd_read_status) & 0x01) == 1) {
		vdp_putchar(ce[l]);
		vdp_putchar(8);
		l = (l + 1) & 0x03;

		//blink the debug cLed
		if (cLed == 0) cLed = 1; else cLed = 0; LED = cLed;

		for (i = 0; i < 5000; i++) ;
	}

	vdp_prints(" OK\n");
	vdp_prints("Writing Flash: ");

	f_mount(&FatFs, "", 0);				/* Give a work area to the default drive */
	res = f_open(&Fil, NEXT_CORE_FILE, FA_READ);
	if (res != FR_OK) {
		display_error("Error opening '" NEXT_CORE_FILE "' file!");
	}



		dsize = 0x100000; // 0x100000 - first core sector



	l = 0;
	while (!f_eof(&Fil))
	{
		buffer[0] = cmd_write_bytes;
		buffer[1] = (dsize >> 16) & 0xFF;
		buffer[2] = (dsize >> 8) & 0xFF;
		buffer[3] = dsize & 0xFF;

		res = f_read(&Fil, buffer+4, 256, &bl);

		// the last block NOT EQUAL 256 - TO DO!!!
		//if (res != FR_OK || bl != 256)
		//{
		//	display_error("Error reading block!");
		//}

		SPI_sendcmd(cmd_write_enable);
		SPI_writebytes(buffer);
		vdp_putchar(ce[l]);
		vdp_putchar(8);
		l = (l + 1) & 0x03;

		while ((SPI_sendcmd_recv(cmd_read_status) & 0x01) == 1);

		dsize += 256;

		//blink the debug cLed
		if (cLed == 0) cLed = 1; else cLed = 0; LED = cLed;
	}
	vdp_prints(" OK\n");

	// Protect Flash
/*	if (mach_id == HWID_ZXNEXT) {
		SPI_sendcmd(cmd_write_enable);
		buffer[0] = cmd_write_status;
		buffer[1] = 0x30;
		buffer[2] = 0x02;
		SPI_send3bytes(buffer);
	}
*/
	SPI_sendcmd(cmd_write_disable);

	vdp_cls();
	vdp_gotoxy(0, 5);
	vdp_gotox(13);
	vdp_prints("Updated!\n\n");
	vdp_gotox(4);
	vdp_prints("Turn the power off and on.");

	//turn off the debug cLed
	LED = 1;

	f_close(&Fil);


	for(;;);
}
