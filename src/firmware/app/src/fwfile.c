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

static FIL FilFW;
static unsigned char fwMap[512];
static unsigned char scratch[512];

void fwOpenAndSeek(unsigned int startblk)
{
	unsigned int bl, initial_block;
	unsigned int error_count = 100;

START:
	--error_count;

	res = f_open(&FilFW, NEXT_FIRMWARE_FILE2, FA_READ);
	if (res != FR_OK) {
		if (error_count > 0) {
			goto START;
		}
		//             12345678901234567890123456789012
		display_error( "Error opening TBBLUE.FW file" );
	}

	// Load the block start/length info.
	res = f_read(&FilFW, fwMap, 512, &bl);
	if (res != FR_OK || bl != 512)
	{
		//             12345678901234567890123456789012
		display_error( "Error reading TBBLUE.FW map!");
	}

	initial_block =    fwMap[ startblk*4   ]
			+ (fwMap[(startblk*4)+1] * 256);

	// Skip blocks
	while (initial_block > 0)
	{
		res = f_read(&FilFW, scratch, 512, &bl);

		if (res != FR_OK || bl != 512) {
			//             12345678901234567890123456789012
			display_error( "Error seeking within TBBLUE.FW");
		}
		
		initial_block--;
	}
}

unsigned int fwBlockLength(unsigned int startblk)
{
	// Return the number of 512-byte blocks.
	return fwMap[(startblk*4)+2]
		+ (fwMap[(startblk*4)+3] * 256);
}

void fwRead(unsigned char * pDest, unsigned int length)
{
	unsigned int bl;

	res = f_read(&FilFW, pDest, length, &bl);
	if (res != FR_OK || bl != length)
	{
		//             12345678901234567890123456789012
		display_error( "Error reading TBBLUE.FW data!");
	}
}

void fwClose()
{
	f_close(&FilFW);
}
