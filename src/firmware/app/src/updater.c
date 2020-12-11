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
#include <stdio.h>
#include <string.h>
#include "hardware.h"
#include "vdp.h"
#include "ff.h"
#include "spi.h"
#include "misc.h"
#include "config.h"

const char ce[5]   = "\\|/-";

FATFS           FatFs;          /* FatFs work area needed for each volume */
FIL                     Fil;            /* File object needed for each open file */
FRESULT         res;

unsigned char   buffer[512];
unsigned char   mach_id, mach_version,mach_version_sub;
unsigned char   mach_ab = 0;
unsigned char   cLed = 0;
unsigned char   byteoffset, cso;
unsigned char   l, file_mach_id, file_mach_version, vma, vmi, cs, csc, vsub;
unsigned int    bl, i, j;
unsigned long   fsize, dsize;


static unsigned char wait_resp() {
        unsigned char r = 0;
        unsigned char bts = 0;

        REG_NUM = REG_ANTIBRICK;


        while (1) {
                // key Y
                if ((HROW5 & (1 << 4)) == 0) {
                        r = 2;
                        break;
                }
                // key N
                if ((HROW7 & (1 << 3)) == 0) {
                        r = 3;
                        break;
                }

                bts = REG_VAL;


                if (bts & 1) //MF button, same as N
                {
                        r = 3;
                        break;
                }

                if (bts & 2) //Drive button, same as Y
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

        REG_NUM = REG_MACHID;
        mach_id = REG_VAL;
        REG_NUM = REG_VERSION;
        mach_version = REG_VAL;

        REG_NUM = REG_VERSION_SUB;
        mach_version_sub = REG_VAL;


        if (mach_id == HWID_ZXNEXT_AB) {
                mach_id = HWID_ZXNEXT;
                mach_ab = 1;
        }

        vdp_init();

        if (mach_ab == 0)
        {
                REG_NUM = REG_TURBO;
                REG_VAL = 3;

                // Read config.ini and honour the video settings.
                // Can't be done for AB cores on KS1 machines, since they do
                // not include video mode setting registers.
                load_config();
                update_video_settings();
        }
        else
        {
                REG_NUM = REG_TURBO;
                REG_VAL = 0;
        }

        vdp_setcolor(COLOR_BLACK, COLOR_BLUE, COLOR_WHITE);
        vdp_prints(TITLE);

        if (mach_ab > 0)
        {
                vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_RED);
                vdp_gotoxy(11, 2);
                vdp_prints("Anti-Brick\n\n");

                REG_NUM = REG_ANTIBRICK;
                while (REG_VAL & 3);
        }
        else
        {
                vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_LGREEN);
                vdp_gotoxy(13, 2);
                vdp_prints("Updater\n\n");
        }

        vdp_setcolor(COLOR_BLACK, COLOR_BLACK, COLOR_WHITE);

        if (mach_id != HWID_ZXNEXT)
        {
                vdp_prints("Not supported on this hardware!");
                for (;;) ;
        }

        //          12345678901234567890123456789012
        vdp_prints("Update file 'TBBLUE.TBU' found!\n\n");

        memset(buffer, 0, 512);

        f_mount(&FatFs, "", 0);                         /* Give a work area to the default drive */

        res = f_open(&Fil, NEXT_UPDATE_FILE2, FA_READ);
        if (res != FR_OK) {
                display_error("Error opening " NEXT_UPDATE_FILE2 " file");
        }
        fsize = f_size(&Fil);
        res = f_read(&Fil, buffer, 512, &bl);
        if (res != FR_OK || bl != 512) {
                display_error("Error reading " NEXT_UPDATE_FILE2 " file!");
        }
        if (0 == strncmp(buffer, "TBUFILE", 7)) {
                byteoffset = 0;
                cso = 0;
        } else if (0 == strncmp(buffer, "ZXNFILE", 7)) {
                byteoffset = 1;
                cso = 0xa1;
        } else {
                display_error("Wrong Magic!");
        }
        memcpy(&dsize, buffer+7, 4);
        if (fsize != dsize + 512) {
                sprintf(line, "Wrong size, %ld != %ld", fsize, dsize);
                display_error(line);
        }
        file_mach_id = buffer[11];
        file_mach_version = buffer[12];
        vma = file_mach_version >> 4;
        vmi = file_mach_version & 0x0F;
        cs = buffer[13];
        vsub= buffer[500];

        vdp_setfg(COLOR_WHITE);
        vdp_gotox(13);
        vdp_prints("Version\n");

        if (mach_ab > 0)
        {
                vdp_gotox(14);
        }
        else
        {
                sprintf(line, "%d.%02d.%02d  ->  ", mach_version >> 4, mach_version & 0x0F, mach_version_sub);
                vdp_gotox(6);
                vdp_prints(line);
        }

        vdp_setfg(COLOR_LCYAN);
        sprintf(line, "%d.%02d.%02d\n\n", vma, vmi, vsub);
        vdp_prints(line);

        vdp_setfg(COLOR_WHITE);
        vdp_gotox(15);
        vdp_prints("ID\n");
        sprintf(line, "%d  ->  ", mach_id);
        vdp_gotox(11);
        vdp_prints(line);
        vdp_setfg(COLOR_LCYAN);
        sprintf(line, "%d\n\n", file_mach_id);
        vdp_prints(line);
        vdp_setfg(COLOR_WHITE);

        vdp_gotox(12);
        vdp_prints("HARDWARE\n");
        vdp_setfg(COLOR_LCYAN);
        for (l = 0; l < 16 - strlen(buffer + 14) / 2; l++) {
                vdp_prints(" ");
        }

        vdp_prints(buffer + 14);
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
                REG_VAL = RESET_HARD;                   // Hard-reset
        }
        vdp_prints("y\n\n");

        if (file_mach_id != mach_id) {
                display_error("Wrong Hardware!");
        }

        // Read flash ID
        // EPCS4     = 0x12
        // W25Q32BV  = 0x15
        // W25Q128JV = 0x17
        buffer[0] = cmd_read_id;
        SPI_send4bytes(buffer);
        SPI_receive(buffer, 1);
        SPI_cshigh();

        if ( (buffer[0] != 0x15) && (buffer[0] != 0x17) )
        {
                display_error("Flash not detected!");
        }

        vdp_prints("Checksum calculating...");

        REG_NUM = REG_DEBUG;

        csc = cso;
        l = 0;
        while (!f_eof(&Fil))
        {
                //blink the debug Led
                if (cLed == 0) cLed = 1; else cLed = 0; LED = cLed;

                res = f_read(&Fil, buffer, 512, &bl);
                if (res != FR_OK || bl != 512)
                {
                        display_error("Error reading block!");
                }
                for (j = 0; j < 512; j++)
                {
                        csc ^= buffer[j] + byteoffset;
                }
                vdp_putchar(ce[l]);
                vdp_putchar(8);
                l = (l + 1) & 0x03;

        }

        f_close(&Fil);

        if (cs != csc)
        {
                sprintf(line, "CS error: %02X %02X", cs, csc);
                display_error(line);
        }
        vdp_prints("OK\n");

        vdp_prints("Upgrading:\n");

        vdp_prints("Erasing Flash: ");

        if (mach_id == HWID_ZXNEXT)
        {

                buffer[0] = cmd_erase_block64;
                buffer[1] = 0x08;
                buffer[2] = 0x00;
                buffer[3] = 0x00;

                for (i = 0; i < 8; i++)
                {
                        SPI_sendcmd(cmd_write_enable);
                        SPI_send4bytes(buffer); // send the command to erase a 64kb block
                        SPI_cshigh();
                        ++buffer[1]; // next 64kb block
                        while ((SPI_sendcmd_recv(cmd_read_status) & 0x01) == 1) ;

                        //repeat 8 times, to erase a 512kb block
                }
        }
        else
        {
                SPI_sendcmd(cmd_write_enable);
                SPI_sendcmd(cmd_erase_bulk);
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

        f_mount(&FatFs, "", 0);                         /* Give a work area to the default drive */
        res = f_open(&Fil, NEXT_UPDATE_FILE2, FA_READ);
        if (res != FR_OK) {
                display_error("Error opening '" NEXT_UPDATE_FILE2 "' file!");
        }
        res = f_read(&Fil, buffer, 512, &bl);
        if (res != FR_OK || bl != 512) {
                display_error("Error reading '" NEXT_UPDATE_FILE2 "' file!");
        }

        if (mach_id == HWID_ZXNEXT)
        {
                dsize = 0x080000;
        }
        else
        {
                dsize = 0;
        }

        l = 0;
        while (!f_eof(&Fil))
        {
                buffer[0] = cmd_write_bytes;
                buffer[1] = (dsize >> 16) & 0xFF;
                buffer[2] = (dsize >> 8) & 0xFF;
                buffer[3] = dsize & 0xFF;

                res = f_read(&Fil, buffer+4, 256, &bl);

                if (res != FR_OK || bl != 256)
                {
                        display_error("Error reading block!");
                }

                for (i = 4; i < 4+256; i++)
                {
                        buffer[i] = buffer[i] + byteoffset;
                }

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
