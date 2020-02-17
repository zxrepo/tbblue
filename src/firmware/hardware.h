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

#ifndef _HARDWARE_H
#define _HARDWARE_H

__sfr __at 0xE7 SD_CONTROL;
__sfr __at 0xE7 SD_STATUS;
__sfr __at 0xEB SD_DATA;
__sfr __at 0xFB ZXPRINTERPORT;
__sfr __at 0xFE ULAPORT;
__sfr __banked __at 0x243B REG_NUM;
__sfr __banked __at 0x253B REG_VAL;
__sfr __banked __at 0x123B L2PORT;
__sfr __banked __at 0x103B LED;
__sfr __banked __at 0xfffd AY_REG;
__sfr __banked __at 0xbffd AY_DATA;

/* Keyboard */
__sfr __banked __at 0xFEFE HROW0; // SHIFT,Z,X,C,V
__sfr __banked __at 0xFDFE HROW1; // A,S,D,F,G
__sfr __banked __at 0xFBFE HROW2; // Q,W,E,R,T
__sfr __banked __at 0xF7FE HROW3; // 1,2,3,4,5
__sfr __banked __at 0xEFFE HROW4; // 0,9,8,7,6
__sfr __banked __at 0xDFFE HROW5; // P,O,I,U,Y
__sfr __banked __at 0xBFFE HROW6; // ENTER,L,K,J,H
__sfr __banked __at 0x7FFE HROW7; // SPACE,SYM SHFT,M,N,B

#define peek(A) (*(volatile unsigned char*)(A))
#define poke(A,V) *(volatile unsigned char*)(A)=(V)
#define peek16(A) (*(volatile unsigned int*)(A))
#define poke16(A,V) *(volatile unsigned int*)(A)=(V)

/* Filenames */
#define NEXT_UPDATE_FILE    "TBBLUE  TBU"
#define NEXT_UPDATE_FILE2   "TBBLUE.TBU"
#define NEXT_FIRMWARE_FILE  "TBBLUE  FW "
#define NEXT_FIRMWARE_FILE2 "TBBLUE.FW"
#define NEXT_DIRECTORY      "/machines/next/"
#define CONFIG_FILE         NEXT_DIRECTORY "config.ini"
#define TIMING_FILE         NEXT_DIRECTORY "timing.ini"
#define ESXMMC_FILE         "esxmmc.bin"
#define MF1_FILE            "mf1.rom"
#define MF3_FILE            "mf3.rom"
#define MF128_FILE          "mf128.rom"
#define KEYMAP_FILE         "keymap.bin"

/* Hardware IDs */
#define HWID_DE1A		0x01		/* DE-1 */
#define HWID_DE2A		0x02		/* DE-2  */
//#define HWID_DE2N		0x03		/* DE-2 (new) */
//#define HWID_DE1N		0x04		/* DE-1 (new) */
#define HWID_FBLABS		0x05		/* FBLabs */
#define HWID_VTRUCCO		0x06		/* VTrucco */
#define HWID_WXEDA		0x07		/* WXEDA */
#define HWID_EMULATORS		0x08		/* Emulators */
#define HWID_MC		0x0b		/* Multicore */
#define HWID_ZXNEXT		0x0a		/* ZX Spectrum Next */
#define HWID_ZXDOS		0xea		/* ZX DOS (Next clone mode) */
#define HWID_ZXNEXT_AB		0xfa		/* ZX Spectrum Next Anti-brick */

