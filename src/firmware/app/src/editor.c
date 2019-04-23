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
#include "ff.h"				// read/write

/* Defines */

#define LI_ITENS 4
#define DEBUG_CONFIG 0
#define ERR_CHECK(x) if (res == FR_OK) { res = x; }
#define ERR_CHECK_PF(x) if (res == FR_OK) { res = (x<0) ? FR_DISK_ERR : FR_OK; }


typedef struct {
	unsigned char type;
	unsigned char *title;
	unsigned char *var;
} configitem;

typedef struct {
	char			title[32];
	unsigned char	mode;
	unsigned char	video_timing;
	char			romfile[14];
	char			divmmc_romfile[15];
	char			mf_romfile[15];
} mnuitem;

//                        12345678901234567890123456789012
const char TITLE[]     = "         TBBLUE BOOT ROM        ";

const char YESNO[2][4] = {"NO ","YES"};						// type 0
const char AYYM[3][4]  = {"AY ","YM ","OFF"};				// type 1
const char JOYS[7][7]  = {"Sincl2","Kemps1","Cursor","Sincl1","Kemps2","MD 1  ","MD 2  "};		// type 2
const char PS_2[2][6]  = {"Keyb.","Mouse"};					// type 3
const char JOY2[2][5]  = {"JOY","M.LP"};					// type 4
const char  DAC[2][4]  = {"I2S","JAP"};						// type 5
const char STEREO[2][4] = {"ABC","ACB"};					// type 6
const char SCANL[4][4]  = {"OFF","75%","50%","25%"};		// type 7


unsigned char * help_joy[] = 
				{ // 12345678901234567890123456789012
					"Maps to keys 6,7,8,9 and 0     ",
					"Kempston at port 31            ",
					"Maps to keys 5,6,7,8 and 0     ",
					"Maps to keys 1,2,3,4 and 5     ",
					"Kempston at port 55            ",
					"3 or 6 button joypad at port 31",
					"3 or 6 button joypad at port 55"
				};

/*
joystick types
000 = Sinclair 2 (67890)   
001 = Kempston 1 (1f)
010 = Cursor
011 = Sinclair 1 (12345)
100 = Kempston 2 (5f)
101 = MD 1 (sega 3/6 at 1f)
110 = MD 2 (sega 3/6 at 5f)
*/

FATFS		FatFs;		/* FatFs work area needed for each volume */
FIL			Fil;		/* File object needed for each open file */
FRESULT		res;

unsigned char divmmc[2]      = {1, 1};
unsigned char mf[2]          = {1, 1};
unsigned char psgmode[2]     = {0, 0};
unsigned char timex[2]       = {0, 0};
unsigned char freq5060[2]    = {1, 1};
unsigned char scandoubler[2] = {1, 1};
unsigned char joystick1[2]   = {0, 0};
unsigned char joystick2[2]   = {0, 0};
unsigned char ps2[2]         = {0, 0};
unsigned char lightpen[2]    = {0, 0};
unsigned char scanlines[2]   = {0, 0};
unsigned char dac[2]         = {0, 0};
unsigned char ena_turbo[2]   = {0, 0};
unsigned char turbosound[2]  = {0, 0};
unsigned char covox[2]       = {0, 0};
unsigned char intsnd[2]      = {0, 0};
unsigned char stereomode[2]  = {0, 0};

unsigned char menu_default = 0;
unsigned char menu_cont = 0;
unsigned char button_up = 0;
unsigned char button_down = 0;
unsigned char button_left = 0;
unsigned char button_right = 0;
unsigned char button_enter = 0;
unsigned char button_e = 0;
unsigned char button_c = 0;
unsigned char button_space = 0;
unsigned char config_changed = 0;

char			line[256], temp[256];
char			*comma1, *comma2, *comma3, *comma4, *comma5;
unsigned char	mach_id, mach_version;
unsigned char	i, it, nl, l, c, t, r, y, lin, col, *value, type;
unsigned char	top, bottom, opc, posc;
unsigned int	bl = 0;
unsigned char	mode = 0;

