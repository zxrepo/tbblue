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

#ifndef _VIDEOTEST_H
#define _VIDEOTEST_H

enum {
	eVidTestNone = 0,
	eVidTestAll,
	eVidTestHDMI,
	eVidTestSCART,
	eVidTestVGA,
};

typedef struct {
	unsigned char timing;
	unsigned char freq;
	unsigned char doubler;
} testmodeitem;

unsigned char videoTestActive();
void videoTestCycle();

#endif // _VIDEOTEST_H
