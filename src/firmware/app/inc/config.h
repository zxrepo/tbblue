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

#ifndef _CONFIG_H
#define _CONFIG_H

#define MIN(a,b) 	(((a)<(b))?(a):(b))
#define MAX(a,b) 	(((a)>(b))?(a):(b))
#define CLAMP(a,b) 	((MAX(0,(MIN(a,b)))))

#define	MAX_DIVMMC	1
#define	MAX_DIVPORTS	1
#define	MAX_KMOUSE	1
#define MAX_MF		1
#define	MAX_FREQ5060	1
#define MAX_TIMEX	1
#define	MAX_PSGMODE	2
#define	MAX_INTSND	1
#define	MAX_TURBOSOUND	1
#define	MAX_COVOX	1
#define	MAX_STEREOMODE	1
#define	MAX_SCANDOUBLER	1
#define	MAX_SCANLINES	3
#define	MAX_TURBO	1
#define	MAX_JOYSTICK1	6
#define MAX_JOYSTICK2	6
#define MAX_PS2		1
#define	MAX_DAC		1
#define MAX_LIGHTPEN	1

#endif // _CONFIG_H