/*******************************************************************************/
static void waitforanykey()
{
	while(1) 
	{
		if ((HROW0 != 0xff) ||
			(HROW1 != 0xff) ||
			(HROW2 != 0xff) ||
			(HROW3 != 0xff) ||
			(HROW4 != 0xff) ||
			(HROW5 != 0xff) ||
			(HROW6 != 0xff) ||
			(HROW7 != 0xff) 
			)
		{
			return;
		}
	}
}

static void display_about(void) 
{
	int i;

	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_LYELLOW);
	vdp_cls();

	vdp_gotoxy(2, 2); vdp_prints("The Next Team");
	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_GRAY);
	vdp_gotoxy(2, 3); vdp_prints("Victor Trucco");
	vdp_gotoxy(2, 4); vdp_prints("Fabio Belavenuto");
	vdp_gotoxy(2, 5); vdp_prints("Henrique Olifiers");
	vdp_gotoxy(2, 6); vdp_prints("Rick Dickinson");
	vdp_gotoxy(2, 7); vdp_prints("Jim Bagley");

	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_LYELLOW);
	vdp_gotoxy(2, 9); vdp_prints("The Folks Who Made It Happen");
	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_GRAY);
	vdp_gotoxy(2, 10); vdp_prints("Allen Albright");
	vdp_gotoxy(2, 11); vdp_prints("Mike Cadwallader");
	vdp_gotoxy(2, 12); vdp_prints("Phoebus Dokos");
	vdp_gotoxy(2, 13); vdp_prints("Garry Lancaster");

	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_LYELLOW);
	vdp_gotoxy(2, 15); vdp_prints("The Super Backers");
	vdp_setcolor(COLOR_BLUE, COLOR_BLACK, COLOR_GRAY);
	vdp_gotoxy(2, 16); vdp_prints("Paul Edward Howes");
	vdp_gotoxy(2, 17); vdp_prints("Jake Warren");
	vdp_gotoxy(2, 18); vdp_prints("Steve Brown (aka Gilby)");
	vdp_gotoxy(2, 19); vdp_prints("Dan Birch");
	vdp_gotoxy(2, 20); vdp_prints("Bob Bazley");
	
	for (i=0; i<1000; i++){}; // wait some time before read the keys
	waitforanykey();
	
}


// Order: line 0 col 0, line 0 col 1, line 1 col 0....
// Others
const configitem peripherals1[] = {
	//   123456789
	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{1, "Sound",     psgmode },
	{0, "TurboSnd",  turbosound },
	{0, "Scandoubl", scandoubler },
	{7, "Scanline",  scanlines },
	{0, "60 Hz",     freq5060 },
	{0, "Ena Turbo", ena_turbo },
	{0, "Timex",     timex },
	{2, "Joy 1",     joystick1 },
	{2, "Joy 2",     joystick2 },
//	{0, "Lightpen",  lightpen },
};
const unsigned char itemcount1 = sizeof(peripherals1) / sizeof(configitem);

// VTrucco
const configitem peripherals2[] = {
	//   123456789
	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{0, "Timex",     timex },
	{1, "Sound",     psgmode },
	{0, "60 Hz",     freq5060 },
	{0, "Scandoubl", scandoubler },
	{7, "Scanline",  scanlines },
	{0, "Lightpen",  lightpen },
	{3, "PS/2",      ps2 },
	{5, "DAC",       dac },
	{0, "Ena Turbo", ena_turbo },
};
const unsigned char itemcount2 = sizeof(peripherals2) / sizeof(configitem);

// FBLabs
const configitem peripherals3[] = {
	//   123456789
	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{0, "Scandoubl", scandoubler },
	{7, "Scanline",  scanlines },
	{0, "Timex",     timex },
	{0, "60 Hz",     freq5060 },
	{1, "Sound",     psgmode },
	{0, "Ena Turbo", ena_turbo },
	{4, "P.Joy2",    lightpen },
	{2, "Joy 1",     joystick1 },
	{2, "Joy 2",     joystick2 },
};
const unsigned char itemcount3 = sizeof(peripherals3) / sizeof(configitem);

