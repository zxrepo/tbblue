;
; TBBlue / ZX Spectrum Next project
; Copyright (c) 2010-2018 
;
; PI2C - Tim Gilberts and Victor Trucco
;
; All rights reserved
;
; Redistribution and use in source and synthezised forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; Redistributions of source code must retain the above copyright notice,
; this list of conditions and the following disclaimer.
;
; Redistributions in synthesized form must reproduce the above copyright
; notice, this list of conditions and the following disclaimer in the
; documentation and/or other materials provided with the distribution.
;
; Neither the name of the author nor the names of other contributors may
; be used to endorse or promote products derived from this software without
; specific prior written permission.
;
; THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
; THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
; PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.
;
; You are responsible for any legal issues arising from your use of this code.
;
;-------------------------------------------------------------------------------
;
; .PI2C for ESXDOS
;
; Talk to the PI over i2c - given it an arbitrary address of the digital ver
; of the answer to everything $42

	org 0x2000

	defc PORT = 0x3B
	defc PORT_CLOCK = 0x10 ;0x103b
	defc PORT_DATA = 0x11 ;0x113b
  
MAIN:
	
	XOR A
	LD (CHKACK),A

	ld a,h
	or l
	JP z,CHECK_PI   ;if we dont have parameters it is a read command

	CALL IGSPA

	CP '-'		;if first char not an options flag
	JR NZ,end_error

	INC HL
	
	LD A,(HL)
	CP 'd'		; 
	JR NZ,NO_DEBUG

	LD A,$80
	LD (CHKACK),A	

	INC HL
	LD A,(HL)
	CP ' '
	JP NZ,end_error

	CALL IGSPA

	CP '-'
	JP NZ,end_error

	INC HL
	LD A,(HL)

NO_DEBUG:		
	CP 'w'		; Write bytes
	JP Z,WRITE_PI
	
	CP 'r'		; Read bytes
	JP Z,READ_PI

	JP end_error	; Give them help for all other stuff

;---------------------
IGSPA:	LD A,(HL)
	CP ' '
	RET NZ
	INC HL
	JR IGSPA


;----------------------------------------------	
CHECK_PI:

	LD A,1
	LD (BYTCNT),A

	CALL READ_PI_DO
	JR C,no_ack_error

	LD HL,PiACKmessage
	JR print_message

no_ack_error:
	LD HL,NoACKmessage
	JR print_message

debug_error:
	CALL prt_hex
	LD HL, ErrorMessage
	CALL print
	
end_error:
	LD HL, MsgUsage

print_message:
	CALL print	
	ret

;---------------------------------------------------
READ_PI:
	PUSH HL
	LD HL,ReadingMessage
	CALL print
	POP HL

	INC HL
	;HL point to parameters so get no of bytes to write
	CALL CONVERT_HEX_DEC
	JP C,debug_error; return to basic with error message
	CP 65			;Cant be more than 64 bytes
	JR NC,debug_error
	
	PUSH HL
	LD (BYTCNT),A ; store in the table
	CALL prt_hex
	LD HL,ReadingNoBytes
	CALL print
	POP HL

	CALL READ_PI_DO
	JR C,no_ack_error
	
	LD A,(BYTCNT)
	LD HL,BUFFER
	CALL print_bytes

	CALL print_newline
		
	RET
	

READ_PI_DO:	
	call START_SEQUENCE
	
	ld l,0x84		;7bit Address 0x42 + 8th 1 Bit for read data 
	call SEND_DATA
	JP C, STOP_SEQUENCE_SCF
	
	LD A,(BYTCNT)
	ld l,A
	call SEND_DATA
	JP C, STOP_SEQUENCE_SCF
	
	call START_SEQUENCE
	
	ld l,0x85
	call SEND_DATA
	JP C, STOP_SEQUENCE_SCF
	
	;point to the first reg in table
	LD HL,BUFFER
	
	LD A,(BYTCNT)
	LD E,A
	
loop_read_bytes:
	call READ

	;point to next byte
	inc hl	
	
	;dec number of bytes
	dec e
	jr z, end_read_bytes
	
	;if don´t finish, send as ACK and loop
	call SEND_ACK
	jr loop_read_bytes

	;we just finished to read the I2C, send a NACK and STOP
end_read_bytes:
	LD A,1	
	call SEND_ACK_NACK
;	call SEND_NACK
	
	CALL STOP_SEQUENCE_CCF

	RET


	

;---------------------------------------------------
WRITE_PI:

	PUSH HL
	LD HL,WritingMessage
	CALL print
	POP HL

	LD DE,BUFFER
	LD C,64
	
LOOP_READ_BYTES:
	INC HL
	LD A,(HL)
	CP 13
	JR Z,DONE_READ_BYTES
	
	CALL CONVERT_HEX_DEC
	jr c,ERROR_READ_BYTES		; return to basic with error message if needed

	LD (DE),A 			; store in the table
	
	INC DE
	DEC C
	JR NZ,LOOP_READ_BYTES

