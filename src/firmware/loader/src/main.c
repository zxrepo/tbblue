/*
ZX Spectrum Next Firmware
Copyright 2020 Garry Lancaster, Fabio Belavenuto & Victor Trucco

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
#include "mmc.h"
#include "fat.h"

/* Defines */

//#define DEBUG(x) REG_NUM = REG_DEBUG; REG_VAL = x;

#define MODULE_BOOT_INDEX               0
#define MODULE_EDITOR_INDEX             1
#define MODULE_UPDATER_INDEX    2
#define MODULE_CORES_INDEX              3

/* Variables */

static unsigned char error_count, l;
static const char * fn_update   = NEXT_UPDATE_FILE;
static const char * fn_firmware = NEXT_FIRMWARE_FILE;
static unsigned char buffer[512];

/* Private functions */

/*******************************************************************************/
static void display_error(unsigned char *message)
{
        unsigned char v;
        unsigned int c;

        v = (0 << 7) | (1 << 6) | (COLOR_BLACK << 3) | COLOR_GRAY;
        for (c = CT_BASE; c < (CT_BASE+768); c++)
                poke(c, v);

        DisableCard();
        l = 16 - strlen(message)/2;
        ULAPORT = COLOR_RED;
        vdp_gotoxy(l, 12);
        vdp_prints(message);
        for(;;);
}

/* Public functions */

/*******************************************************************************/
void main()
{
        unsigned char *mem   = (unsigned char *)0x6000;
        unsigned char module, have_tbu, have_update;
        unsigned char mach_id, mach_version, reset_type, buttons;
        unsigned int c = 0, initial_block, blocks;
        fileTYPE file;

//      DEBUG(1)
        ULAPORT = COLOR_BLACK;                          // Blue border
        REG_NUM = REG_MACHID;
        mach_id = REG_VAL;
        REG_NUM = REG_VERSION;
        mach_version = REG_VAL;
        REG_NUM = REG_RESET;
        reset_type = REG_VAL & RESET_POWERON;
        REG_NUM = REG_ANTIBRICK;
        buttons = REG_VAL & (AB_BTN_DIVMMC | AB_BTN_MULTIFACE);

        //capture if some key was pressed
        module = MODULE_BOOT_INDEX;                     // Load module 'boot'
        if (((HROW7 & 0x01) == 0) && ((HROW0 & 0x01) ==1)) {
                // SPACE key pressed, load module 'editor'
                module = MODULE_EDITOR_INDEX;
        }

        vdp_init();

//      vdp_gotoxy(11, 0);
//      vdp_prints("Loading...");
//      DEBUG(2)
        error_count = 10;
        while(error_count > 0) {
                if (!MMC_Init()) {
                        //             01234567890123456789012345678901
                        display_error("Error initializing SD card!");
                }
//              DEBUG(3)
                if (!FindDrive()) {
                        --error_count;
                        for (c = 0; c < 65000; c++);
                } else {
                        break;
                }
        }
        if (error_count == 0) {
                //             01234567890123456789012345678901
                display_error("Error mounting SD card!");
        }
//      DEBUG(4)
        // Test whether there is update file.
        have_tbu = 0;
        have_update = 0;

        if (FileOpen(&file, fn_update)) {
                have_tbu = 1;
        }
        if ((HROW5 & 0x08) == 0) {                      // u key pressed
                have_update = 1;
        }
        // If anti-brick core
        if (mach_id == HWID_ZXNEXT_AB) {
                if (buttons == (AB_BTN_DIVMMC | AB_BTN_MULTIFACE)) {
                        have_update = 1;
                } else {
                        REG_NUM = REG_ANTIBRICK;
                        REG_VAL = AB_CMD_NORMALCORE;            // Load normal core
                        for(;;);
                }
        }
        if (!FileOpen(&file, fn_firmware)) {
                //             01234567890123456789012345678901
                display_error("Error opening TBBLUE.FW file");
        }
//      DEBUG(5)
        if (!FileRead(&file, buffer)) {
                //             01234567890123456789012345678901
                display_error("Error reading TBBLUE.FW file");
        }
//      DEBUG(6)
        if (have_tbu == 1 && have_update == 1) {        // There is upgrade, load module 'updater'
                module = MODULE_UPDATER_INDEX;
        }

        //load the extra cores update module
        if ((HROW0 & 0x08) == 0) {                      // C key pressed
                module = MODULE_CORES_INDEX;
        }


//      DEBUG(7)
        initial_block = buffer[module * 4]     + buffer[module * 4 + 1] * 256;
        blocks        = buffer[module * 4 + 2] + buffer[module * 4 + 3] * 256;
//      DEBUG(8)
        // Skip blocks
        while (c < initial_block) {
                if (!FileRead(&file, buffer)) {
                        //             01234567890123456789012345678901
                        display_error("Error reading TBBLUE.FW file");
                }
                c++;
        }
//      DEBUG(9)
        c = 0;
        // Read blocks
        while (c < blocks) {
                if (!FileRead(&file, mem)) {
                        //             01234567890123456789012345678901
                        display_error("Error reading TBBLUE.FW file");
                }
                c++;
                mem += 512;
        }
        DisableCard();
        __asm__("jp 0x6000");   // Start firmware
}