// WXEDA
const configitem peripherals4[] = {
	//   123456789
	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{0, "Scandoubl", scandoubler },
	{7, "Scanline",  scanlines },
	{0, "60 Hz",     freq5060 },
	{0, "Timex",     timex },
	{1, "Sound",     psgmode },
	{0, "TurboSnd",  turbosound },
};
const unsigned char itemcount4 = sizeof(peripherals4) / sizeof(configitem);

// Multicore
// DivMMC		Multiface
// Sound		60 Hz
// TurboSnd		Scandbl
// Ena Turbo	Scanline
// Joy1			Timex
// Joy2
const configitem peripherals5[] = {
	//   123456789
	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{1, "Sound",     psgmode },
	{0, "60 Hz",     freq5060 },
	{0, "TurboSnd",  turbosound },
	{0, "Scandoubl", scandoubler },
	{0, "Ena Turbo", ena_turbo },
	{7, "Scanline",  scanlines },
	{2, "Joy 1",     joystick1 },
	{0, "Timex",     timex },
	{2, "Joy 2",     joystick2 },
};
const unsigned char itemcount5 = sizeof(peripherals5) / sizeof(configitem);

// ZX Spectrum Next
// DivMMC		Multiface
// 60 Hz		Timex
// Sound		Scandbl
// Int. Beep	Scanline
// TurboSnd		Joy1
// Covox		Joy2
// Ena Turbo
const configitem peripherals6[] = 
{
	//   123456789

	{0, "DivMMC",    divmmc },
	{0, "Multiface", mf },
	{0, "60 Hz",     freq5060 },
	{0, "Timex",     timex },
	{1, "Sound",     psgmode },
	{0, "Int. Beep", intsnd },
	{0, "TurboSnd",  turbosound },
	{0, "Covox",     covox },
	{6, "Stereo M.", stereomode },	
	{0, "Scandoubl", scandoubler },
	{7, "Scanlines", scanlines },
	{0, "Turbo Ena", ena_turbo },
	{2, "Left joy ", joystick1 },
	{2, "Right joy", joystick2 }

};
const unsigned char itemcount6 = sizeof(peripherals6) / sizeof(configitem);

configitem *peripherals = peripherals1;
unsigned char itemsCount = 0;

mnuitem menus[15];

/* Public functions */

/*******************************************************************************/
static void display_error(const unsigned char *msg) 
{
	l = 16 - strlen(msg)/2;

	vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
	vdp_cls();
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

static void printVal(unsigned char help) 
{

	switch (type) 
	{
		case 0:
			vdp_prints(YESNO[*value]);
		break;
		
		case 1:
			vdp_prints(AYYM[*value]);
		break;
	
		case 2:
			vdp_prints(JOYS[*value]);
		break;

		case 3:
			vdp_prints(PS_2[*value]);
		break;

		case 4:
			vdp_prints(JOY2[*value]);
		break;
		
		case 5:
			vdp_prints(DAC[*value]);
		break;

		case 6:
			vdp_prints(STEREO[*value]);
		break;

		case 7:
			vdp_prints(SCANL[*value]);

		break;
	}
	
	if (help)
	{
		vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);
		vdp_setflash(0);
				
		vdp_gotoxy(0, 20);
		vdp_prints("                                ");	
		vdp_gotoxy(0, 20);
		
		if (type == 2)
		{
			vdp_prints(help_joy[*value]);
		}
	}

	
}

/*******************************************************************************/
static void show_peripherals()
{
	// Check joysticks
/*	if ((joystick1[0] == 1 && joystick2[0] == 1) ||
		(joystick1[0] == 2 && joystick2[0] == 2) ||
		(joystick1[0] == 0 && joystick2[0] == 2)) 
	{
		joystick2[0] = 0;
		config_changed = 1;
	}
	*/
	
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);
	vdp_cls();
	vdp_setbg(COLOR_BLUE);
	vdp_prints(TITLE);
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_LCYAN);
	vdp_gotoxy(0, 2);
	vdp_prints("Options:\n");

	for (i = 0; i < itemsCount; i++) 
	{
		lin = (i >> 1) + LI_ITENS;
		col = ((i & 1) == 0) ? 0 : 16;
		vdp_gotoxy(col, lin);
		vdp_setfg(COLOR_WHITE);
		vdp_prints(peripherals[i].title);
		vdp_setfg(COLOR_LRED);
		vdp_gotox(col+9);
		value = peripherals[i].var;
		type = peripherals[i].type;
		printVal(0); // without help text
	}
}