DONE_READ_BYTES:
	LD A,64
	SUB C				; See how many bytes read
	JR NC,ALL64

	OR @10000000		;Set high bit as syntax flag
	
ERROR_READ_BYTES:
	JP debug_error		; None was a syntax error

ALL64:
;	INC A
	LD (BYTCNT),A
	
	CALL prt_hex
	LD HL,WritingNoBytes
	CALL print
	
	CALL WRITE_PI_DO
	
	JP C,no_ack_error

	RET	
	

WRITE_PI_DO:

	call START_SEQUENCE
	
	ld l,0x84 		;7bit Address 0x64 0110100 + 8th Zero Bit for write data
	call SEND_DATA
	JP C,STOP_SEQUENCE_SCF
	
	LD A,(BYTCNT)

	ld L,A 			;We are going to send xxxxx bytes *** TODO inc a checksum
	call SEND_DATA
	JP C,STOP_SEQUENCE_SCF

	LD A,(BYTCNT)
	LD DE,BUFFER
	
WRITE_PI_LOOP:
	PUSH AF	
	LD A,(DE)
	LD L,A
	call SEND_DATA
	JR C,STOP_SEQUENCE_SCF_POPAF
	INC DE
	POP AF
	DEC A
	JR NZ,WRITE_PI_LOOP

;	JP STOP_SEQUENCE_CCF
	
STOP_SEQUENCE_CCF:
	CALL SDA0
	CALL SCL1
	CALL SDA1
	EI
	RET

STOP_SEQUENCE_SCF_POPAF:
	POP AF

STOP_SEQUENCE_SCF:
	CALL SDA0
	CALL SCL1
	CALL SDA1
	EI
	SCF
	RET

;---------------------------------------------------
SEND_DATA:

	;8 bits
	ld h,8				;7
	
SEND_DATA_LOOP:	
	
	;next bit
	RLC L				;8
		
	ld a,L				;4
	CALL SDA			;17 + xxx
		
	call PULSE_CLOCK		;17 + xxx
		
	dec h				;4
	jr nz, SEND_DATA_LOOP		;12 or 7
		
WAIT_ACK:

	;free the line to wait the ACK
	CALL SDA1			;17 + xxx

;	JR PULSE_CLOCK			;12
	;so we now do the same but, check for an ACK coming back!
	;http://www.gammon.com.au/forum/?id=10896 useful to see the timing diagrams
	CALL SCL1			;17	;17 + 

	LD HL,4				;loop for a short while looking for the ACK
	
WAIT_ACK_LOOP:
	LD B,PORT_DATA			;7
	IN A,(C)			;12
	RRCA
	JR C,LINE_HIGH			
	
	INC H				;Something on the bus pulled SDA low - count how long
	
LINE_HIGH:
	DEC L
	JR NZ,WAIT_ACK_LOOP

	CALL SCL0			;If stitched back into RTC etc could be a JP to save a byte this will CCF due to XOR A

	LD A,H
	SUB 2				;Carry will be set if we did not receive at least duration 2 of pulse.

;Suppress ACK test if required.
	LD HL,CHKACK
	BIT 7,(HL)		;Does not affect carry
	RET Z			;if not supressed

	OR A			;Otherwise carry clear
	RET


;---------------------------------------------------
;-- Read 8 bits from the bus - no automatic ACK
READ:

;	free the data line
	CALL SDA1			;17 + xxx
	
; lets read 8 bits
	ld D,8				;7
			
READ_LOOP:
	;clock is high
	CALL SCL1			;17 + xxx
	
	;read the bit
	ld b,PORT_DATA			;7
	in a,(c)			;12

	RRCA				;4
	RL (HL)				;15
	
	;clock is low
	CALL SCL0			;17 + xxx
	
	dec d				;4
	
	;go to next bit
	jr nz, READ_LOOP		;12 or 7
	
	;finish the byte read
	ret				;10

;-- ACK the bus, if A-1 can enter to send a NACK at second entry
	
SEND_ACK:
	
	xor a  				;4
	
SEND_ACK_NACK:

	CALL SDA			;17 + xxx
	
	call PULSE_CLOCK		;17 + xxx
	
	JR SDA1				;12
	
	
;---------------------------------------------------
START_SEQUENCE:	
	DI

	;high in both i2c, before begin
	ld a,1				;7	;Could save this by calling SCL1 not SCL...
	ld c, PORT			;7
	CALL SCL 			;17 + xxx
	CALL SDA			;17 + xxx

	;high to low when clock is high
	CALL SDA0			;17 + xxx
	
	;low the clock to start sending data
	JR SCL				;12


;---------------------------------------------------
SDA0:
	xor a 				;4
	jr SDA				;12
SDA1: 
	ld a,1				;7
SDA: 
	ld b,PORT_DATA			;7
	JR SCLO				;12
;One byte less to use out later - does mean we have same delay as Clock
;	 OUT (c), a
;	 ret

