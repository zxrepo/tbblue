/*
TBBlue / ZX Spectrum Next project

Copyright (c) 2015 Fabio Belavenuto & Victor Trucco

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
#include "config.h"
#include "ff.h"

/* Defines */

//                    12345678901234567890123456789012
const char TITLE[] = "         TBBLUE BOOT ROM        ";

/* Variables */
FATFS		FatFs;		/* FatFs work area needed for each volume */
FIL			Fil, Fil2;	/* File object needed for each open file */
FRESULT		res;

unsigned char * FW_version = " 1.10b"; 

// minimal required for this FW 
unsigned long minimal = 0x010A2F; // 01 0A 2F = 1.10.47
unsigned long current = 0;

unsigned char scandoubler = 1;
unsigned char freq5060 = 0;
unsigned char timex   = 0;
unsigned char psgmode = 0;
unsigned char divmmc = 1;
unsigned char mf = 1;
unsigned char joystick1 = 0;
unsigned char joystick2 = 0;
unsigned char ps2 = 0;
//unsigned char alt_ps2 = 0;
unsigned char lightpen = 0;
unsigned char scanlines = 0;
unsigned char menu_default = 0;
unsigned char menu_cont = 0;
unsigned char config_changed = 0;
unsigned char dac = 0;
unsigned char ena_turbo = 1;
unsigned char turbosound = 0;
unsigned char covox = 0;
unsigned char intsnd = 0;
unsigned char stereomode = 0;
unsigned char t[256];

unsigned short tv50_visible_h  = 0;
unsigned short tv50_hsync_sta  = 0;
unsigned short tv50_hsync_end  = 0;
unsigned short tv50_cnt_h_end  = 0;
unsigned short tv50_visible_v  = 0;
unsigned short tv50_vsync_sta  = 0;
unsigned short tv50_vsync_end  = 0;
unsigned short tv50_cnt_v_end  = 0;
unsigned short tv60_visible_h  = 0;
unsigned short tv60_hsync_sta  = 0;
unsigned short tv60_hsync_end  = 0;
unsigned short tv60_cnt_h_end  = 0;
unsigned short tv60_visible_v  = 0;
unsigned short tv60_vsync_sta  = 0;
unsigned short tv60_vsync_end  = 0;
unsigned short tv60_cnt_v_end  = 0;

unsigned short ula50_hblnk_sta = 0;
unsigned short ula50_hsync_sta = 0;
unsigned short ula50_hsync_end = 0;
unsigned short ula50_hblnk_end = 0;
unsigned short ula50_cnt_h_end = 0;
unsigned short ula50_vblnk_sta = 0;
unsigned short ula50_vsync_sta = 0;
unsigned short ula50_vsync_end = 0;
unsigned short ula50_vblnk_end = 0;
unsigned short ula50_cnt_v_end = 0;
unsigned short ula60_hblnk_sta = 0;
unsigned short ula60_hsync_sta = 0;
unsigned short ula60_hsync_end = 0;
unsigned short ula60_hblnk_end = 0;
unsigned short ula60_cnt_h_end = 0;
unsigned short ula60_vblnk_sta = 0;
unsigned short ula60_vsync_sta = 0;
unsigned short ula60_vsync_end = 0;
unsigned short ula60_vblnk_end = 0;
unsigned short ula60_cnt_v_end = 0;

static unsigned char 	*mem = (unsigned char *)0x4000;
static char				line[256], temp[256], buffer[512], *filename;
static char				romesxmmc[14] = ESXMMC_FILE, romm1[14] = MF1_FILE, romm128[14] = MF128_FILE, romm3[14] = MF3_FILE;
static char				*comma1, *comma2, *comma3, *comma4, *comma5;
static char				titletemp[32];
static char				romfile[14];
static unsigned char	mach_id, mach_version_major, mach_version_minor, mach_version_sub, l, found = 0;
static unsigned char	opc = 0;
static unsigned int		bl = 0, cont, initial_block, blocks;
static unsigned char	video_timing = 0;
static unsigned char	mode = 0;
static unsigned char	temp_byte = 0;

/* Private functions */