/*******************************************************************************/
static void readkeyb()
{
	button_up = 0;
	button_down = 0;
	button_left = 0;
	button_right = 0;
	button_enter = 0;
	button_e = 0;
	button_c = 0;
	button_space = 0;

	while(1) 
	{
		if ((HROW0 & 0x08) == 0) {
			button_c = 1;
			while(!(HROW0 & 0x08));
			return;
		}
		if ((HROW2 & 0x04) == 0) {
			button_e = 1;
			while(!(HROW2 & 0x04));
			return;
		}
		if ((HROW7 & 0x01) == 0) {
			button_space = 1;
			while(!(HROW7 & 0x01));
			return;
		}
		if ((HROW3 & 0x10) == 0) {
			button_left = 1;
			while(!(HROW3 & 0x10));
			return;
		}
		t = HROW4;
		if ((t & 0x10) == 0) {
			button_down = 1;
			while(!(HROW4 & 0x10));
			return;
		}
		if ((t & 0x08) == 0) {
			button_up = 1;
			while(!(HROW4 & 0x08));
			return;
		}
		if ((t & 0x04) == 0) {
			button_right = 1;
			while(!(HROW4 & 0x04));
			return;
		}
		if ((HROW6 & 0x01) == 0) {
			button_enter = 1;
			while(!(HROW6 & 0x01));
			return;
		}

		// Verify that the user has changed 50/60Hz or scandoubler by keyboard
		i = 0;

		REG_NUM = REG_PERIPH1;
		t = (REG_VAL & 0x07);

		if (freq5060[0] != ((t & 0x04) >> 2)) 
		{
			freq5060[0] = (t & 0x04) >> 2;
			freq5060[1] = freq5060[0];
			i = 1;
			config_changed = 1;
		}

		if (scandoubler[0] != (t & 0x01)) 
		{
			scandoubler[0] = (t & 0x01);
			scandoubler[1] = scandoubler[0];
			i = 1;
			config_changed = 1;
		}

		/*
		REG_NUM = REG_PERIPH4;
		t = (REG_VAL & 3);

		if (scanlines[0] != (t & 0x03))
		{
			scanlines[0] = (t & 0x03);
			scanlines[1] = scanlines[0];
			i = 1;
			config_changed = 1;
		}
*/
		if (i == 1) {
			break;
		}
	}
}

/*******************************************************************************/
static unsigned char iedit() {

	r = 0;
	lin = l + LI_ITENS;
	col = (c == 0) ? 9 : 25;	
	while(1) {
		vdp_gotoxy(col, lin);
		vdp_setflash(1);
		vdp_setfg(COLOR_RED);
		printVal(1); // with the help text
		vdp_setflash(0);
		vdp_putchar(' ');
		readkeyb();
		if (i == 1) {
			break;
		}
		if (button_space == 1) {
			
			if (type == 1 ) 
			{
				if (*value < 2) 
				{
					*value = *value + 1;
				} 
				else 
				{
					*value = 0;
				}
			} 
			else if (type == 2 ) 
			{
				if (*value < 6) 
				{
					*value = *value + 1;
				} 
				else 
				{
					*value = 0;
				}
			} 
			else if (type == 7 ) 
			{
				if (*value < 3) 
				{
					*value = *value + 1;
				} 
				else 
				{
					*value = 0;
				}
			}
			else 
			{
				if (*value == 0)
				{
					*value = 1;
				}
				else
				{
					*value = 0;
				}
			}
			
		} else if (button_up == 1) {
			r = 1;
			break;
		} else if (button_down == 1) {
			r = 2;
			break;
		} else if (button_left == 1) {
			r = 3;
			break;
		} else if (button_right == 1) {
			r = 4;
			break;
		} else if (button_enter == 1) {
			r = 5;
			break;
		}
	}
	vdp_gotoxy(col, lin);
	vdp_setflash(0);
	vdp_setfg(COLOR_LRED);
	printVal(0); //no help text
	vdp_prints(" ");
		
	vdp_gotoxy(0, 20);
	vdp_prints("                                ");	
		
	return r;
}