PULSE_CLOCK:
	CALL SCL1			;17
	NOP
	CALL SCL1			;Lengthen high state

SCL0:
	xor a 				;4
	jr SCL				;12
SCL1:
	ld a,1				;7
SCL:
	ld b,PORT_CLOCK			;7
SCLO:	OUT (c), a			;12
	NOP				;Wait 16 t states or approx 4usec at 4Mhz so more like 5 at 3.5

	ret				;10



;---------------------------------------------------
CONVERT_HEX_DEC:

	CALL CONVERT_HEX_DEC_DIGIT
	JR C,DIGIT_ERROR

	RLCA	; A*16
	RLCA
	RLCA	
	RLCA
	
	LD B,A

	INC HL

	CALL CONVERT_HEX_DEC_DIGIT
	JR C,DIGIT_ERROR

	ADD A,B
			
	or a; clear the carry
	ret	

;---------------------------------------------------
CONVERT_HEX_DEC_DIGIT:
	LD a,(HL)
	;test ascii for 0 to 9
	CP 48
	JR C,DIGIT_ERROR 
	
	CP 58				;This is a colon - why we need a string but in this case is just first char above 9...
	JR C,ONLY_0TO9
	
	AND @11011111			;Force upper case
	
	CP 'A'
	JR C,DIGIT_ERROR
	
	CP 'G'
	JR NC,DIGIT_ERROR
	
	SUB 7				;Offset for A to be after 9
	
ONLY_0TO9:

	sub 48 				; convert asc to number
	
	OR A
	RET
	
DIGIT_ERROR:

	SCF
	RET

	
	

	

;---------------------------------------------------
NUMBER_TO_ASC:
	LD a,(HL)
	
	; get just the upper bits
	SRA A
	SRA A
	SRA A
	SRA A 
	add 48 ;convert number to ASCII
	LD b,a
	
	;now the lower bits
	LD a,(HL)
	and 0x0f ;just the lower bits
	add 48 ;convert number to ASCII
	LD c,a
	
	ret

	
	
	
;--------------------------------------------------
			

;-- Print A rows of 8 bytes at HL
print_row:		PUSH AF
			PUSH HL	
			call print_newline			
			POP HL

			LD A,8
			CALL print_bytes

			POP AF
			DEC A
			JR NZ,print_row

			RET

;-- Print A bytes at HL
print_bytes:		PUSH AF
			PUSH HL
			LD A,(HL)
			call prt_hex
			CALL space
			POP HL
			INC HL
			POP AF
			DEC A
			JR NZ,print_bytes
			
			RET			
		
;---------------------------------------------		


print:			ld a,(hl)
			inc hl
			or a
			ret z
			bit 7,a
			ret nz
			rst 16
			jr print

print_newline:		ld hl,newline
			call print
			ret

hextab:			DEFM	"0123456789ABCDEF"

space:			ld	a,' '
			jp 16

prt_hex_16:		ld	a,h
			call prt_hex
			ld a,l
			
prt_hex:		push af
			rra
			rra
			rra
			rra
			call prt_hex_4
			pop af

prt_hex_4:		push hl
			and	15
			add a,hextab&255
			ld l,a
			adc a,hextab/256
			sub l
			ld h,a
			ld a,(hl)
			pop hl
			jp 16

prt_dec:		ld bc,10000
			call dl
			ld bc,1000
			call dl
			ld bc,100
			call dl
			ld bc,10
			call dl
			ld a,l
			add a,'0'
			jp 16
			
dl:			ld a,'0'-1

lp2:			inc a
			or a
			sbc hl,bc
			jr nc,lp2
			add hl,bc
			jp 16


newline:	DEFB 13,0	
	

ErrorMessage:	DEFM " - Error.",13,13,0

ReadingMessage: DEFM "Reading 0x",0
ReadingNoBytes:	DEFM " bytes from PI",13,13,0

WritingMessage: DEFM "Writing 0x",0
WritingNoBytes:	DEFM " bytes to PI.",13,13,0

NoACKmessage:	DEFM "No ACK on address select.",13
		DEFM "Probably no PI at 0x42.",13,13,0

PiACKmessage:	DEFM "Got an ACK from device.",13
		DEFM "Probably a PI at 0x42.",13,13,0

MsgUsage: defm "PI2C V0.1 usage: ",13
	  defm "pi2c <ENTER>"
	  defb 13
	  defm "See if PI responds with an ACK"
	  defb 13,13
	  defm "pi2c {-d} -wHH{HH}<ENTER>"
	  defb 13
	  defm " - write upto 64 0xHH"
	  defb 13,13
	  defm "pi2c {-d} -rNN<ENTER>"
	  defb 13
	  defm "-rNN - read 0xNN bytes "
	  defb 13,13
	  defm "-d - no ACK test"
	  defb 13,13,0

CHKACK:	  DEFB 0

BYTCNT:	  DEFB 0
BUFFER:	  DEFS 64
CHKSUM:	  DEFB 0

