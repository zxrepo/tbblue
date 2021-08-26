/*
ZX Spectrum Next Firmware
Copyright 2020 Garry Lancaster

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

#ifndef _VIDEOMAGIC_H
#define _VIDEOMAGIC_H

enum {
        eVidTestNone = 0,
        eVidTestAll,
        eVidTestDigital,
        eVidTestRGB,
        eVidTestVGA,
};

#define VIDMAGIC_OFFSET 0
#define VIDMAGIC_LEN 9
#define VIDMODE_OFFSET (VIDMAGIC_OFFSET + VIDMAGIC_LEN)
#define VIDITER_OFFSET (VIDMODE_OFFSET + 1)
#define VIDBLACK_OFFSET (VIDITER_OFFSET + 1)
#define VIDWHITE_OFFSET (VIDBLACK_OFFSET + 1)

extern unsigned char * strVidMagic;
extern unsigned char *pVidMagic;
extern unsigned char *pVidTestMode;
extern unsigned char *pVidTestIter;
extern unsigned char *pVidTestBlack;
extern unsigned char *pVidTestWhite;
extern unsigned char vidtestmode;

unsigned char videoTestActive();
unsigned char videoTestReselect();

#endif // _VIDEOMAGIC_H