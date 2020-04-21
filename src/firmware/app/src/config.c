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
#include <string.h>
#include "hardware.h"
#include "vdp.h"
#include "ff.h"
#include "misc.h"
#include "config.h"

const char * settingName[eSettingMAX] =
{
	"scandoubler",		// eSettingScandoubler
	"50_60hz",		// eSettingFreq5060
	"timex",		// eSettingTimex
	"psgmode",		// eSettingPsgMode
	"intsnd",		// eSettingIntSnd
	"stereomode",		// eSettingStereoMode
	"turbosound",		// eSettingTurboSound
	"covox",		// eSettingCovox
	"divmmc",		// eSettingDivMMC
	"mf",			// eSettingMF
	"joystick1",		// eSettingJoystick1
	"joystick2",		// eSettingJoystick2
	"ps2",			// eSettingPS2
	"dma",			// eSettingDMA
	"scanlines",		// eSettingScanlines
	"turbokey",		// eSettingTurboKey
	"default",		// eSettingMenuDefault
	"timing",		// eSettingTiming
	"keyb_issue",		// eSettingIss23
	"divports",		// eSettingDivPorts
	"dac",			// eSettingDAC
	"ay48",			// eSettingAY48
	"uart_i2c",		// eSettingUARTI2C
	"kmouse",		// eSettingKMouse
	"ulaplus",		// eSettingULAplus
	"hdmisound",		// eSettingHDMISound
	"beepmode",		// eSettingBEEPMode
};	

const unsigned char settingMaxValue[eSettingMAX] =
{
	MAX_SCANDOUBLER,	// eSettingScandoubler
	MAX_FREQ5060,		// eSettingFreq5060
	MAX_TIMEX,		// eSettingTimex
	MAX_PSGMODE,		// eSettingPsgMode
	MAX_INTSND,		// eSettingIntSnd
	MAX_STEREOMODE,		// eSettingStereoMode
	MAX_TURBOSOUND,		// eSettingTurboSound
	MAX_COVOX,		// eSettingCovox
	MAX_DIVMMC,		// eSettingDivMMC
	MAX_MF,			// eSettingMF
	MAX_JOYSTICK1,		// eSettingJoystick1
	MAX_JOYSTICK2,		// eSettingJoystick2
	MAX_PS2,		// eSettingPS2
	MAX_DMA,		// eSettingDMA
	MAX_SCANLINES,		// eSettingScanlines
	MAX_TURBOKEY,		// eSettingTurboKey
	255,			// eSettingMenuDefault (don't clamp)
	MAX_TIMING,		// eSettingTiming
	MAX_ISS23,		// eSettingIss23
	MAX_DIVPORTS,		// eSettingDivPorts
	MAX_DAC,		// eSettingDAC
	MAX_AY48,		// eSettingAY48
	MAX_UARTI2C,		// eSettingUARTI2C
	MAX_KMOUSE,		// eSettingKMouse
	MAX_ULAPLUS,		// eSettingULAplus
	MAX_HDMISOUND,		// eSettingHDMISound
	MAX_BEEPMODE,		// eSettingBEEPMode
};

const unsigned char settingDefaults[eSettingMAX] =
{
	1,			// eSettingScandoubler
	0,			// eSettingFreq5060
	1,			// eSettingTimex
	1,			// eSettingPsgMode
	1,			// eSettingIntSnd
	0,			// eSettingStereoMode
	1,			// eSettingTurboSound
	1,			// eSettingCovox
	0,			// eSettingDivMMC
	0,			// eSettingMF
	1,			// eSettingJoystick1
	3,			// eSettingJoystick2
	1,			// eSettingPS2
	0,			// eSettingDMA
	0,			// eSettingScanlines
	1,			// eSettingTurboKey
	0,			// eSettingMenuDefault
	8,			// eSettingTiming
	0,			// eSettingIss23
	1,			// eSettingDivPorts
	0,			// eSettingDAC
	0,			// eSettingAY48
	1,			// eSettingUARTI2C
	1,			// eSettingKMouse
	1,			// eSettingULAplus
	1,			// eSettingHDMISound
	0,			// eSettingBEEPMode
};

const unsigned char settingType[eSettingMAX] =
{
	eTypeYesNo,		// eSettingScandoubler
	eTypeYesNo,		// eSettingFreq5060
	eTypeYesNo,		// eSettingTimex
	eTypePSGMode,		// eSettingPSGMode
	eTypeYesNo,		// eSettingIntSnd
	eTypeStereoMode,	// eSettingStereoMode
	eTypeYesNo,		// eSettingTurboSound
	eTypeYesNo,		// eSettingCovox
	eTypeYesNo,		// eSettingDivMMC
	eTypeYesNo,		// eSettingMF
	eTypeJoystickMode,	// eSettingJoystick1
	eTypeJoystickMode,	// eSettingJoystick2
	eTypePS2Mode,		// eSettingPS2
	eTypeYesNo,		// eSettingDMA
	eTypeScanlines,		// eSettingScanlines
	eTypeYesNo,		// eSettingTurboKey
	0,			// eSettingMenuDefault (not edited)
	0,			// eSettingTiming (not edited)
	eTypeIss23,		// eSettingIss23
	eTypeYesNo,		// eSettingDivPorts
	eTypeYesNo,		// eSettingDAC
	eTypeYesNo,		// eSettingAY48
	eTypeYesNo,		// eSettingUARTI2C
	eTypeYesNo,		// eSettingKMouse
	eTypeYesNo,		// eSettingULAplus
	eTypeYesNo,		// eSettingHDMISound
	eTypeBEEPMode,		// eSettingBEEPMode
};