/*******************************************************************************/
static void mode_edit() {

	r = 0;
	it = 0;
	nl = (itemsCount - 1) >> 1;

	divmmc[1]      = divmmc[0];
	mf[1]          = mf[0];
	psgmode[1]     = psgmode[0];
	timex[1]       = timex[0];
	freq5060[1]    = freq5060[0];
	scandoubler[1] = scandoubler[0];
	joystick1[1]   = joystick1[0];
	joystick2[1]   = joystick2[0];
	ps2[1]         = ps2[0];
	lightpen[1]    = lightpen[0];
	scanlines[1]   = scanlines[0];
	dac[1]   	   = dac[0];
	ena_turbo[1]   = ena_turbo[0];
	turbosound[1]  = turbosound[0];
	covox[1]       = covox[0];
	intsnd[1]      = intsnd[0];
	stereomode[1]  = stereomode[0];

	while (1) {
		l = it >> 1;
		c = it & 1;
		type = peripherals[it].type;
		value = peripherals[it].var + 1;
		r = iedit();
		if (r == 0) {
			show_peripherals();
		} else if (r == 1 && l > 0) {		// UP
			it -= 2;
		} else if (r == 2 && l < nl) {		// DOWN
			it += 2;
		} else if (r == 3 && c == 1) {		// LEFT
			--it;
		} else if (r == 4 && c == 0) {		// RIGHT
			++it;
		} else if (r == 5) {				// ENTER
			break;
		}
		if (it == itemsCount) {
			--it;
		}
	}

	divmmc[0]      = divmmc[1];
	mf[0]          = mf[1];
	psgmode[0]     = psgmode[1];
	timex[0]       = timex[1];
	freq5060[0]    = freq5060[1];
	scandoubler[0] = scandoubler[1];
	joystick1[0]   = joystick1[1];
	joystick2[0]   = joystick2[1];
	ps2[0]         = ps2[1];
	lightpen[0]    = lightpen[1];
	scanlines[0]   = scanlines[1];
	dac[0]   	   = dac[1];
	ena_turbo[0]   = ena_turbo[1];
	turbosound[0]  = turbosound[1];
	covox[0]       = covox[1];
	intsnd[0]      = intsnd[1];
	stereomode[0]  = stereomode[1];

	config_changed = 1;
	
	opc = 0;
	if (freq5060[0] == 1)    opc |= 0x04;
	if (scandoubler[0] == 1) opc |= 0x01;
	REG_NUM = REG_PERIPH1;				// send only 50/60 and scandoubler options
	REG_VAL = opc;
	
	opc = scanlines[0] & 3;
	REG_NUM = REG_PERIPH4;				// send only scanlines options
	REG_VAL = opc;
	
	
}

/*******************************************************************************/
static void show_menu(unsigned char numitens)
{
	top = 0;
	bottom = numitens-1;
	posc = menu_default;
	if (posc > bottom) 
		posc = bottom;
init:
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);
	vdp_cls();
	vdp_setbg(COLOR_BLUE);
	vdp_prints(TITLE);
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_CYAN);
	vdp_gotoxy(0, 22);
	vdp_prints("  Press 'E' to edit options    ");
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_GRAY);
	vdp_gotoxy(0, 23);
	vdp_prints("        'C' for credits screen  ");
	while(1) {
		vdp_setfg(COLOR_LGREEN);
		y = 3;
		for (i = top; i <= bottom; i++) {
			vdp_gotoxy(2, y++);
			vdp_setflash(i == posc);
			vdp_prints(menus[i].title);
			vdp_setflash(0);
		}
		readkeyb();
		vdp_setfg(COLOR_LGREEN);
		if (button_c) {
			display_about();
			goto init;
		}
		else if (button_e) {
			show_peripherals();
			mode_edit();
			goto init;
		} else if (button_up) {
			if (posc > top) {
				--posc;
			}
		} else if (button_down) {
			if (posc < bottom) {
				++posc;
			}
		} else if (button_enter) {
			if (posc != menu_default) {
				menu_default = posc;
				config_changed = 1;
			}
			break;
		}
	}
}

