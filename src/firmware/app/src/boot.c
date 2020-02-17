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
#include "ff.h"
#include "misc.h"
#include "config.h"
#include "fwfile.h"
#include "videotest.h"

FATFS		FatFs;		/* FatFs work area needed for each volume */
FIL		Fil;		/* File object needed for each open file */
FRESULT		res;

unsigned char * FW_version = "1.22";

// minimal required for this FW
unsigned long minimal = 0x030100; // 03 01 00 = 3.01.00
unsigned long current = 0;

unsigned char t[256];

const char *filename;
static unsigned char	mach_id, l;
static unsigned char	opc = 0;
static unsigned int	bl = 0, cont;
static unsigned char	temp_byte = 0;


void error_loading(char e)
{
	switch (e)
	{
		case 'O':
			vdp_prints("unable to open!");
			break;
		case 'R':
			vdp_prints("error reading!");
			break;
		default:
			vdp_prints("unknown error!");
			break;
	}

	ULAPORT = COLOR_RED;
	for(;;);
}

void load_and_start()
{
	//turn off the debug led
	LED = 1;

	REG_NUM = REG_RAMPAGE;

	filename = 0;

	if (settings[eSettingDivMMC] == 1)
	{
		filename = ESXMMC_FILE;
	}

	if (pMenu->divmmc_romfile[0])
	{
		filename = pMenu->divmmc_romfile;
	}

	if (filename) {
		vdp_prints("Loading ESXMMC:\n");
		vdp_prints(filename);
		vdp_prints("...");
		strcpy(temp, NEXT_DIRECTORY);
		strcat(temp, filename);
		res = f_open(&Fil, temp, FA_READ);
		if (res != FR_OK) {
			error_loading('O');
		}
		REG_VAL = RAMPAGE_ROMDIVMMC;
		res = f_read(&Fil, (unsigned char *)0, 8192, &bl);
		if (res != FR_OK || bl != 8192) {
			error_loading('R');
		}
		f_close(&Fil);
		vdp_prints("OK!\n");
		REG_VAL = RAMPAGE_RAMDIVMMC;
		__asm__("ld hl, #0\n");		// Zeroing RAM DivMMC
		__asm__("ld de, #1\n");
		__asm__("ld bc, #16383\n");
		__asm__("ld (hl), l\n");
		__asm__("ldir\n");
	}

	filename = 0;

	if (settings[eSettingMF] == 1) {
		switch ( pMenu->mode ) {
			case 0:
				filename = MF1_FILE;
			break;

			case 1:
				filename = MF128_FILE;
			break;

			case 2:
				filename = MF3_FILE;
			break;

			case 3: // Pentagon
				filename = MF128_FILE;
			break;
		}
	}

	if (pMenu->mf_romfile[0])
	{
		filename = pMenu->mf_romfile;
	}

	if (filename) {
		vdp_prints("Loading Multiface ROM:\n");
		vdp_prints(filename);
		vdp_prints("...");
		strcpy(temp, NEXT_DIRECTORY);
		strcat(temp, filename);
		res = f_open(&Fil, temp, FA_READ);
		if (res != FR_OK) {
			error_loading('O');
		}
		REG_VAL = RAMPAGE_ROMMF;
		res = f_read(&Fil, (unsigned char *)0, 8192, &bl);
		if (res != FR_OK || bl != 8192) {
			error_loading('R');
		}
		f_close(&Fil);
		vdp_prints("OK!\n");
	}

	filename = pMenu->romfile;

	vdp_prints("Loading ROM:\n");
	vdp_prints(filename);
	vdp_prints("...");

	// Load 16K
	strcpy(temp, NEXT_DIRECTORY);
	strcat(temp, filename);
	res = f_open(&Fil, temp, FA_READ);
	if (res != FR_OK) {
		error_loading('O');
	}
	REG_VAL = RAMPAGE_ROMSPECCY;
	res = f_read(&Fil, (unsigned char *)0, 16384, &bl);
	if (res != FR_OK || bl != 16384) {
		error_loading('R');
	}
	// If Speccy > 48K, load more 16K
	if (pMenu->mode > 0) {
		REG_VAL = RAMPAGE_ROMSPECCY+1;
		res = f_read(&Fil, (unsigned char *)0, 16384, &bl);
		if (res != FR_OK || bl != 16384) {
			error_loading('R');
		}
	}
	// If +2/+3e, load more 32K
	if (pMenu->mode == 2) {

		REG_VAL = RAMPAGE_ROMSPECCY+2;
		res = f_read(&Fil, (unsigned char *)0, 16384, &bl);
		if (res != FR_OK || bl != 16384) {
			error_loading('R');
		}
		REG_VAL = RAMPAGE_ROMSPECCY+3;
		res = f_read(&Fil, (unsigned char *)0, 16384, &bl);
		if (res != FR_OK || bl != 16384) {
			error_loading('R');
		}
	}
	f_close(&Fil);
	vdp_prints("OK!\n");

	REG_NUM = REG_PERIPH4;
	opc = settings[eSettingScanlines] & 3;			// bits 1-0
	REG_VAL = opc;

	REG_NUM = REG_MACHTYPE;
	REG_VAL = (pMenu->mode + 1);

	REG_NUM = REG_RESET;
	REG_VAL = RESET_SOFT;				// Soft-reset

	for(;;);
}