unsigned char settings[eSettingMAX];
unsigned char menu_cont = 0;
mnuitem menus[MAX_MENU_ITEMS];

char line[256], temp[16];
const char *pLine, *comma;
mnuitem *pMenu;

void parsestring(char *pDest, unsigned int maxlen)
{
	memset(pDest, 0, maxlen);
	comma = strchr(pLine, ',');

	if (comma == 0)
	{
		strncpy(pDest, pLine, maxlen-1);
		pLine = "\0";
	}
	else
	{
		strncpy(pDest, pLine, MIN(comma-pLine,maxlen-1));
		pLine = comma + 1;
	}
}

void parsenumber(unsigned char *pValue)
{
	parsestring(temp, 16);
	*pValue = atoi(temp);
}

void parseword(unsigned int *pValue)
{
	parsestring(temp, 16);
	*pValue = atoi(temp);
}

void update_video_settings()
{
	unsigned char opc = 0;

	if (settings[eSettingFreq5060] == 1)    opc |= 0x04;
	if (settings[eSettingScandoubler] == 1) opc |= 0x01;

	REG_NUM = REG_PERIPH1;
	REG_VAL = opc;

	opc = settings[eSettingScanlines] & 3;

	REG_NUM = REG_PERIPH4;
	REG_VAL = opc;

	if ((menu_cont > 0) && (settings[eSettingMenuDefault] < menu_cont))
	{
		unsigned char tim = settings[eSettingTiming];
		pMenu = &(menus[settings[eSettingMenuDefault]]);

		// If timing override is specified, use it.
		if (pMenu->video_timing < 8)
		{
			tim = pMenu->video_timing;
		}

		REG_NUM = REG_VIDEOT;
		REG_VAL = (tim & 0x07) | 0x80;
	}
}


void reset_settings()
{
	// Default all options to something sensible
	memcpy(&settings, &settingDefaults, sizeof(settings));
}

void load_config()
{
	unsigned int i;

	// Read config.ini at 14MHz
	REG_NUM = REG_TURBO;
	REG_VAL = 2;

	// Default all options to something sensible
	reset_settings();

	// Give a work area to the default drive
	res = f_mount(&FatFs, "", 0);
	if (res != FR_OK)
	{
		//             12345678901234567890123456789012
		display_error("Error mounting SD card!");
	}

	res = f_open(&Fil, CONFIG_FILE, FA_READ);
	if (res != FR_OK)
	{
		//             12345678901234567890123456789012
		display_error("Error opening 'config.ini'!");
	}

	// Read configuration
	while(f_eof(&Fil) == 0)
	{
		if (!f_gets(line, 255, &Fil))
		{
			//             12345678901234567890123456789012
			display_error("Error reading file data!");
		}

		if (line[0] == ';')
			continue;

		// Ensure correct parsing even if no EOL on last line
		if (line[strlen(line)-1] == '\n')
		{
			line[strlen(line)-1] = '\0';
		}
		else
		{
			line[strlen(line)] = '\0';
		}

		if ( strncmp ( line, "menu=", 5) == 0)
		{
			if (menu_cont < MAX_MENU_ITEMS) {
				pMenu = &(menus[menu_cont]);
				pLine = line + 5;
				parsestring(pMenu->title, MAX_TITLE);
				parsenumber(&(pMenu->mode));
				parsenumber(&(pMenu->video_timing));
				parsestring(pMenu->romfile, MAX_ROMNAME);
				parsestring(pMenu->divmmc_romfile, MAX_ROMNAME);
				parsestring(pMenu->mf_romfile, MAX_ROMNAME);

				if (pMenu->romfile[0])
				{
					++menu_cont;
				}
			}
		}
		else
		{
			for (i = 0; i < eSettingMAX; i++)
			{
				unsigned int len = strlen(settingName[i]);
				if ((line[len] == '=') && strncmp(line, settingName[i], len) == 0)
				{
					settings[i] = CLAMP(atoi(line + len + 1), settingMaxValue[i]);
					break;
				}
			}
		}
	}

	f_close(&Fil);

	if (menu_cont == 0) {
		//             12345678901234567890123456789012
		display_error("No menu line read!");
	}

	if (settings[eSettingMenuDefault] >= menu_cont) {
	    settings[eSettingMenuDefault] = menu_cont - 1;
	}

	// Revert to standard 3.5MHz
	REG_NUM = REG_TURBO;
	REG_VAL = 0;
}
