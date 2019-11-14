/*
TBBlue / ZX Spectrum Next project

videotest: Garry Lancaster

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
#include "layers.h"
#include "videotest.h"

unsigned char * strVidMagic = "VideoTest";

#define VIDMAGIC_OFFSET 0
#define VIDMAGIC_LEN 9
#define VIDMODE_OFFSET (VIDMAGIC_OFFSET + VIDMAGIC_LEN)
#define VIDITER_OFFSET (VIDMODE_OFFSET + 1)
#define VIDBLACK_OFFSET (VIDITER_OFFSET + 1)
#define VIDWHITE_OFFSET (VIDBLACK_OFFSET + 1)

unsigned char *pVidMagic = (unsigned char *)VIDMAGIC_OFFSET;
unsigned char *pVidTestMode = (unsigned char *)VIDMODE_OFFSET;
unsigned char *pVidTestIter = (unsigned char *)VIDITER_OFFSET;
unsigned char *pVidTestBlack = (unsigned char *)VIDBLACK_OFFSET;
unsigned char *pVidTestWhite = (unsigned char *)VIDWHITE_OFFSET;

const testmodeitem modesDigital[] =
{
	{ 7, 0, 1 },
	{ 7, 1, 1 },

	// End marker
	{ 255, 255, 255 }
};

const testmodeitem modesRGB[] =
{`
	{ 0, 0, 0 },
	{ 0, 1, 0 },

	// End marker
	{ 255, 255, 255 }
};

const testmodeitem modesVGA[] =
{
	{ 0, 0, 1 },
	{ 0, 1, 1 },
	{ 1, 0, 1 },
	{ 1, 1, 1 },
	{ 2, 0, 1 },
	{ 2, 1, 1 },
	{ 3, 0, 1 },
	{ 3, 1, 1 },
	{ 4, 0, 1 },
	{ 4, 1, 1 },
	{ 5, 0, 1 },
	{ 5, 1, 1 },
	{ 6, 0, 1 },
	{ 6, 1, 1 },

	// End marker
	{ 255, 255, 255 }
};

const testmodeitem modesAll[] =
{
	// Digital first
	{ 7, 0, 1 },
	{ 7, 1, 1 },

	// RGB next
	{ 0, 0, 0 },
	{ 0, 1, 0 },

	// VGA last
	{ 0, 0, 1 },
	{ 0, 1, 1 },
	{ 1, 0, 1 },
	{ 1, 1, 1 },
	{ 2, 0, 1 },
	{ 2, 1, 1 },
	{ 3, 0, 1 },
	{ 3, 1, 1 },
	{ 4, 0, 1 },
	{ 4, 1, 1 },
	{ 5, 0, 1 },
	{ 5, 1, 1 },
	{ 6, 0, 1 },
	{ 6, 1, 1 },

	// End marker
	{ 255, 255, 255 }
};

const testmodeitem *modeTables[] =
{
	0,			// eVidTestNone
	modesAll,		// eVidTestAll
	modesDigital,		// eVidTestDigital
	modesRGB,		// eVidTestRGB
	modesVGA,		// eVidTestVGA
};

const char *modeName[] =
{
	"",			// eVidTestNone
	"ALL",			// eVidTestAll
	"DIGI",			// eVidTestDigital
	"RGB",			// eVidTestRGB
	"VGA",			// eVidTestVGA
};

unsigned char vidtestmode;
unsigned char l2black, l2white;
testmodeitem curtestmode;


void aySend(unsigned char ayreg, unsigned char data)
{
	AY_REG = ayreg;
	AY_DATA = data;
}

void ayOff()
{
	aySend(AY_REG_MIXER, 0xff);
	aySend(AY_REG_VOLUME_A, 0x00);
}

void videoTestInit(unsigned char mode)
{
	unsigned int i, l;
	unsigned int *pPalette;

	if (mode == eVidTestNone)
	{
		// Overwrite the magic to disable testing.
		REG_NUM = REG_RAMPAGE;
		REG_VAL = RAMPAGE_ROMSPECCY;
		*pVidMagic = 0;
	}
	else
	{
		// Load the L2 test card into RAM (at 14MHz)
		REG_NUM = REG_TURBO;
		REG_VAL = 2;

		fwOpenAndSeek(FW_BLK_TESTCARD_SCR);

		for (i = 0; i < 3; i++)
		{
			REG_NUM = REG_RAMPAGE;
			REG_VAL = RAMPAGE_RAMSPECCY + L2_BANK + i;
			fwRead((unsigned char *)0, 0x4000);	
		}

#if (FW_BLK_TESTCARD_L2PAL != (FW_BLK_TESTCARD_SCR + 1))
#error "FW_BLK_TESTCARD_L2PAL must follow FW_BLK_TESTCARD_SCR"
#endif
#if (FW_BLK_TESTCARD_TMPAL != (FW_BLK_TESTCARD_L2PAL + 1))
#error "FW_BLK_TESTCARD_TMPAL must follow FW_BLK_TESTCARD_L2PAL"
#endif

		// Read the L2 & tilemap palettes into the following bank
		// so they can be set from memory after each reboot
		// without needing to be reloaded.
		REG_NUM = REG_RAMPAGE;
		REG_VAL = RAMPAGE_RAMSPECCY + L2_BANK + 3;
		fwRead((unsigned char *)0, 0x400);

		// Find the layer2 palette indices for black and white.
		pPalette = (unsigned int *)0;

		for (i = 0; i < 256; i++)
		{
			if (pPalette[i] == 0x0000)
			{
				l2black = i;
			}

			if (pPalette[i] == 0x01ff)
			{
				l2white = i;
			}
		}

#if (FW_BLK_TESTCARD_TMDATA != (FW_BLK_TESTCARD_TMPAL + 1))
#error "FW_BLK_TESTCARD_TMDATA must follow FW_BLK_TESTCARD_TMPAL"
#endif

		// Similarly, read the tilemap data into the next bank.
		REG_NUM = REG_RAMPAGE;
		REG_VAL = RAMPAGE_RAMSPECCY + L2_BANK + 4;
		l = fwBlockLength(FW_BLK_TESTCARD_TMDATA);
		fwRead((unsigned char *)0, l * 512);

		fwClose();

		REG_NUM = REG_TURBO;
		REG_VAL = 0;

		// Initialise the testing data and signal in progress.
		REG_NUM = REG_RAMPAGE;
		REG_VAL = RAMPAGE_ROMSPECCY;
		strncpy(pVidMagic, strVidMagic, VIDMAGIC_LEN);

		*pVidTestMode = mode;
		*pVidTestIter = 0;
		*pVidTestBlack = l2black;
		*pVidTestWhite = l2white;
	}
}

unsigned char videoTestReselect()
{
	unsigned char mode = eVidTestNone;

	if ((HROW0 & 0x10) == 0)	// "V"
	{
		mode = eVidTestVGA;
	}
	else if ((HROW1 & 0x01) == 0)	// "A"
	{
		mode = eVidTestAll;
	}
	else if ((HROW2 & 0x08) == 0)	// "R"
	{
		mode = eVidTestRGB;
	}
	else if ((HROW1 & 0x04) == 0)	// "D"
	{
		mode = eVidTestDigital;
	}

	if ((mode != eVidTestNone)
	    && (mode != vidtestmode))
	{
		vidtestmode = mode;
		return 1;
	}
	else
	{
		return 0;
	}
}

unsigned char videoTestActive()
{
	REG_NUM = REG_RAMPAGE;
	REG_VAL = RAMPAGE_ROMSPECCY;

	if (strncmp(pVidMagic, strVidMagic, VIDMAGIC_LEN) == 0)
	{
		// Video mode testing is already in progress.
		vidtestmode = *pVidTestMode;
	}
	else
	{
		vidtestmode = eVidTestNone;
	}

	if (videoTestReselect())
	{
		// Initialise or re-initialise if new mode chosen.
		videoTestInit(vidtestmode);
	}
	else if ((vidtestmode == eVidTestNone)
		&& (settings[eSettingTiming] == 8))
	{
		// Force testing if timing=8 in config.ini.
		vidtestmode = eVidTestAll;
		videoTestInit(vidtestmode);
	}

	return (vidtestmode != eVidTestNone);
}

unsigned char videoTestMode()
{
	// Set the current mode.
	// NOTE: If the timing register contents are changed, a power-on
	//       reboot will occur, but we will then be returned to this
	//       point since the details of the current video mode cycle
	//       state are stored in RAM.
	unsigned long l;
	unsigned char opc = 0;
	unsigned char modeName_x;

	REG_NUM = REG_VIDEOT;
	REG_VAL = curtestmode.timing | 0x80;

	if (curtestmode.freq)		opc |= 0x04;
	if (curtestmode.doubler)	opc |= 0x01;
	REG_NUM = REG_PERIPH1;
	REG_VAL = opc;

	// Set layer2 start bank.
	REG_NUM = REG_L2BANK;
	REG_VAL = L2_BANK;

	// Display mode information.
	l2_setcolours(l2black, l2white);
	l2_gotoxy(7*8, 2*8-5);
	//////////////////123456
	l2_prints("Cycling      modes");

	modeName_x = 14*8 + ((6-strlen(modeName[vidtestmode]))*8/2);
	l2_gotoxy(modeName_x, 2*8-5);
	l2_prints(modeName[vidtestmode]);

	l2_gotoxy(7*8,19*8);
	l2_prints("Mode ");
	l2_putchar('0' + curtestmode.timing);
	if (curtestmode.freq)
	{
		l2_prints("/60Hz");
	}
	else
	{
		l2_prints("/50Hz");
	}
	if (curtestmode.doubler)
	{
		l2_prints("/scan*2");
	}
	else
	{
		l2_prints("/scan*1");
	}

	// Set the layer2 and tilemap palettes for the testcard
	REG_NUM = REG_RAMPAGE;
	REG_VAL = RAMPAGE_RAMSPECCY + L2_BANK + 3;
	setPalette(PALETTE_L2_0, (unsigned char *)0);
	setPalette(PALETTE_TILEMAP_0, (unsigned char *)0x200);

	// Copy the tilemap data up to RAM5.
	REG_NUM = REG_RAMPAGE;
	REG_VAL = RAMPAGE_RAMSPECCY + L2_BANK + 4;
	memcpy((unsigned char*)0x4000, (unsigned char)0, 0x2000);

	// Set up and enable the tilemap.
	REG_NUM = REG_TILEMAP_ATTR;
	REG_VAL = 0x00;

	REG_NUM = REG_TILEMAP_BASE;
	REG_VAL = 0x40;

	REG_NUM = REG_TILEDEF_BASE;
	REG_VAL = 0x45;

	REG_NUM = REG_TILEMAP_CTRL;
	REG_VAL = 0xa1;		// enable, no attribs, no ULA

	// Set transparency and fallback to black so that the magentas show up.
	REG_NUM = REG_TRANSPARENCY;
	REG_VAL = 0;
	REG_NUM = REG_FALLBACK;
	REG_VAL = 0;

	// Make layer 2 visible.
	L2PORT = 0x02;

	// Show border around the outside.
	ULAPORT = 0x04;

	// If "N" is still being held from previous mode, wait until released.
	while ((HROW7 & 0x08) == 0);

	for (l = 0; l < 0x17fff; l++)
	{
		if ((l & 0xfff) == 0)
		{
        		l2_gotoxy(7*8,20*8+4);
			if ((l & 0x1000) == 0)
			{
				l2_prints("ENTER selects mode");
				l2_gotoxy(8*8+4,21*8+4);
				l2_prints("N skips to next");
			}
			else
			{
				l2_prints("                  ");
				l2_gotoxy(8*8+4,21*8+4);
				l2_prints("               ");
			}
		}

		if (l == 5000)
		{
			aySend(AY_REG_TONE_COARSE_A, 0x00);
			aySend(AY_REG_TONE_FINE_A, 0xfc); // 0x7e
			aySend(AY_REG_MIXER, 0xfe);
			aySend(AY_REG_VOLUME_A, 0x0f);
		}

		if (l == 18000)
		{
			ayOff();
		}

		// Select this mode if ENTER is pressed.
		if ((HROW6 & 0x01) == 0)
		{
			// Turn off AY, layer 2 and tilemap,
			// and set border back to black.
			ayOff();
			vdp_cls();
			L2PORT = 0x00;
			REG_NUM = REG_TILEMAP_CTRL;
			REG_VAL = 0x00;
			ULAPORT = 0x00;
		
			// Reset the layer 2 palette to defaults.
			setOrderedPalette(PALETTE_L2_0);

			// Turn off video mode cycling.
			videoTestInit(eVidTestNone);

			// Update config.ini with current mode settings.
			settings[eSettingTiming] = curtestmode.timing;
			settings[eSettingFreq5060] = curtestmode.freq;
			settings[eSettingScandoubler] = curtestmode.doubler;
			save_config();

			return 1;
		}

		// Skip this mode if N is pressed.
		if ((HROW7 & 0x08) == 0)
		{
			return 0;
		}

		// Exit with new mode range if chosen with key A/V/H/S.
		if (videoTestReselect())
		{
			REG_NUM = REG_RAMPAGE;
			REG_VAL = RAMPAGE_ROMSPECCY;

			*pVidTestMode = vidtestmode;
			*pVidTestIter = 0xff;	// will be incremented
			return 0;
		}
	}

	// No need to reset anything as this func will shortly be re-run.
	return 0;
}

void videoTestCycle()
{
	while (1)
	{
		REG_NUM = REG_RAMPAGE;
		REG_VAL = RAMPAGE_ROMSPECCY;

		vidtestmode = *pVidTestMode;
		l2black = *pVidTestBlack;
		l2white = *pVidTestWhite;

		curtestmode = (modeTables[vidtestmode])[*pVidTestIter];

		if (curtestmode.timing != 255)
		{
			if (videoTestMode())
			{
				// Exit if mode successfully selected.
				return;
			}

			// Re-select test mode data RAM page.
			REG_NUM = REG_RAMPAGE;
			REG_VAL = RAMPAGE_ROMSPECCY;

			// If not selected, step to next mode.
			*pVidTestIter = *pVidTestIter + 1;
		}
		else
		{
			// Look back to table start if end reached.
			*pVidTestIter = 0;
		}
	}
}
