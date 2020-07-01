///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
#ifndef DOT_COMMAND_SHARED
#define DOT_COMMAND_SHARED

#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <errno.h>
#include <input.h>
#include <z80.h>
#include <arch/zxn/esxdos.h>
#include <arch/zxn.h>
#include <libgen.h>

///////////////////////////////////////////////////////////
// ( these defines are to keep codestyle the same and
//   also handle the fact the hardware has progressed ) 
///////////////////////////////////////////////////////////
#define RTM_28MHZ	3

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
extern void CommonInit(void);
extern int PrintFormatted(char *fmt, ...);
extern void PrintErrorMessage(unsigned int error);
extern char* MakeNicePath(char* str);

extern unsigned char pathname[];

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
extern unsigned char _z_page_sz;
extern unsigned char _z_page_table[];

extern unsigned char _z_extra_sz;
extern unsigned char _z_extra_table[];

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
extern void rom_cls(void);

///////////////////////////////////////////////////////////
//
///////////////////////////////////////////////////////////
#endif //DOT_COMMAND_SHARED