void check_coreversion()
{
	REG_NUM = REG_MACHID;
	mach_id = REG_VAL;

	if (mach_id == HWID_EMULATORS)
	{
		return;
	}

        current = get_core_ver();

	if (current < minimal)
	{

		vdp_cls();
		vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
		vdp_prints(TITLE);

		vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_LGREEN);

		if (current == 0)
		{
			vdp_gotoxy(11, 3);
			vdp_prints("Anti-Brick\n\n\n");

			vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);
			vdp_prints("No " NEXT_UPDATE_FILE2 " update file found!");

			for (;;);
		}

		vdp_gotoxy(4, 3);
		vdp_prints ("Please update your core!\n\n\n");
		vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);

		vdp_prints(  "You need at least core  v");
		sprintf(t, "%lu.%02lu.%02lu", (minimal >> 16) & 0xff, (minimal >> 8) & 0xff, minimal & 0xff);
		vdp_prints(t);

		vdp_prints("\nYou currently have core v");
		sprintf(t, "%lu.%02lu.%02lu", (current >> 16) & 0xff, (current >> 8) & 0xff, current & 0xff);
		vdp_prints(t);

		vdp_prints("\n\n\nHold U to enter the updater now\n");
		vdp_prints(      " if you have copied the latest\n");
		vdp_prints(      "  TBBLUE.TBU to your SD card\n");

		ULAPORT = COLOR_RED;
		for(;;)
		{
			if ((HROW5 & 0x08) == 0)
			{
				REG_NUM = REG_RESET;
				REG_VAL = 0x02;	// hard reset to loader
			}
		}
	}
}

void display_bootscreen()
{
	// Load TBBLUE.FW at 14MHz
	REG_NUM = REG_TURBO;
	REG_VAL = 2;

	// Load the boot screen.
	switch (mach_id)
	{
		case HWID_ZXNEXT:
			l = FW_BLK_NEXT_SCR;
			break;
		case HWID_ZXDOS:
			l = FW_BLK_ZXDOS_SCR;
			break;
		default:
			l = FW_BLK_TBBLUE_SCR;
			break;
	}

	fwOpenAndSeek(l);
	fwRead((unsigned char *)0x4000, 6912);
	fwClose();

	current = get_core_ver();

	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);

	vdp_gotoxy(1, 16);
	vdp_prints("For video mode selection press:");
	vdp_gotoxy(1, 17);
	vdp_prints("A=all, D=Digital, V=VGA, R=RGB");

	vdp_gotoxy(15, 21);
	vdp_prints("Firmware v");
	vdp_prints(FW_version);

	vdp_gotoxy(19, 22);
	vdp_prints("Core v");
	sprintf(t, "%lu.%02lu.%02lu", (current >> 16) & 0xff, (current >> 8) & 0xff, current & 0xff);
	vdp_prints(t);

	// Revert to standard 3.5MHz
	REG_NUM = REG_TURBO;
	REG_VAL = 0;
}

void init_registers()
{
	// Set machine type
	REG_NUM = REG_MACHTYPE;
	REG_VAL = (pMenu->mode + 1) << 4 | 0x80;

	// Set peripheral config.
	REG_NUM = REG_PERIPH1;
	opc = ((settings[eSettingJoystick1] & 3) << 6)
		| ((settings[eSettingJoystick2] & 3) << 4);	// bits 7-6 and 5-4 (joysticks LSBs)
	if (settings[eSettingJoystick1] & 4)	opc |= 0x08;	// bit 3 = joystick 1 MSB
	if (settings[eSettingFreq5060])		opc |= 0x04;	// bit 2
	if (settings[eSettingJoystick2] & 4)	opc |= 0x02;	// bit 1 = joystick 2 MSB
	if (settings[eSettingScandoubler])	opc |= 0x01;	// bit 0
	REG_VAL = opc;

	REG_NUM = REG_PERIPH2;
	opc = settings[eSettingPSGMode]; 			// bits 1-0
	if (settings[eSettingTurboKey])		opc |= 0x80;	// bit 7
	if (settings[eSettingDMA])		opc |= 0x40;	// bit 6
	if (settings[eSettingDivMMC])		opc |= 0x10;	// bit 4
	if (settings[eSettingMF])		opc |= 0x08;	// bit 3
	if (settings[eSettingPS2])		opc |= 0x04;	// bit 2
	REG_VAL = opc;

	REG_NUM = REG_PERIPH3;
	opc = 0;
	if (settings[eSettingStereoMode])	opc |= 0x20;	// bit 5
	if (settings[eSettingIntSnd])		opc |= 0x10;	// bit 4
	if (settings[eSettingCovox])		opc |= 0x08;	// bit 3
	if (settings[eSettingTimex])		opc |= 0x04;	// bit 2
	if (settings[eSettingTurboSound])	opc |= 0x02;	// bit 1
	if (settings[eSettingIss23])		opc |= 0x01;	// bit 0
	REG_VAL = opc;

	REG_NUM = REG_PERIPH4;
	opc = settings[eSettingScanlines] & 3;			// bits 1-0
	REG_VAL = opc;
}