/*******************************************************************************/
void display_error(const unsigned char *msg)
{
	l = 16 - strlen(msg)/2;

	vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);
	vdp_cls();
	vdp_setcolor(COLOR_RED, COLOR_BLUE, COLOR_WHITE);
	vdp_setflash(0);
	vdp_prints(TITLE);
	vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);
	vdp_setflash(1);
	vdp_gotoxy(l, 12);
	vdp_prints(msg);
	ULAPORT = COLOR_RED;
	for(;;);
}

/*******************************************************************************/
void error_loading(char e)
{
	vdp_prints("ERROR!!");
	vdp_putchar(e);
	ULAPORT = COLOR_RED;
	for(;;);
}

/*******************************************************************************/
void prints_help()
{
//                       11111111112222222222333
//              12345678901234567890123456789012
	vdp_prints("  F1      - Hard Reset\n");
	vdp_prints("  F2      - Toggle scandoubler\n");
	vdp_prints("  F3      - Toggle 50/60 Hz\n");
	vdp_prints("  F4      - Soft Reset\n");
	vdp_prints("  F7      - Toggle scanlines\n");
	vdp_prints("  F8      - Toggle turbo\n");
	vdp_prints("  F9      - Multiface button\n");
	vdp_prints("  F10     - DivMMC button\n");
	vdp_prints("  SHIFT   - Caps Shift\n");
	vdp_prints("  CONTROL - Symbol Shift\n");
	vdp_prints("\n");
	vdp_prints("  Hold SPACE while power-up or\n");
	vdp_prints("  on Hard Reset to start\n");
	vdp_prints("  the configurator.\n");
	vdp_prints("\n");
}