/* Register numbers */
#define REG_MACHID		0x00
#define REG_VERSION		0x01
#define REG_RESET		0x02
#define REG_MACHTYPE		0x03
#define REG_RAMPAGE		0x04
#define REG_PERIPH1		0x05
#define REG_PERIPH2		0x06
#define REG_TURBO		0x07
#define REG_PERIPH3		0x08
#define REG_PERIPH4		0x09
#define REG_VERSION_SUB 	0x0e
#define REG_ANTIBRICK		0x10
#define REG_VIDEOT		0x11
#define REG_L2BANK		0x12
#define REG_TRANSPARENCY	0x14
#define	REG_SLU_MODE		0x15
#define REG_KMHA		0x28
#define REG_KMLA		0x29
#define REG_KMHD		0x2a
#define REG_KMLD		0x2b
#define REG_PAL_INDEX		0x40
#define REG_PAL_VALUE_8		0x41
#define REG_PAL_CTRL		0x43
#define REG_PAL_VALUE_9		0x44
#define REG_FALLBACK		0x4a
#define REG_CUCTRL_LO		0x61
#define REG_CUCTRL_HI		0x62
#define REG_TILEMAP_CTRL	0x6b
#define REG_TILEMAP_ATTR	0x6c
#define REG_TILEMAP_BASE	0x6e
#define REG_TILEDEF_BASE	0x6f
#define REG_EXPBUS_CTRL		0x80
#define REG_DECODE_INT0		0x82
#define REG_DECODE_INT1		0x83
#define REG_DECODE_INT2		0x84
#define REG_DECODE_INT3		0x85
#define REG_DECODE_EXP0		0x86
#define REG_DECODE_EXP1		0x87
#define REG_DECODE_EXP2		0x88
#define REG_DECODE_EXP3		0x89
#define REG_DEBUG		0xFF

/* AY register numbers */
#define AY_REG_TONE_FINE_A	0x00
#define AY_REG_TONE_COARSE_A	0x01
#define AY_REG_TONE_FINE_B	0x02
#define AY_REG_TONE_COARSE_B	0x03
#define AY_REG_TONE_FINE_C	0x04
#define AY_REG_TONE_COARSE_C	0x05
#define AY_REG_NOISE_PITCH	0x06
#define AY_REG_MIXER		0x07
#define AY_REG_VOLUME_A		0x08
#define AY_REG_VOLUME_B		0x09
#define AY_REG_VOLUME_C		0x0a
#define AY_REG_ENV_FINE 	0x0b
#define AY_REG_ENV_COARSE	0x0c

/* Reset types */
#define RESET_POWERON	4
#define RESET_HARD		2
#define RESET_SOFT		1
#define RESET_NONE		0

/* Anti-brick */
#define AB_CMD_NORMALCORE	0x80
#define AB_BTN_DIVMMC		0x02
#define AB_BTN_MULTIFACE	0x01

/* RAM pages */
#define RAMPAGE_RAMDIVMMC	0x08 /* 0x00 */
#define RAMPAGE_ROMDIVMMC	0x04 /* 0x18 */
#define RAMPAGE_ROMMF		0x05 /* 0x19 */
#define RAMPAGE_ROMSPECCY	0x00 /* 0x1C */
#define RAMPAGE_RAMSPECCY	0x10	// start of standard ZX RAM

/* Palette ids */
#define PALETTE_ULA_0		0x00
#define PALETTE_ULA_1		0x40
#define PALETTE_L2_0		0x10
#define PALETTE_L2_1		0x50
#define PALETTE_SPRITES_0	0x20
#define PALETTE_SPRITES_1	0x60
#define PALETTE_TILEMAP_0	0x30
#define PALETTE_TILEMAP_1	0x70

/* Firmware block numbers */
#define FW_BLK_BOOT		0
#define FW_BLK_EDITOR		1
#define FW_BLK_UPDATER		2
#define FW_BLK_CORES		3
#define FW_BLK_TBBLUE_SCR	4
#define FW_BLK_NEXT_SCR	5
#define FW_BLK_ZXDOS_SCR	6
#define FW_BLK_TESTCARD_SCR	7
#define FW_BLK_TESTCARD_L2PAL	8
#define FW_BLK_TESTCARD_TMPAL	9
#define FW_BLK_TESTCARD_TMDATA	10

#endif /* _HARDWARE_H */