void load_keymap()
{
	// Read and send Keymap
	strcpy(temp, NEXT_DIRECTORY);
	strcat(temp, KEYMAP_FILE);
	vdp_prints("Loading keymap:\n");
	vdp_prints(KEYMAP_FILE);
	vdp_prints("...");
	res = f_open(&Fil, temp, FA_READ);
	if (res != FR_OK) {
		error_loading('O');
	}
	REG_NUM = REG_KMHA;
	REG_VAL = 0;
	REG_NUM = REG_KMLA;
	REG_VAL = 0;
	for (l = 0; l < 4; l++) {
		res = f_read(&Fil, line, 256, &bl);
		if (res != FR_OK || bl != 256) {
			error_loading('R');
		}
		cont = 0;
		while (cont < 256) {
			REG_NUM = REG_KMHD;
			REG_VAL = line[cont++];
			REG_NUM = REG_KMLD;
			REG_VAL = line[cont++];
		}
	}
	f_close(&Fil);
	vdp_prints("OK!\n");
}

void main()
{
	vdp_init();
	disable_bootrom();

	// Read config.ini
	load_config();
	pMenu = &(menus[settings[eSettingMenuDefault]]);

	// Cycle through the modes if necessary
	if (videoTestActive())
	{
		// If a mode is chosen at this point it will also
		// override any menu line "override" for this boot. This
		// is useful if the default line won't display because of
		// an override.
		videoTestCycle();
	}
	else
	{
		// Honour the current scandoubler, 50/60Hz and scanline settings.
		update_video_settings();
	}

	// Show the boot screen
	check_coreversion();
	display_bootscreen();

	for(cont=0;cont<0x1fff;cont++)
	{
		if ((cont & 0x7ff) == 0)
		{
			vdp_gotoxy(5, 13);
			if ((cont & 0x800) == 0)
			{
				vdp_prints("Press SPACEBAR for menu\n");
			}
			else
			{
				vdp_prints("                       \n");
			}
		}

		if ((HROW7 & 0x01) == 0)
		{
			// Reboot to loader if SPACE is pressed.
			// This will load the editor module.
			REG_NUM = REG_RESET;
			REG_VAL = RESET_HARD;
		}

		if (videoTestActive())
		{
			// Enter video test if A/V/D/R pressed.
			videoTestCycle();
			break;
		}

		if ( ((HROW0 & 0x04) == 0) &&
		     ((HROW7 & 0x08) == 0) )
		{
			// If N,X held down, reset config.ini to defaults.
			reset_settings();
			save_config();
			vdp_cls();
			vdp_gotoxy(3, 3);
			vdp_prints("Settings reset to defaults!\n\n");
			vdp_gotoxy(7, 7);
			vdp_prints("Turn the power off");
			for (;;);
		}
	}

	// Clear off the video mode selection prompts.
	vdp_gotoxy(1, 16);
	vdp_prints("                               ");
	vdp_gotoxy(1, 17);
	vdp_prints("                               ");
	vdp_gotoxy(0, 10);

	// Perform remaining boot operations at 14MHz
	REG_NUM = REG_TURBO;
	REG_VAL = 2;

	// Force MF and/or DivMMC if ROMs were specified.
	if (pMenu->mf_romfile[0])
	{
		if (strncmp(pMenu->mf_romfile, "<none>", 6) == 0)
		{
			settings[eSettingMF] = 0;
			pMenu->mf_romfile[0] = 0;
		}
		else
		{
			settings[eSettingMF] = 1;
		}
	}

	if (pMenu->divmmc_romfile[0])
	{
		if (strncmp(pMenu->divmmc_romfile,"<none>", 6) == 0)
		{
			settings[eSettingDivMMC] = 0;
			pMenu->divmmc_romfile[0] = 0;
		}
		else
		{
			settings[eSettingDivMMC] = 1;
		}
	}

	init_registers();
	load_keymap();
	load_and_start();
}