/*******************************************************************************/
void load_timings()
{
	long i=0;
	unsigned int error_count = 5;
	
	vdp_prints("Reading TIMING.INI...");


LOADTIMING:
	--error_count;
	
	res = f_open(&Fil, TIMING_FILE, FA_READ);
	if (res != FR_OK) {
		if (error_count > 0) {
			goto LOADTIMING;
		}
		//             12345678901234567890123456789012
		display_error("Error opening 'timing.ini'!");
	}

	// Read configuration
	while(f_eof(&Fil) == 0) {
		if (!f_gets(line, 255, &Fil)) {
			if (error_count > 0) {
				goto LOADTIMING;
			}
			//             12345678901234567890123456789012
			display_error("Error reading timings!");
		}
		if (line[0] == ';')
			continue;

		line[strlen(line)-1] = '\0';
		
		// TV Timing - 50 HZ
		if ( strncmp ( line, "tv50_visible_h=", 15) == 0) 
		{
			tv50_visible_h = atoi( line + 15 ) - 1;
		} 
		else if ( strncmp ( line, "tv50_hsync_sta=", 15) == 0) 
		{
			tv50_hsync_sta = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv50_hsync_end=", 15) == 0) 
		{
			tv50_hsync_end = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv50_cnt_h_end=", 15) == 0) 
		{
			tv50_cnt_h_end = atoi( line + 15 ) - 1;	
		} 
		//------------------
		else if ( strncmp ( line, "tv50_visible_v=", 15) == 0) 
		{
			tv50_visible_v = atoi( line + 15 ) - 1;
		} 
		else if ( strncmp ( line, "tv50_vsync_sta=", 15) == 0) 
		{
			tv50_vsync_sta = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv50_vsync_end=", 15) == 0) 
		{
			tv50_vsync_end = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv50_cnt_v_end=", 15) == 0) 
		{
			tv50_cnt_v_end = atoi( line + 15 ) - 2;	
		} 

		// TV Timing - 60 HZ
		else if ( strncmp ( line, "tv60_visible_h=", 15) == 0) 
		{
			tv60_visible_h = atoi( line + 15 ) - 1;
		} 
		else if ( strncmp ( line, "tv60_hsync_sta=", 15) == 0) 
		{
			tv60_hsync_sta = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv60_hsync_end=", 15) == 0) 
		{
			tv60_hsync_end = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv60_cnt_h_end=", 15) == 0) 
		{
			tv60_cnt_h_end = atoi( line + 15 ) - 1;	
		} 
		//------------------
		else if ( strncmp ( line, "tv60_visible_v=", 15) == 0) 
		{
			tv60_visible_v = atoi( line + 15 ) - 1;
		} 
		else if ( strncmp ( line, "tv60_vsync_sta=", 15) == 0) 
		{
			tv60_vsync_sta = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv60_vsync_end=", 15) == 0) 
		{
			tv60_vsync_end = atoi( line + 15 ) - 1;	
		} 
		else if ( strncmp ( line, "tv60_cnt_v_end=", 15) == 0) 
		{
			tv60_cnt_v_end = atoi( line + 15 ) - 2;	
		} 
		// ULA Timing - 50 Hz
		else if ( strncmp ( line, "ula50_hblnk_sta=", 16) == 0) 
		{
			ula50_hblnk_sta = atoi( line + 16 );
		} 
		else if ( strncmp ( line, "ula50_hsync_sta=", 16) == 0) 
		{
			ula50_hsync_sta = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula50_hsync_end=", 16) == 0) 
		{
			ula50_hsync_end = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula50_hblnk_end=", 16) == 0) 
		{
			ula50_hblnk_end = atoi( line + 16 );	
		} 	
		else if ( strncmp ( line, "ula50_cnt_h_end=", 16) == 0) 
		{
			ula50_cnt_h_end = atoi( line + 16 ) - 1;	
		} 
		//------------------
		else if ( strncmp ( line, "ula50_vblnk_sta=", 16) == 0) 
		{
			ula50_vblnk_sta = atoi( line + 16 );
		} 
		else if ( strncmp ( line, "ula50_vsync_sta=", 16) == 0) 
		{
			ula50_vsync_sta = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula50_vsync_end=", 16) == 0) 
		{
			ula50_vsync_end = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula50_vblnk_end=", 16) == 0) 
		{
			ula50_vblnk_end = atoi( line + 16 );	
		} 	
		else if ( strncmp ( line, "ula50_cnt_v_end=", 16) == 0) 
		{
			ula50_cnt_v_end = atoi( line + 16 ) - 1;	
		} 
		// ULA Timing - 60 Hz
		else if ( strncmp ( line, "ula60_hblnk_sta=", 16) == 0) 
		{
			ula60_hblnk_sta = atoi( line + 16 );
		} 
		else if ( strncmp ( line, "ula60_hsync_sta=", 16) == 0) 
		{
			ula60_hsync_sta = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula60_hsync_end=", 16) == 0) 
		{
			ula60_hsync_end = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula60_hblnk_end=", 16) == 0) 
		{
			ula60_hblnk_end = atoi( line + 16 );	
		} 	
		else if ( strncmp ( line, "ula60_cnt_h_end=", 16) == 0) 
		{
			ula60_cnt_h_end = atoi( line + 16 ) - 1;	
		} 
		//------------------
		else if ( strncmp ( line, "ula60_vblnk_sta=", 16) == 0) 
		{
			ula60_vblnk_sta = atoi( line + 16 );
		} 
		else if ( strncmp ( line, "ula60_vsync_sta=", 16) == 0) 
		{
			ula60_vsync_sta = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula60_vsync_end=", 16) == 0) 
		{
			ula60_vsync_end = atoi( line + 16 );	
		} 
		else if ( strncmp ( line, "ula60_vblnk_end=", 16) == 0) 
		{
			ula60_vblnk_end = atoi( line + 16 );	
		} 	
		else if ( strncmp ( line, "ula60_cnt_v_end=", 16) == 0) 
		{
			ula60_cnt_v_end = atoi( line + 16 ) - 1;	
		} 

	}
	f_close(&Fil);

	vdp_prints(" OK\n");

	
/*	vdp_prints("vh: ");
	sprintf(t, "%d\n", tv50_visible_h);
	vdp_prints(t);

	vdp_prints("vh1: ");
	sprintf(t, "%d\n", tv50_visible_h& 0xff);
	vdp_prints(t);

	vdp_prints("vh2: ");
	sprintf(t, "%d\n", tv50_visible_h>>8);
	vdp_prints(t);	
*/
	
	REG_NUM = REG_VIDEOREG;

	//------------- TV
	// ---- 50 Hz
	REG_VAL = tv50_visible_h & 0xff;
	REG_VAL = tv50_visible_h >> 8;
	
	REG_VAL = tv50_hsync_sta & 0xff;
	REG_VAL = tv50_hsync_sta >> 8;

	REG_VAL = tv50_hsync_end & 0xff;
	REG_VAL = tv50_hsync_end >> 8;

	REG_VAL = tv50_cnt_h_end & 0xff;
	REG_VAL = tv50_cnt_h_end >> 8;

	REG_VAL = tv50_visible_v & 0xff;
	REG_VAL = tv50_visible_v >> 8;
	
	REG_VAL = tv50_vsync_sta & 0xff;
	REG_VAL = tv50_vsync_sta >> 8;

	REG_VAL = tv50_vsync_end & 0xff;
	REG_VAL = tv50_vsync_end >> 8;

	REG_VAL = tv50_cnt_v_end & 0xff;
	REG_VAL = tv50_cnt_v_end >> 8;

	// ---- 60 Hz
	REG_VAL = tv60_visible_h & 0xff;
	REG_VAL = tv60_visible_h >> 8;
	
	REG_VAL = tv60_hsync_sta & 0xff;
	REG_VAL = tv60_hsync_sta >> 8;

	REG_VAL = tv60_hsync_end & 0xff;
	REG_VAL = tv60_hsync_end >> 8;

	REG_VAL = tv60_cnt_h_end & 0xff;
	REG_VAL = tv60_cnt_h_end >> 8;

	REG_VAL = tv60_visible_v & 0xff;
	REG_VAL = tv60_visible_v >> 8;
	
	REG_VAL = tv60_vsync_sta & 0xff;
	REG_VAL = tv60_vsync_sta >> 8;

	REG_VAL = tv60_vsync_end & 0xff;
	REG_VAL = tv60_vsync_end >> 8;

	REG_VAL = tv60_cnt_v_end & 0xff;
	REG_VAL = tv60_cnt_v_end >> 8;
	
	//------------- ULA
	// ---- 50 Hz
	REG_VAL = ula50_hblnk_sta & 0xff;
	REG_VAL = ula50_hblnk_sta >> 8;

	REG_VAL = ula50_hsync_sta & 0xff;
	REG_VAL = ula50_hsync_sta >> 8;

	REG_VAL = ula50_hsync_end & 0xff;
	REG_VAL = ula50_hsync_end >> 8;

	REG_VAL = ula50_hblnk_end & 0xff;
	REG_VAL = ula50_hblnk_end >> 8;

	REG_VAL = ula50_cnt_h_end & 0xff;	
	REG_VAL = ula50_cnt_h_end >> 8;

			
	REG_VAL = ula50_vblnk_sta & 0xff;
	REG_VAL = ula50_vblnk_sta >> 8;

	REG_VAL = ula50_vsync_sta & 0xff;
	REG_VAL = ula50_vsync_sta >> 8;

	REG_VAL = ula50_vsync_end & 0xff;
	REG_VAL = ula50_vsync_end >> 8;

	REG_VAL = ula50_vblnk_end & 0xff;
	REG_VAL = ula50_vblnk_end >> 8;

	REG_VAL = ula50_cnt_v_end & 0xff;	
	REG_VAL = ula50_cnt_v_end >> 8;

	// ---- 60 Hz
	REG_VAL = ula60_hblnk_sta & 0xff;
	REG_VAL = ula60_hblnk_sta >> 8;

	REG_VAL = ula60_hsync_sta & 0xff;
	REG_VAL = ula60_hsync_sta >> 8;

	REG_VAL = ula60_hsync_end & 0xff;
	REG_VAL = ula60_hsync_end >> 8;

	REG_VAL = ula60_hblnk_end & 0xff;
	REG_VAL = ula60_hblnk_end >> 8;

	REG_VAL = ula60_cnt_h_end & 0xff;	
	REG_VAL = ula60_cnt_h_end >> 8;

	REG_VAL = ula60_vblnk_sta & 0xff;
	REG_VAL = ula60_vblnk_sta >> 8;

	REG_VAL = ula60_vsync_sta & 0xff;
	REG_VAL = ula60_vsync_sta >> 8;

	REG_VAL = ula60_vsync_end & 0xff;
	REG_VAL = ula60_vsync_end >> 8;

	REG_VAL = ula60_vblnk_end & 0xff;
	REG_VAL = ula60_vblnk_end >> 8;

	REG_VAL = ula60_cnt_v_end & 0xff;	
	REG_VAL = ula60_cnt_v_end >> 8;
	
}

/*******************************************************************************/
void load_and_start()
{
	
	//turn off the debug led
	LED = 1;
	
	REG_NUM = REG_RAMPAGE;
	if (divmmc == 1) {
		vdp_prints("Loading ESXMMC:\n");
		vdp_prints(romesxmmc);
		vdp_prints(" ... ");
		strcpy(temp, NEXT_DIRECTORY);
		strcat(temp, romesxmmc);
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
		__asm__("ld a, #0\n");			// Zeroing RAM DivMMC
		__asm__("ld hl, #0\n");
		__asm__("ld de, #1\n");
		__asm__("ld bc, #16383\n");
		__asm__("ldir\n");
	}

	if (mf == 1) {
		switch ( mode ) {
			case 0:
				filename = romm1;
			break;

			case 1:
				filename = romm128;
			break;

			case 2:
				filename = romm3;
			break;


			case 3: // Pentagon
				filename = romm128;
			break;
		}

		vdp_prints("Loading Multiface ROM:\n");
		vdp_prints(filename);
		vdp_prints(" ... ");
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

	vdp_prints("Loading ROM:\n");
	vdp_prints(romfile);
	vdp_prints(" ... ");

	// Load 16K
	strcpy(temp, NEXT_DIRECTORY);
	strcat(temp, romfile);
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
	if (mode > 0) {
		REG_VAL = RAMPAGE_ROMSPECCY+1;
		res = f_read(&Fil, (unsigned char *)0, 16384, &bl);
		if (res != FR_OK || bl != 16384) {
			error_loading('R');
		}
	}
	// If +2/+3e, load more 32K
	//if (mode > 1) {
	if (mode == 2) {

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
	
	REG_NUM = REG_MACHTYPE;
//	REG_VAL = (mode+1) << 3 | (mode+1);	// Set machine (and timing)
	REG_VAL = (mode+1);
	
	//REG_NUM = REG_VIDEOT;
	//REG_VAL = video_timing; 
	
	REG_NUM = REG_RESET;
	REG_VAL = RESET_SOFT;				// Soft-reset
	
	for(;;);
}

/* Public functions */

/*******************************************************************************/
unsigned long get_fattime()
{
	return 0x44210000UL;
}

/*******************************************************************************/
void main()
{
	long i=0;
	unsigned int error_count = 100;

//	vdp_init();
/*	vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
	vdp_prints(TITLE);
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);*/

	vdp_setflash(0);

	REG_NUM = REG_MACHTYPE;
	REG_VAL = 0;	// disable bootrom
	
	REG_NUM = REG_MACHID;
	mach_id = REG_VAL;
	
	REG_NUM = REG_VERSION;
	mach_version_major = REG_VAL;
	
	mach_version_minor = mach_version_major & 0x0F;
	mach_version_major = (mach_version_major >> 4) & 0x0F; 
	
	REG_NUM = REG_VERSION_SUB;
	mach_version_sub = REG_VAL;
	
	current = (mach_version_major*65536) + (mach_version_minor*256) + mach_version_sub;
	
	
/*
	vdp_gotoxy(0,2);
	prints_help();
*/
	for( cont = 0; cont < 1000; cont++ );	

START:
	--error_count;
	f_mount(&FatFs, "", 0);		/* Give a work area to the default drive */


	res = f_open(&Fil, NEXT_FIRMWARE_FILE2, FA_READ);
	if (res != FR_OK) {
		if (error_count > 0) {
			goto START;
		}
		//             12345678901234567890123456789012
		display_error( "Error opening TBBLUE.FW file" );
	}
	
	error_count = 100;

	res = f_read(&Fil, buffer, 512, &bl);
	if (res != FR_OK || bl != 512) {
		error_loading('F');
	}
	
	
	// load the boot screen. The default is the TBBLUE at block 4
	l = 4; //3
	
	if (mach_id == HWID_ZXNEXT) 
	{
		l = 5; //4 // if its the Next, the block is 5
	}
	
	initial_block = buffer[l * 4]     + buffer[l * 4 + 1] * 256;
	blocks        = buffer[l * 4 + 2] + buffer[l * 4 + 3] * 256;
	blocks *= 512;
	cont = 0;
	
	// Skip blocks
	while (cont < initial_block) {
		res = f_read(&Fil, buffer, 512, &bl);
		if (res != FR_OK || bl != 512) {
			error_loading('F');
		}
		++cont;
	}

	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_BLACK);

	res = f_read(&Fil, mem, blocks, &bl);
	if (res != FR_OK || bl != blocks) {
		error_loading('F');
	}

	f_close(&Fil);

	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);

	vdp_gotoxy(14, 21); 
	vdp_prints("Firmware v.");
	vdp_prints(FW_version);

	vdp_gotoxy(12, 22);
	vdp_prints("    Core v.");
	sprintf(t, "%d.%02d.%02d", mach_version_major, mach_version_minor, mach_version_sub);
	vdp_prints(t);

	for(cont=0;cont<5000;cont++);			// Wait a little

	vdp_gotoxy(5, 13);
	vdp_prints("Press SPACEBAR for menu\n");

	for(cont=0;cont<30000;cont++) 
	{
		if ((HROW7 & 0x01) == 0) 
		{
			REG_NUM = REG_RESET;
			REG_VAL = RESET_HARD;
		}
	}

	//clean the spacebar message
	vdp_gotoxy(5, 13);
	vdp_prints("                       \n");

	vdp_gotoxy(0, 10);

	res = f_open(&Fil, CONFIG_FILE, FA_READ);
	
	if (res != FR_OK) 
	{
		//if (error_count > 0) {
		//	goto START;
		//}
		//             12345678901234567890123456789012
		display_error("Error opening 'config.ini'!");
	}

	// Read configuration
	while(f_eof(&Fil) == 0) 
	{
		if (!f_gets(line, 255, &Fil)) 
		{
			//if (error_count > 0) {
			//	goto START;
			//}
			//             12345678901234567890123456789012
			display_error("Error reading configuration!");
		}
		
		if (line[0] == ';')
			continue;
		
		line[strlen(line)-1] = '\0';
		
		if ( strncmp ( line, "scandoubler=", 12) == 0) 
		{
			scandoubler = CLAMP(atoi ( line + 12), MAX_SCANDOUBLER);
		} 
		else if ( strncmp ( line, "50_60hz=", 8) == 0) 
		{
			freq5060 = CLAMP(atoi ( line + 8), MAX_FREQ5060);
		} 
		else if ( strncmp ( line, "timex=", 6) == 0) 
		{
			timex = CLAMP(atoi ( line + 6), MAX_TIMEX);
		} 
		else if ( strncmp ( line, "psgmode=", 8) == 0) 
		{
			psgmode = CLAMP(atoi ( line + 8), MAX_PSGMODE);
		} 
		else if ( strncmp ( line, "intsnd=", 7) == 0) 
		{
			intsnd = CLAMP(atoi ( line + 7), MAX_INTSND);
		}
 		else if ( strncmp ( line, "stereomode=", 11) == 0) 
		{
			stereomode = CLAMP(atoi ( line + 11 ), MAX_STEREOMODE);
		} 
		else if ( strncmp ( line, "turbosound=", 11) == 0) 
		{
			turbosound = CLAMP(atoi ( line + 11 ), MAX_TURBOSOUND);
		} 
		else if ( strncmp ( line, "covox=", 6) == 0) 
		{
			covox = CLAMP(atoi ( line + 6), MAX_COVOX);
		} 
		else if ( strncmp ( line, "divmmc=", 7) == 0) 
		{
			divmmc = CLAMP(atoi ( line + 7), MAX_DIVMMC);
		} 
		else if ( strncmp ( line, "mf=", 3) == 0) 
		{
			mf = CLAMP(atoi ( line + 3), MAX_MF);
		} 
		else if ( strncmp ( line, "joystick1=", 10) == 0) 
		{
			joystick1 = CLAMP(atoi ( line + 10), MAX_JOYSTICK1);
		} 
		else if ( strncmp ( line, "joystick2=", 10) == 0) 
		{
			joystick2 = CLAMP(atoi ( line + 10), MAX_JOYSTICK2);
		} 
		else if ( strncmp ( line, "ps2=", 4) == 0) 
		{
			ps2 = CLAMP(atoi ( line + 4), MAX_PS2);
		} 
//		else if ( strncmp ( line, "alternativePS2=", 15) == 0) 
//		{
//			alt_ps2 = atoi ( line + 15);
//		} 
		else if ( strncmp ( line, "lightpen=", 9) == 0) 
		{
			lightpen = CLAMP(atoi ( line + 9), MAX_LIGHTPEN);
		} 
		else if ( strncmp ( line, "scanlines=", 10) == 0) 
		{
			scanlines = CLAMP(atoi ( line + 10), MAX_SCANLINES);
		} 
		else if ( strncmp ( line, "dac=", 4) == 0) 
		{
			dac = CLAMP(atoi ( line + 4), MAX_DAC);
		} 
		else if ( strncmp ( line, "turbo=", 6) == 0) 
		{
			ena_turbo = CLAMP(atoi ( line + 6), MAX_TURBO);
		} 
		else if ( strncmp ( line, "default=", 8) == 0) 
		{
			menu_default = atoi ( line + 8);
		} 
		else if ( strncmp ( line, "menu=", 5) == 0) 
		{
			if (menu_cont != menu_default) 
			{
				++menu_cont;
				continue;
			}
			++menu_cont;

			comma1 = strchr(line, ',');
			
			if (comma1 == 0)
			{
				continue;
			}
			
			memset(temp, 0, 255);
			memcpy(temp, line+5, (comma1-line-5));
			strcpy(titletemp, temp);
			++comma1;

			comma2 = strchr(comma1, ',');
			
			if (comma2 == 0) 
			{
				continue;
			}
			
			memset(temp, 0, 255);
			memcpy(temp, comma1, (comma2-comma1));
			mode = atoi(temp);
			++comma2;	
			
			comma3 = strchr(comma2, ',');
			
			if (comma3 == 0) 
			{
				continue;
			}

			/* A valid line specified by default has been found */
			found = 1;
			
			memset(temp, 0, 255);
			memcpy(temp, comma2, (comma3-comma2));
			video_timing = atoi(temp);
			++comma3;

			comma4 = strchr(comma3, ',');
			
			if (comma4 != 0) 
			{
				// Force load and enable of DivMMC ROM
				// if specified on selected menu line
				divmmc = 1;

				memset(temp, 0, 255);
				memcpy(temp, comma3, (comma4-comma3));

				strcpy(romfile, temp); // main ROM

				++comma4;

				comma5 = strchr(comma4, ',');
				if (comma5 != 0)
				{
					// Force load and enable of MF ROM
					// if specified on selected menu line
					mf = 1;

					memset(temp, 0, 255);
					memcpy(temp, comma4, (comma5-comma4));

					strcpy(romesxmmc, temp); // divMMC ROM

					comma5++;

					// Multiface ROM
					switch (mode)
					{
						case 0: // 48K
							strcpy(romm1, comma5);
							break;
						case 1:	// 128K
						case 3: // Pentagon
							strcpy(romm128, comma5);
							break;
						case 2: // +3
							strcpy(romm3, comma5);
							break;
					}
				}
				else
				{
					strcpy(romesxmmc, comma4); // divMMC ROM
				}
			}
			else
			{
				strcpy(romfile, comma3); // main ROM
			}
		}
	}
	f_close(&Fil);


	
	if (menu_cont == 0) {
		//if (error_count > 0) {
		//	goto START;
		//}
		//             12345678901234567890123456789012
		display_error("No configuration read!");
	}
	if (!found) {
		//if (error_count > 0) {
		//	goto START;
		//}
		//             12345678901234567890123456789012
		display_error("Error in configuration!");
	}
	// Check joysticks combination
/*	if ((joystick1 == 1 && joystick2 == 1) ||
		(joystick1 == 2 && joystick2 == 2) ||
		(joystick1 == 0 && joystick2 == 2)) {
		joystick2 = 0;
	}
*/
	// Set timing
	REG_NUM = REG_MACHTYPE;
	REG_VAL = (mode+1) << 4 | 0x80;
	
	REG_NUM = REG_VIDEOT;
	REG_VAL = video_timing | 0x80; 

	// Set peripheral config.
	REG_NUM = REG_PERIPH1;
	opc = ((joystick1 & 3) << 6)  | ((joystick2 & 3) << 4);	// bits 7-6 and 5-4 (joysticks LSBs)
	if (joystick1 & 4)  opc |= 0x08;		// bit 3 = joystick 1 MSB
	if (freq5060)    	opc |= 0x04;		// bit 2
	if (joystick2 & 4)  opc |= 0x02;		// bit 1 = joystick 2 MSB
	if (scandoubler) 	opc |= 0x01;		// bit 0
	REG_VAL = opc;

	REG_NUM = REG_PERIPH2;
	opc = psgmode; 						// bits 1-0
	if (ena_turbo)   opc |= 0x80;		// bit 7
	if (dac)         opc |= 0x40;		// bit 6
	if (lightpen)    opc |= 0x20;		// bit 5
	if (divmmc)      opc |= 0x10;		// bit 4
	if (mf)          opc |= 0x08;		// bit 3
	if (ps2)         opc |= 0x04;		// bit 2
	REG_VAL = opc;

	REG_NUM = REG_PERIPH3;
	opc = 0;
//	if (alt_ps2)  	 opc |= 0x40;		// bit 6
	if (stereomode)  opc |= 0x20;		// bit 5
	if (intsnd)      opc |= 0x10;		// bit 4
	if (covox)       opc |= 0x08;		// bit 3
	if (timex)       opc |= 0x04;		// bit 2
	if (turbosound)  opc |= 0x02;		// bit 1
	REG_VAL = opc;
	
	REG_NUM = REG_PERIPH4;
	opc = scanlines & 3; // bits 1-0
	REG_VAL = opc;
	

	// Read and send Keymap
	strcpy(temp, NEXT_DIRECTORY);
	strcat(temp, KEYMAP_FILE);
	res = f_open(&Fil, temp, FA_READ);
	if (res != FR_OK) {
		error_loading('K');
	}
	REG_NUM = REG_KMHA;
	REG_VAL = 0;
	REG_NUM = REG_KMLA;
	REG_VAL = 0;
	for (l = 0; l < 4; l++) {
		res = f_read(&Fil, line, 256, &bl);
		if (res != FR_OK || bl != 256) {
			error_loading('M');
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

	//if (video_timing ==7) load_timings();
	
		
	if (current < minimal) 
	{
		
		vdp_setcolor(COLOR_RED, COLOR_BLACK, COLOR_WHITE);
		vdp_cls();

		vdp_gotoxy(0, 9);
		vdp_prints ("    Please update your core!\n\n");
		
		vdp_prints("You need TBU v. ");
		sprintf(t, "%lu.%02lu.%02lu", (minimal >> 16) & 0xff, (minimal >> 8) & 0xff, minimal & 0xff);
		vdp_prints(t);
		vdp_prints(" or later\n");		
		
		vdp_prints("    The current is v.");
		sprintf(t, "%d.%02d.%02d", mach_version_major, mach_version_minor, mach_version_sub);
		vdp_prints(t);
		
		ULAPORT = COLOR_RED;
		for(;;);
	}
	

	load_and_start();
}
