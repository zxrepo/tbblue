;  TBBlue / ZX Spectrum Next project
;--------------------------------------------------------------------------
;  crt0.s - Generic crt0.s for a Z80
;
;  Copyright (C) 2000, Michael Hope
;  Copyright (C) 2015, Fabio Belavenuto & Victor Trucco
;
;  This library is free software; you can redistribute it and/or modify it
;  under the terms of the GNU General Public License as published by the
;  Free Software Foundation; either version 2, or (at your option) any
;  later version.
;
;  This library is distributed in the hope that it will be useful,
;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;  GNU General Public License for more details.
;
;  You should have received a copy of the GNU General Public License 
;  along with this library; see the file COPYING. If not, write to the
;  Free Software Foundation, 51 Franklin Street, Fifth Floor, Boston,
;   MA 02110-1301, USA.
;
;  As a special exception, if you link this library with other files,
;  some of which are compiled with SDCC, to produce an executable,
;  this library does not by itself cause the resulting executable to
;  be covered by the GNU General Public License. This exception does
;  not however invalidate any other reasons why the executable file
;   might be covered by the GNU General Public License.
;--------------------------------------------------------------------------

	.module crt0
	.globl	_main
	.globl  l__INITIALIZER
	.globl  s__INITIALIZED
	.globl  s__INITIALIZER
	.globl	l__DATA
	.globl	s__DATA

	.area	_HEADER (ABS)
	;; Reset vector
	.org 	0x6000
	;; Stack at the top of memory.
	ld		sp, #0xFFFF
	di
	;; Initialise global variables
	call    gsinit
	call	_main
	jp		_exit

	;; Ordering of segments for the linker.
	.area	_HOME
	.area	_CODE
	.area	_INITIALIZER

	.area   _GSINIT
	.area   _GSFINAL

	.area	_DATA
	.area	_INITIALIZED

	.area	_BSEG
	.area   _BSS
	.area   _HEAP

	.area   _CODE

_exit::
1$:
	halt
	jr		1$

	.area	_GSINIT
gsinit::
	ld		bc, #l__DATA
	ld		a, b
	or		a, c
	jr		z,gsinit_initialized
	ld		hl, #s__DATA
	ld		de, #s__DATA+1
	ld		(hl), #0
	dec		bc
	ld		a, b
	or		a, c
	jr		z,gsinit_initialized
	ldir
gsinit_initialized:
	ld		bc, #l__INITIALIZER
	ld		a, b
	or		a, c
	jr z,	gsinit_next
	ld		de, #s__INITIALIZED
	ld		hl, #s__INITIALIZER
	ldir
gsinit_next:
	.area   _GSFINAL
	ret