/*******************************************************************************/
static void save_config()
{
	unsigned int i;
	res = FR_OK;

	// FA_CREATE_ALWAYS should be used, but f_open always returns an error.
	ERR_CHECK(f_open(&Fil, CONFIG_FILE, /*FA_CREATE_ALWAYS*/
					FA_OPEN_EXISTING | FA_WRITE));
	
	ERR_CHECK_PF(f_printf(&Fil, "scandoubler=%d\n", scandoubler[0]));
	ERR_CHECK_PF(f_printf(&Fil, "50_60hz=%d\n",     freq5060[0]));
	ERR_CHECK_PF(f_printf(&Fil, "timex=%d\n",       timex[0]));
	ERR_CHECK_PF(f_printf(&Fil, "psgmode=%d\n",     psgmode[0]));
	ERR_CHECK_PF(f_printf(&Fil, "stereomode=%d\n",  stereomode[0]));
	ERR_CHECK_PF(f_printf(&Fil, "intsnd=%d\n",      intsnd[0]));
	ERR_CHECK_PF(f_printf(&Fil, "turbosound=%d\n",  turbosound[0]));
	ERR_CHECK_PF(f_printf(&Fil, "covox=%d\n",       covox[0]));
	ERR_CHECK_PF(f_printf(&Fil, "divmmc=%d\n",      divmmc[0]));
	ERR_CHECK_PF(f_printf(&Fil, "mf=%d\n",          mf[0]));
	ERR_CHECK_PF(f_printf(&Fil, "joystick1=%d\n",   joystick1[0]));
	ERR_CHECK_PF(f_printf(&Fil, "joystick2=%d\n",   joystick2[0]));
	ERR_CHECK_PF(f_printf(&Fil, "ps2=%d\n",         ps2[0]));
	ERR_CHECK_PF(f_printf(&Fil, "lightpen=%d\n",    lightpen[0]));
	ERR_CHECK_PF(f_printf(&Fil, "scanlines=%d\n",   scanlines[0]));
	ERR_CHECK_PF(f_printf(&Fil, "dac=%d\n",         dac[0]));
	ERR_CHECK_PF(f_printf(&Fil, "turbo=%d\n",       ena_turbo[0]));

	ERR_CHECK_PF(f_printf(&Fil, "default=%d\n", menu_default));
	
	for (i=0; i < menu_cont; i++) 
	{
#if DEBUG_CONFIG
		vdp_cls();
		vdp_prints("WRITE:\n");
		vdp_prints(menus[i].title);
		vdp_putchar(10);
		vdp_prints(menus[i].romfile);
		vdp_putchar(10);
		vdp_prints(menus[i].divmmc_romfile);
		vdp_putchar(10);
		vdp_prints(menus[i].mf_romfile);
		vdp_putchar(10);
#endif // DEBUG_CONFIG

		ERR_CHECK_PF(f_printf(&Fil, "menu=%s,%d,%d,%s%s%s\n", menus[i].title, menus[i].mode, menus[i].video_timing, menus[i].romfile,menus[i].divmmc_romfile,menus[i].mf_romfile));

#if DEBUG_CONFIG
		readkeyb();
#endif // DEBUG_CONFIG

	}	

	// Delete any further part of the file that we haven't overwritten
	ERR_CHECK(f_sync(&Fil));
	ERR_CHECK(f_truncate(&Fil));	

	ERR_CHECK(f_close(&Fil));
	
	if (res != FR_OK) 
	{
		//             12345678901234567890123456789012
		display_error("Error saving configuration!");
	}

#if DEBUG_CONFIG
	readkeyb();
#endif // DEBUG_CONFIG
}

/* Public functions */

/*******************************************************************************/
unsigned long get_fattime() {

	return 0x44210000UL;
}

