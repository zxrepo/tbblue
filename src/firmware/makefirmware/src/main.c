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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

/* Defines */
#define NUMMODULES 4
#define NUMSCREENS 2

#define MAX_PATH 254
/* Variables */

const char moduledirectory[] = "..//app//";
const char screendirectory[] = "..//screen//";
const char *module_files[NUMMODULES] = {
	"boot.bin",
	"editor.bin",
	"updater.bin",
	"cores.bin"
};
const char *screen_files[NUMSCREENS] = {
	"screen0.scr",
	"screen1.scr"
};

/* Public functions */

// =============================================================================
int main(int argc, char *argv[]) {
	FILE			*fileBin = NULL, *fileFw = NULL;
	char			path[MAX_PATH];
	unsigned char	pB[512], buffer[512];
	int				size, blocks, blockA=0, cb=0, i, c;

	if (!(fileFw = fopen("TBBLUE.FW", "wb"))) {
		fprintf(stderr, "Error creating TBBLUE.FW file\n");
		return -1;
	}

	memset(pB, 0, 512);
	fwrite(pB, 1, 512, fileFw);

	// Embed modules
	for (i = 0; i < NUMMODULES; i++) {
		strcpy(path, moduledirectory);
		strcat(path, module_files[i]);
		if (!(fileBin = fopen(path, "rb"))) {
			fprintf(stderr, "Error opening '%s'\n", path);
			fclose(fileFw);
			return -1;
		}
		fseek(fileBin, 0, SEEK_END);
		size = ftell(fileBin);
		fseek(fileBin, 0, SEEK_SET);
		printf("Processing file '%s', filesize %d\n", path, size);

		blocks = (size + 511) / 512;
		pB[cb++] = blockA % 256;	pB[cb++] = blockA / 256;
		pB[cb++] = blocks % 256;	pB[cb++] = blocks / 256;
		blockA += blocks;
		c = 0;
		while(c < size) {
			memset(buffer, 0, 512);
			fread(buffer, 1, 512, fileBin);
			fwrite(buffer, 1, 512, fileFw);
			c += 512;
		}
		fclose(fileBin);
	}

	// Embed screens
	for (i = 0; i < NUMSCREENS; i++) {
		strcpy(path, screendirectory);
		strcat(path, screen_files[i]);
		if (!(fileBin = fopen(path, "rb"))) {
			fprintf(stderr, "Error opening '%s'\n", path);
			fclose(fileFw);
			return -1;
		}
		fseek(fileBin, 0, SEEK_END);
		size = ftell(fileBin);
		fseek(fileBin, 0, SEEK_SET);
		printf("Processing file '%s', filesize %d\n", path, size);

		blocks = (size + 511) / 512;
		pB[cb++] = blockA % 256;	pB[cb++] = blockA / 256;
		pB[cb++] = blocks % 256;	pB[cb++] = blocks / 256;
		blockA += blocks;
		c = 0;
		while(c < size) {
			memset(buffer, 0, 512);
			fread(buffer, 1, 512, fileBin);
			fwrite(buffer, 1, 512, fileFw);
			c += 512;
		}
		fclose(fileBin);
	}

	fseek(fileFw, 0, SEEK_SET);
	fwrite(pB, 1, 512, fileFw);
	fclose(fileFw);

	printf("TBBLUE.FW created!\n");

	return 0;
}
