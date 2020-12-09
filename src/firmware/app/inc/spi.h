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
/*
  TBBlue / ZX Spectrum Next project
  Copyright (c) 2015 Fabio Belavenuto & Victor Trucco
*/

#ifndef SPI_H
#define SPI_H

// EPCS4 cmds
#define cmd_write_enable        0x06
#define cmd_write_disable       0x04
#define cmd_read_status         0x05
#define cmd_read_bytes          0x03
#define cmd_read_id             0xAB
#define cmd_fast_read           0x0B
#define cmd_write_status        0x01
#define cmd_write_bytes         0x02
#define cmd_erase_bulk          0xC7
#define cmd_erase_block64       0xD8            // Block Erase 64K

void SPI_sendcmd(unsigned char cmd);
void SPI_cshigh(void);
unsigned char SPI_sendcmd_recv(unsigned char cmd);
void SPI_send4bytes(unsigned char *buffer);
void SPI_receive(unsigned char *buffer, unsigned char pages);
void SPI_writebytes(unsigned char *buffer);

#endif