/*******************************************************************************/
void main()
{
	REG_NUM = REG_MACHID;
	mach_id = REG_VAL;
	REG_NUM = REG_VERSION;
	mach_version = REG_VAL;

	REG_NUM = REG_TURBO;
	REG_VAL = 2;

	vdp_init();
	vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
	vdp_prints(TITLE);
	vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_LGREEN);

	REG_NUM = REG_MACHTYPE;
	REG_VAL = 0;						// disable bootrom

	f_mount(&FatFs, "", 0);		/* Give a work area to the default drive */

	res = f_open(&Fil, CONFIG_FILE, FA_READ);
	if (res != FR_OK) {
		//             12345678901234567890123456789012
		display_error("Error opening 'config.ini' file!");
	}

	while(f_eof(&Fil) == 0) {
		if (!f_gets(line, 255, &Fil)) {
			//             12345678901234567890123456789012
			display_error("Error reading configuration!");
		}
		if (line[0] == ';')
			continue;

		if (line[strlen(line)-1] == '\n')
		{
			line[strlen(line)-1] = '\0';
		}
		else
		{
			line[strlen(line)] = '\0';
		}

		if ( strncmp ( line, "scandoubler=", 12) == 0) 
		{
			scandoubler[0] = CLAMP(atoi( line + 12), MAX_SCANDOUBLER);
		} 
		else if ( strncmp ( line, "50_60hz=", 8) == 0) 
		{
			freq5060[0] = CLAMP(atoi( line + 8), MAX_FREQ5060);
		} 
		else if ( strncmp ( line, "timex=", 6) == 0) 
		{
			timex[0] = CLAMP(atoi( line + 6), MAX_TIMEX);
		} 
		else if ( strncmp ( line, "psgmode=", 8) == 0) 
		{
			psgmode[0] = CLAMP(atoi( line + 8), MAX_PSGMODE);
		} 
		else if ( strncmp ( line, "intsnd=", 7) == 0) 
		{
			intsnd[0] = CLAMP(atoi( line + 7), MAX_INTSND);
		}
 		else if ( strncmp ( line, "stereomode=", 11) == 0) 
		{
			stereomode[0] = CLAMP(atoi( line + 11), MAX_STEREOMODE);
		} 
		else if ( strncmp ( line, "turbosound=", 11) == 0) 
		{
			turbosound[0] = CLAMP(atoi( line + 11), MAX_TURBOSOUND);
		} 
		else if ( strncmp ( line, "covox=", 6) == 0) 
		{
			covox[0] = CLAMP(atoi( line + 6), MAX_COVOX);
		} 
		else if ( strncmp ( line, "divmmc=", 7) == 0) 
		{
			divmmc[0] = CLAMP(atoi( line + 7), MAX_DIVMMC);
		} 
		else if ( strncmp ( line, "mf=", 3) == 0) 
		{
			mf[0] = CLAMP(atoi( line + 3), MAX_MF);
		} 
		else if ( strncmp ( line, "joystick1=", 10) == 0) 
		{
			joystick1[0] = CLAMP(atoi( line + 10), MAX_JOYSTICK1);
		} 
		else if ( strncmp ( line, "joystick2=", 10) == 0) 
		{
			joystick2[0] = CLAMP(atoi( line + 10), MAX_JOYSTICK2);
		} 
		else if ( strncmp ( line, "ps2=", 4) == 0) 
		{
			ps2[0] = CLAMP(atoi( line + 4), MAX_PS2);
		} 
//		else if ( strncmp ( line, "alternativePS2=", 15) == 0) 
//		{
//			alt_ps2[0] = atoi( line + 15);
//		} 
		else if ( strncmp ( line, "dac=", 4 ) == 0) 
		{
			dac[0] = CLAMP(atoi( line + 4), MAX_DAC);
		} 
		else if ( strncmp ( line, "lightpen=", 9 ) == 0) 
		{
			lightpen[0] = CLAMP(atoi( line + 9), MAX_LIGHTPEN);
		} 
		else if ( strncmp ( line, "scanlines=", 10 ) == 0) 
		{
			scanlines[0] = CLAMP(atoi( line + 10 ), MAX_SCANLINES);
		} 
		else if ( strncmp ( line, "turbo=", 6 ) == 0) 
		{
			ena_turbo[0] = CLAMP(atoi( line + 6 ), MAX_TURBO);
		} 
		else if ( strncmp ( line, "default=", 8) == 0) 
		{
			menu_default = atoi( line + 8);
		} 
		else if ( strncmp ( line, "menu=", 5) == 0) 
		{
			if (menu_cont < 15) {
				comma1 = strchr(line, ',');
				if (comma1 == 0)
					continue;
				memset(temp, 0, 255);
				memcpy(temp, line+5, (comma1-line-5));
				strcpy(menus[menu_cont].title, temp);
				++comma1;
				
				comma2 = strchr(comma1, ',');
				if (comma2 == 0) {
					continue;
				}
				memset(temp, 0, 255);
				memcpy(temp, comma1, (comma2-comma1));
				menus[menu_cont].mode = atoi(temp);
				++comma2;
				
				comma3 = strchr(comma2, ',');
				if (comma3 == 0) {
					continue;
				}
				memset(temp, 0, 255);
				memcpy(temp, comma2, (comma3-comma2));
				menus[menu_cont].video_timing = atoi(temp);
				++comma3;

				
				comma4 = strchr(comma3, ',');
				if (comma4 != 0) {

					memset(temp, 0, 255);
					memcpy(temp, comma3, ( comma4 - comma3 + 1 ));

					strcpy(menus[menu_cont].romfile, temp); 

					++comma4;

					comma5 = strchr(comma4, ',');
					if (comma5 != 0) {

						memset(temp, 0, 255);
						memcpy(temp, comma4, ( comma5 - comma4 + 1));

						strcpy(menus[menu_cont].divmmc_romfile, temp);

						++comma5;
						strcpy(menus[menu_cont].mf_romfile, comma5);
					}
					else
					{
						strcpy(menus[menu_cont].divmmc_romfile, comma4);
						strcpy(menus[menu_cont].mf_romfile, "");
					}
				}
				else
				{
					strcpy(menus[menu_cont].romfile, comma3);
					strcpy(menus[menu_cont].divmmc_romfile, ""); 
					strcpy(menus[menu_cont].mf_romfile, ""); 
				}

#if DEBUG_CONFIG
		vdp_cls();
		vdp_prints("READ:\n");
		vdp_prints(menus[menu_cont].title);
		vdp_putchar(10);
		vdp_prints(menus[menu_cont].romfile);
		vdp_putchar(10);
		vdp_prints(menus[menu_cont].divmmc_romfile);
		vdp_putchar(10);
		vdp_prints(menus[menu_cont].mf_romfile);
		vdp_putchar(10);
		readkeyb();
#endif // DEBUG_CONFIG
				
				++menu_cont;
			}
		}
	}
	
	f_close(&Fil);
	
	if (menu_cont == 0) 
	{
		//             12345678901234567890123456789012
		display_error("No configuration read!");
	}
	if (mach_id == HWID_VTRUCCO) 
	{
		peripherals = (configitem *)peripherals2;
		itemsCount = itemcount2;
	} 
	else if (mach_id == HWID_ZXNEXT) 
	{
		peripherals = (configitem *)peripherals6;
		itemsCount = itemcount6;
	} 
	else if (mach_id == HWID_FBLABS) 
	{
		peripherals = (configitem *)peripherals3;
		itemsCount = itemcount3;
	} 
	else if (mach_id == HWID_WXEDA) 
	{
		peripherals = (configitem *)peripherals4;
		itemsCount = itemcount4;
	} 
	else if (mach_id == HWID_MC) 
	{
		peripherals = (configitem *)peripherals5;
		itemsCount = itemcount5;
	} 
	else 
	{
		peripherals = (configitem *)peripherals1;
		itemsCount = itemcount1;
	}

	show_menu(menu_cont);
	
	if (config_changed) 
	{
		save_config();
	}
	
	REG_NUM = REG_RESET;
	REG_VAL = RESET_HARD;				// Hard-reset
}
