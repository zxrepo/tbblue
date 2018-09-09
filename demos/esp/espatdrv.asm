; ***************************************************************************
; * Interrupt driven Driver for ESP8266 with Factory AT command set         *
; * (c) 2018 Infinite Imaginations					    *
; ***************************************************************************
;
; File version 05
;
; This file is the 512-byte NextOS driver itself, plus relocation table.
;
; Assemble with: pasmo espatdrv.asm espatdrv.bin espatdrv.sym
;
; After this, espatdrv_drv.asm needs to be built to generate the actual
; driver file.
;
; At the moment it requires a 16K page of memory available to bank to a
; mmu5 and mmu7 pages before calling setup as part of the open
; this will eventually form part of the install process. This contains the
; Memory Resident TSR code and the command buffer.
;
; A000 is the 8K Page of assembly with the JUMP tables - this MAY move
; to MMC memory IF we implement a Spectranet compatible Sockets API
;
; This now replaces the UART driver to improve handling of received IPD packets
; so that they are placed directly on the relevent receive queues.
;
; This will also allow us to support the remote debugging service if a listener
; is setup within this code.
;
; ***************************************************************************
; * Entry points                                                            *
; ***************************************************************************
; Drivers are a fixed length of 512 bytes (although can have external 8K
; banks allocated to them if required).
;
; They are always assembled at origin $0000 and relocated at installation time
;
; The driver always runs with interrupts disabled, and may use any of the
; standard register set (AF,BC,DE,HL). Index registers and alternates must be
; preserved.
;
; No esxDOS hooks or restarts may be used. However, 3 calls are provided
; which drivers may use:
;
;       call    $2000   ; drv_drvswapmmc
;                       ; Used for switching between allocated DivMMC banks
;
;       call    $2003   ; drv_drvrtc
;                       ; Query the RTC. Returns BC=date, DE=time (as M_DATE)
;
;       call    $2006   ; drv_drvapi
;                       ; Access other drivers. Same parameters as M_DRVAPI.
;
; The stack is always located below $4000, so if ZX banks have been allocated
; they may be paged in at any location (MMU2..MMU7). However, when switching
; to other allocated DivMMC banks, the stack cannot be used unless you set
; it up/restore it yourself.
; If you do switch any banks, don't forget to restore the previous MMU setting
; afterwards.

TX_CHKREADY	EQU	4923	;133Bh Write is byte to send, when read status
					;0x01 = RX_AVAIL (1 = data to collect)
					;0x02 - TX_READY (1 = still transmit)
					;0x04 - UART FULL (1 if buffer full)
RX_SETBAUD	EQU	5179	;143Bh Read is byte received, when written set
				;the BAUD rate which is written as two bytes
				;forming a 14bit prescale value
				;First byte Bit 7=0 contains LSBits0-6,
				;2nd BIT7=1 contains MSBits 14-7

; Makes use of the following to save and load MMU registers
; Slot 7 E000-FFFF ; 8K CMD buffer
; Slot 6 C000-DFFF ; 16K IPD buffers
; Slot 5 A000-BFFF ; Used for Main CODE TSR
; Slot 4 8000-9FFF ; Unused.

;   nextreg reg,val   ED 91 reg,val   16Ts  Set a NEXT register (like doing out
;   ($243b),reg then out($253b),val )
;   nextreg reg,a     ED 92 reg       12Ts  Set a NEXT register using A (like 
;   doing out($243b),reg then out($253b),A )

; ***************************************************************************
; * Entry points                                                            *
; ***************************************************************************

CMD_WRITE_BUFFER	EQU	$E000
	
        org     $0000

; -- Table of used jump routines in 8K TSR
;

Signature	EQU $A000
IRQExtend	EQU Signature+3
StreamExtend	EQU IRQExtend+3
APIExtend	EQU StreamExtend+21
tsr_tx_char 	EQU APIExtend+18
tsr_output_size	EQU tsr_tx_char+3
tsr_cmd_get_char EQU tsr_output_size+3

; At $0000 is the entry point for API calls directed to the driver.
; B,DE,HL are available as entry parameters.

api_entry:
        jp      net_api

; At $0003 is the entry point for the interrupt handler. This will only be
; called if bit 7 of the driver id byte has been set in your .DRV file, so
; need not be implemented otherwise.

; For the network driver it empties the UART buffers into the various network
; stream buffers (each 8K/16K in size) usually located at $C000-$FFFF (mmu6/7)

;IF BYTE(S) AVAILABLE
;  STORE ERROR STATE / UART FULL FLAG SET
;  IF NOT DISABLED
;    SAVE MMU STATE
;    BANK IN 8K CODE PAGE and 8K CMD BUFFER PAGE
;    DRAIN UART FIFO BUFFER to CURRENT CMD READ BUFFER
;	WHERE char stream contains "+IPD," CALL Extended IRQ for IPD packets
;    Timeout if no more data for a short period...
;RETURN

im1_entry:	
	LD BC,TX_CHKREADY		;service routine faster when no data
	IN A,(C)
	BIT 0,A				;Check status but don't damage A
	RET Z				;Return from IRQ if no data in fifo

;SAVE UART FULL - Note this flag must stay set until acknowledged from BASIC
im_reloc_0:
	LD HL,flags
	AND %00000100			;Normal Black, Green if UART was full.
	OR (HL)
	LD (HL),A
			
;Check if we are disabled (BIT 7 of flags set) - this is done so we do not 
;write data to Page 0 without Authorisation.
;and because users can't set a page other than 0 before we are loaded yet 
;otherwise due to .install not supporting it.
;	BIT 7,A
;	RET NZ	
;Code above not needed as OR (HL) will set Sign Flag so M means set
	RET M

;	OR  %00000001			;Set the Blue bit
;	AND %00011111			;Mask out any top bits
;	out ($fe),a			;Blue duration of continuous fetch
					;Border will go cyan if we have a
					;buffer full condition due to above
	PUSH IX				;Setup IX for convenience now
im_reloc_1:
	LD IX,stream0

im_reloc_2:
	CALL PAGES_IN
		
	CALL IRQExtend

;Note the TSR will come back here to exit any way it wants
;so flags cannot be affected etc.

tsr_api_return:
	
	POP IX

PAGES_OUT:
	DEFB $ED,$91,$55,$05		;NEXTREG r,n ED 91 reg,val
;(By default pages back in Five, old one saved here)
saved_mmu5 equ $-1
	DEFB $ED,$91,$57,$01	
saved_mmu7 equ $-1

	RET


 
PAGES_IN:
;PAGE IN Correct TSR and Buffer page....
	LD BC,9275			;$243B Need to Save MMU registers
	LD A,$55
	OUT (C),A
	INC B			;LD BC,9531			;$253B
	IN A,(C)	
im_reloc_10:
	LD (saved_mmu5),A
	LD A,5
new_mmu5 equ $-1
	OUT (C),A			;New 8K bank for Code **TODO make DIVMMC
							
	DEC B				;$243B
	LD A,$57
	OUT (C),A
	INC B				;$253B
	IN A,(C)
im_reloc_11:
	LD (saved_mmu7),A			
im_reloc_12:
	LD A,(stream0_mmu7)
	OUT (C),A
	RET	

	
; ***************************************************************************
; * API for NETWORK                                                         *
; ***************************************************************************
; On entry, use B=call id with HL,DE other parameters.
; (NOTE: HL will contain the value that was either provided in HL (when called
;        from dot commands) or IX (when called from a standard program).
;
; When called from the DRIVER command, DE is the first input and HL is the 
; second.
;
; When returning values, the DRIVER command will place the contents of BC into
; the first return variable, then DE and then HL.

; Codes from 64-127 are used by built in functions to control IRQ etc for stream
; 0

net_api:
        bit     7,b                     ; check if B>=$80
api_reloc_1: 
        jp      nz,netchan_api          ; on if so, for standard channel API
        
	bit	6,b
	jr	nz,use_resident

	ld	a,b

	cp 	6			; 1-5 only external calls allowed
	jr	nc,api_error      	; 0 never occurs as that is IRQ vector

	ld 	c,a			; Max of 64 calls so no overflow *2+1
	rlca				; know bit7 = 0 so *2
	add	a,24			; Skip Sig, IRQ and Streams vectors
;Note that params are 1 onwards so above is 3 bytes earlier

	push	ix

execute_tsr:
	ld	b,0
	push	hl			; Save parameter on stack
api_reloc_2:
	ld	hl,tsr_api_return	; Where to come back to
	ex	(sp),hl
	push	hl

	ld	l,a
	ld	h,Signature >> 8	; High of jump table
	add	hl,bc			; add in the 3rd value for *3

;***DEBUG
;	pop	de			; dump the hl save
;	pop	de			; get the return address on stack
;	or	a			; diag the registers temp
;	ret

api_reloc_3:	
	CALL	PAGES_IN
	
	jp	(hl)

use_resident:
	res	6,b			; Sub 64
	inc	b

	djnz	bnot64
;-----
; B=64: get CMD buffer values including flags C=Flag status
; DE and HL are input and output positions on the UART CMD read buffer.

api_reloc_4:
        ld      a,(flags)		; C only really needed
;        and	%00001111		; Ignore all other flags just return
        ld 	c,a
;        ld	b,0			; B=0 due to DJNZ!

api_reloc_5:
        ld      de,(input_add)

api_reloc_6:
        ld      hl,(output_add)

        jr	back_to_black
;	or	a
;	ret
        
;-----
; B=65: set values of input and output buffer directly 
;
; This will also clear all flags so start TSR execution.
;
; When disabling it is possible the de and hl values may not fully reset
; as the IRQ could change them.
bnot64:
	djnz	bnot65

	ld	a,CMD_WRITE_BUFFER>>8	; Force it in range for where = 0
	or	d
	ld	d,a
api_reloc_7:
        ld      (input_add),de

	ld	a,CMD_WRITE_BUFFER>>8	; which makes it a reset
	or	h			; Carry now clear
	ld	h,a
api_reloc_8:
        ld      (output_add),hl

back_to_black:
;        xor	a	                ; clear carry to indicate success
;	or	%00011000		; Stop speaker clicking
	xor a				; Clear carry and all flags 

api_reloc_9:
	ld	(flags),a		; and reset flags.
;	out	($fe),a
	ret

;-----	
;B=66 set RX timeout - allow people to wait for variable periods for receive
;on command channel -REDUNDANT as shared with TSR now

bnot65:
	djnz	bnot66


;api_reloc_10:
;        ld      (timeout_receive),de
        

;api_reloc_11:
;        ld      (timeout_send),hl

;***TODO call main code to set these in its version of the code.

        or	a
        ret
;------
;B=67 set available memory pages to use - ignores upper values of MSB
;Now converts a 16K BASIC BANK to 8K pages 

bnot66:
	djnz	api_error
	
	ld	a,e
	or	a
	jr	z,use_main51
	
	rlca
api_reloc_12:
	ld	(new_mmu5),A
	inc	a
api_reloc_13:
	ld	(stream0_mmu7),A

;*** Todo could set BIT 7 to 0 and start running but not IPD yet

;Just assume that our TSR is already in memory so we can patch it
use_main51:
api_reloc_14:
	CALL	PAGES_IN
	
api_reloc_15:
	ld	de,get_char_border	; Address of routine
	ld 	hl,tsr_cmd_get_char+1
	ld	(hl),e
	inc	hl
	ld	(hl),d
	inc	hl
	inc	hl			;skip over 0 byte in jump table
api_reloc_15a:	
	ld	bc,stream0
	ld	(hl),c
	inc	hl
	ld	(hl),b
		
	or	a
api_reloc_16:
	JP	PAGES_OUT



;exit_invalid_io:
;	ld	a,$fe			; Invalid I/O device	
;	jr 	exit_error
;-----
; Unsupported values of B. 

api_error:
        xor     a                       ; A=0, unsupported call id or Invalid IO
exit_error:
        scf                             ; Fc=1, signals error
        ret


; ***************************************************************************
; * Validate handle for our simple channel                                  *
; ***************************************************************************

validate_handle:
	ld	a,d			; Must be in range 1-6 (1=cmd 2-7 =0-5)
        cp	128			; 0 is nothing open, 128 is local cmd
        ret	z			; Note ASM can call CMD without open...
 ;***TODO should check how many are actually open so compare to chan open flag
 	cp	6
        jr	nc,invalid_handle	; If not one of our streams then invalid
        
	pop	af			; discard return address

off_to_tsr_ix:
	push	ix			; Save IX note that open changes it here

;*** TODO need to pass IX=stream0 onto TSR for all calls not just OPEN...

off_to_tsr:
	ld	a,c			; c is left as 1 count for later
	rlca				; *2
	add	a,6			; Skip Sig and IRQ
	
;api_reloc_14:
	jr	execute_tsr		; Will not come back here

invalid_handle:
	pop     af                      ; otherwise discard return address
        jr      api_error        
        
; ***************************************************************************
; * Standard channel API                                                    *
; ***************************************************************************
; If you want your device driver to support standard channels for i/o, you
; can do so using the following API calls.
; Each call is optional - just return with carry set and A=0
; for any calls that you don't want to provide.
;
; D is usually the handle except for Open...
;
; B=$f9: open channel
; B=$fa: close channel
; B=$fb: output character		; Only one char at a time at the moment
; B=$fc: input character		; so quite slow with paging
; B=$fd: get current stream pointer
; B=$fe: set current stream pointer
; B=$ff: get stream size/extent

netchan_api:
        ld      a,b
        sub     $f9                     ; set zero flag if call $f9 (open)
        jr      c,api_error             ; exit if invalid ($80..$f8)
        ld      b,a                     ; B=0..6
        ld	c,a			; and so is C as a record
        jr      nz,bnotf9               ; on if not $f9 (open)
        

; Use the DRIVER command to pass in /get packets of data rather than single
; bytes if you wish - especially useful for UDP datagrams to a stream.
; so like sendto() and recvfrom()

; B=$f9: open channel
;
; OPEN #n,"D>X"         ; simple open: HL=DE=0
; OPEN #n,"D>X>string"  ; open with string: HL=address, DE=length
;                       ; NOTE: be sure to check for zero-length strings
; OPEN #n,"D>X,p1,p2"   ; open with numbers: DE=p1, HL=p2 (zeros if not prov.)

; For the network driver you MUST open the command channel first
; in fact any data in the string after the first open is ignored and you get
; back the command channel handle. CHANGED

; OPEN #n, "D>N"
;   opens the ESP AT command channel so that you can see the rolling
;   data and query more complex data.  Prints to this channel are
;   sent 'as is' so you can send other commands.
;   Note that the system checks this channel and deals with some commands
;   related to status
;   unlike other channels it will not block - you may receive a timout
;   return, this allows INPUT to be used to get responses but, not hang
;   and still find the end of a sequence etc. This will be char 0 or null string
;
; OPEN #n, "D>N>CTCP/UDP/SSL,address or ip,port" 
;   This is effectively getaddrinfo() (was gethostbyname) + socket() + bind()
;   and then connect()!
;   Issues an ESP  AT+CIPSTART=x,"TCP","address",port and deals with any error
;   messages to return.
;
; OPEN #n, "D>N>LXXXX" - Might be better as DRIVER x,XXXX as the stream iss
;   less use although it could be used for CLOSE with reads triggering the
;   search in the command channel for the value,CONNECT to go in the OPEN?
;   creates a server listening on port XXXX
;
; OPEN #n, "D>N>A"
;   which will do the accept() for BASIC ... when a server is started then
;   the incoming next ESP channel will be used for data receipt so the ID is
;   unknown until the first connect is received - so we need
;   to track the CIPSTATUS immediately after a connect - unless we have that
;   the above call will fail, when we do then it will succeed so it can be
;   used to poll for a new connection and assign a BASIC stream to that connect
;
; OPEN #n, "D>N>D"
;   If D is added then IPD debug data is returned. Along with x,CONNECT etc to
;   responses received back rather than suppressing them. i.e. DEBUG
;   any IPD packets are written to the buffer if received before you have
;   provided any other buffers - this is unlikely to happen unless you
;   send connects or listens yourself in which case the small buffer will be
;   hard to handle.
;
; OPEN #n, "D>N>S'address or ip',port"  - activate a remote debug/syslog service - anything
;   printed to the channel will be sent to that address and port using UDP.
;
; The ESP8266 has a limited number of network channels it can handle 0-4 which
; are set by the CIPSTART command for example.
;
; ***TODO Only 1 SSL channel is allowed so that is specifically checked.
;
; Note that closing id 5 will close all channels except if in server mode so
; we do not allow that from the streams API at the moment.
;
; You must have added at least a single 16K memory bank via the API to allow
; an open to succeed. If you do not then all IPD data will just be in the
; command stream and the buffer will exhaust quickly. 

; Channel handle is returned in A

; If you return with any error (carry set), "Invalid filename" will be reported
; and no stream will be opened.

	push	ix
	
chn_reloc_1:	
	ld	ix,stream0

;        ld      a,(IX-6)		; Can't use HL as it is our string addr
;        cp	7
;        jr      nc,api_error		; exit with error if 6 already open
	ld	a,l			; Zero string is Control channel
	or	h
	jr	nz,off_to_tsr

	bit	7,(ix-6)		; Command channel already open
	jr	nz,api_error

;	inc	a
;        ld      (IX-6),a	       ; signal "channel open"
        set      7,(IX-6)	       ; signal "channel open"
	ld	a,128			; Give out command handle
;	cp	1
;	jr	nz,off_to_tsr		; Not first channel so do complex stuff

;***TODO lack of space but we should check there is no string after us


	pop	ix

;	or	a			; Clear carry (not needed as Z = NC)
        ret                             ; exit with carry reset (from OR above)
                                        ; and A=handle=1


; B=$fa: close channel
; This call is entered with D=handle, and should close the channel
; If it cannot be closed for some reason, exit with an error (this will be
; reported as "In use").
; This will happen if you try to close CMD channel with others open...

bnotf9:
        djnz    bnotfa                  ; on if not call $fa

chn_reloc_2:				; Re use HL to point at our channel
        ld      hl,chanopen_flag

chn_reloc_3:
        call    validate_handle         ; check D is our handle (does not return
                                        ; if invalid or higher IPD channel)
	res	7,(hl)
;	ld	a,(hl)
;       cp	1			; Make sure only 1 open
;       jr	nz,api_error
        
        xor     a
;chn_reloc_4:
;        ld      (chanopen_flag),a       ; signal "final channel closed"
; 	ld	(hl),a
        ret                             ; exit with carry reset (from XOR)


; B=$fb: output character
; This call is entered with D=handle and E=character.
; If you return with carry set and A=$fe, the error "End of file" will be
; reported. If you return with carry set and A<$fe, the error
; "Invalid I/O device" will be reported.
; Do not return with A=$ff and carry set; this will be treated as a successful
; call.
;
; ***TODO we can add a small output buffer to prevent any blocking then
; use the End of file error return if it is filled before transmission.
; This will have to be added to the IRQ routine for transmission 

; This is cooked a CR will add an LF

bnotfa:
        djnz    bnotfb                  ; on if not call $fb
chn_reloc_4:
        call    validate_handle         ; check D is our handle (does not return
                                        ; if invalid - or a handle to TSR)       
;chn_reloc_6:
	ld	a,e
 	push	de
        call	tsr_tx_char		; Send character in A using tsr
        pop	de
  	jr	c,Invalid_IO
	ld	a,e
 	cp	13
 	jr	z,addLF
 	or	a			; Make sure Carry clear
 	ret
addLF:
	ld	a,10
        call	tsr_tx_char
 
Invalid_IO:
       	ld	a,1			; Trigger an Invalid I/O dev on timeouts
        ret                             ; exit with carry as was


; B=$fc: input character
; This call is entered with D=handle.
; You should return the character in A (with carry reset).
; If no character is currently available, return with A=$ff and carry set.
; This will cause INPUT # or NEXT # to continue calling until a character
; is available.
; If you return with carry set and A=$fe, the error "End of file" will be
; reported. If you return with carry set and any other value of A, the error
; "Invalid I/O device" will be reported.

bnotfb:
        djnz    bnotfc                  ; on if not call $fc
chn_reloc_5:
        call    validate_handle         ; check D is our handle (does not return
                                        ; if invalid or not channel 0)
	push	ix

chn_reloc_6:
	call	PAGES_IN	

chn_reloc_7:
	call	get_char

chn_reloc_8:
	jp	tsr_api_return		; POPs IX, PAGES_OUT no effect on Carry


	

;	or	a
;       ret                             ; exit with carry reset (from OR)


; B=$fd: get current stream pointer
; This call is entered with D=handle.
; You should return the pointer in DEHL (with carry reset).
; This can be used with RETURN #n TO var I assume... 
; This will always return 0/Carry set as we are always at the start for CMD
; We will use this to allow BASIC to get the internal handle to pass
; to the driver command for a specific stream.  The handle is an index to
; our internal streams 0-5 from where the ESP channel no can be obtained.

bnotfc:
        djnz    bnotfd                  ; on if not call $fd
chn_reloc_13:
        call    validate_handle		; check D is our handle (does not return
                                        ; if invalid)
        xor	a
	scf
        ret
;Could be a JMP if we set carry?

; B=$fe: set current stream pointer
; This call is entered with D=handle and IXHL=pointer.
; Exit with A=$fe and carry set if the pointer is invalid (will result in
; an "end of file" error).
; NOTE: Normally you should not use IX as an input parameter, as it cannot
;       be set differently to HL if calling via the esxDOS-compatible API.
;       This call is a special case that is only made by NextOS.
; This can be used with "GOTO #n,m" I assume.
; This can be used to ADD x bytes to the stream to bulk skip over incoming
; data - it cannot be used to rewind the stream, error if x is > extent

bnotfd:
        djnz    bnotfe                  ; on if not call $fe


chn_reloc_14:
        call    validate_handle         ; check D is our handle (does not return
                                        ; if invalid or > stream 0)
	xor	a
        or      ixl			; Discard any obviously too big
        or      ixh
        scf				; cause RET C to trigger
        jr	nz,exit_fe
;        ld	c,l
;        ld	b,h
 	push	hl       
;        push	bc
chn_reloc_15:
	call	output_size		; Get the current absolute size
	pop	bc	
        or	a                       ; check if pointer > extent
	sbc	hl,bc			; Carry will be set if so

exit_fe:
	ld      a,$fe
        ret     c                       ; exit with A=$fe and carry set if so

chn_reloc_16:
        ld      hl,(output_add)		; OK so lets adjust the pointer
	add	hl,bc
	jr	nc,all_done

	ld	bc,CMD_WRITE_BUFFER	; If we wrapped around
	add	hl,bc			; then set base address again

all_done:
chn_reloc_17:
        ld      (output_add),hl         ; set the pointer
	res	4,(ix+0)		; At least space for one now!
        and     a                       ; reset carry (successful call)
        ret


;------
; B=$ff: get stream size/extent
; This call is entered with D=handle
; You should return the size/extent in DEHL (with carry reset).
; This can be used with "DIM #n TO var" I assume.

bnotfe:
chn_reloc_18:
        call    validate_handle         ; check D is our handle (does not return
                                        ; if invalid or if channel >0
                                        
output_size:		; Used as a subroutine to get abs buffer size in HL

	push	ix
	ld	bc,8192			; Size of CMD buffer
chn_reloc_19:	
	ld	ix,stream0
	call	tsr_output_size
	pop	ix 
	
;	or	a			; make sure carry clear - is in above

	ret


;Used by this code and the TSR through a JMP table

get_char_border:
;	LD A,%00011111		;White border while getting...	
;	OUT ($FE),A

get_char:	
sub_reloc_0:	
	ld	ix,stream0
sub_reloc_1:
        ld      hl,(output_add)
sub_reloc_2:
        ld	de,(input_add)
        
	ld	a,h
	cp	d
	jr	nz,notsame
	ld	a,l
	cp	e
	jr	nz,notsame

	bit	4,(ix+0)		;Is buffer full
	jr	nz,notsame

	ld	a,$ff			;End of file if nothing in it!
	scf
	ret

notsame:
	res	4,(ix+0)		;At least space for one now!
	
	ld	e,(hl)
	inc	hl
	ld	a,h
	or	l
	jr	nz,no_wrap_out

	ld	h,CMD_WRITE_BUFFER>>8	; Reset to start of buffer

no_wrap_out:

sub_reloc_3:
        ld      (output_add),hl         ; update pointer

        ld      a,e                     ; A=character
        cp 	10			; LF becomes extra/only CR for input
        jr	nz,no_cooking
        ld	a,13	

no_cooking:
	or	a			; Clear carry
	ret	


;***TODO move all this into TSR keeping above as it needs to be available will
;save space and cures the bug in this I can't find. 
	
;chn_reloc_19:
;        ld      hl,(output_add)
;chn_reloc_20:
;        ld	de,(input_add)       
;        or	a			; Clear carry
;        sbc	hl,de
;    	xor	a			; Clear Carry and flags
;    	ld	e,a			; Never extend >65535 anyway.
;    	ld	d,a
;    	bit	7,h			; Trick for ABS HL from http://z80-heaven.wikidot.com/math
;    	ret	z			; Carry clear
;	sub	l			; A was zero from xor above;
;	ld	l,a
;	sbc	a,a
;	sub	h
;	ld	h,a	
;       and     a                       ; reset carry (successful call)
;       ret




;Todo - need to add Block transmit for speed to bypass Streams character
;at a time (use 512bytes in Page buffer?)

;-------------------------------
;Send character in E to UART
;Returns with C set if timeout

;tx_char:
;			LD HL,1024		;Delay timeout
;was 20 at 112500 baud - need to be higher at lower baud rates... ***TODO
;timeout_send equ $-2

;			LD A,%00011111		;White border while sending	
;			OUT ($FE),A
									
;			LD BC,TX_CHKREADY
;char_out_wait:		IN A,(C)

;			BIT 1,A
;			JR Z,char_out_ready

;			LD A,%00011010		;Red border while waiting to send 	
;			OUT ($FE),A
							
;			DEC HL
;			LD A,H
;			OR L
;			JR NZ,char_out_wait

;sub_reloc_1:
;			LD A,(flags)
;			OUT ($FE),A		;Restore Border colour to flag
			
;			SCF			;Return an error.
;			RET
			
;char_out_ready:
;			LD A,E
;			OUT (C),A
			
;sub_reloc_2:
;			LD A,(flags)
;			OUT ($FE),A		;Restore Border colour to flag	
			
;			XOR A			;Zero flag set and Carry reset
;			RET



; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

; This flag tracks the channels - Bit 7 set if Command channel open returns
; a handle of >128
;
; Otherwise it is 1-5 (do not confuse with the ESP number as these can come and
; go as a BASIC stream could be associated with a dead ESP stream if it closes
; which we should flag if we see the close - if not we can flag next time we
; try to use it.  It is still up to the user to close that BASIC stream though
; to our channel.

chanopen_flag:
        defb    0			;(IX-6) if needed


; Note that buffer full error state applies to main ESP command buffer
; IPD handling filling their respective buffers handle that in the flags
; for that stream

ipdstring:
	defm	",DPI+"			;(IX-1) etc must be IPD header

stream0:
flags:					
	defb	%11000000		;Also as IX-0 when in IRQ!
;Bit 0 = Colour modifier (RX_AVAIL) 
;Bit 1 = 8K SW command buffer overwrite error state (temp) (TX_READY)
;Bit 2 = UART 512Byte HW FULL error state (temp)
;Bit 3 = was Always 1 to stop speaker clicks on OUT
;Bit 4 = Buffer full flag now - was Always 1 to stop speaker clicks on OUT
;Bit 5 = IPD packet seen.
;Bit 6 = IPD packet mode receive disable when 1
;Bit 7 = we are disabled when 1
;Note that BIT 7 is buffer full flag normally but, we use flags for border diags
;so different layout in the stream.

stream0_mmu7:
	defb	1			;This forms an 8K buffer at top of main
	defb 	255,255,255		;memory.
	
output_add:
	defw	CMD_WRITE_BUFFER	;Nothing in buffer as yet
    
input_add:
	defw	CMD_WRITE_BUFFER

;ipd_len:
;	defw	0


zzz_end:
	
; ***************************************************************************
; * Relocation table                                                        *
; ***************************************************************************
; This follows directly after the full 512 bytes of the driver.

if ($ > 512)
.ERROR Driver code exceeds 512 bytes 
else
        defs    512-$
endif

; Each relocation is the offset of the high byte of an address to be relocated.

reloc_start:
	defw	api_entry+2	;Now needs a jump!

        defw	im_reloc_0+2
        defw	im_reloc_1+3	;IX load
        defw	im_reloc_2+2
;        defw	im_reloc_3+2
;        defw	im_reloc_4+2
;        defw	im_reloc_5+2
;        defw	im_reloc_6+3	;DE load
;        defw	im_reloc_7+2
;        defw	im_reloc_8+2
;        defw	im_reloc_9+2
        defw	im_reloc_10+2
        defw	im_reloc_11+2
        defw	im_reloc_12+2 
                       
        defw    api_reloc_1+2
        defw    api_reloc_2+2
        defw    api_reloc_3+2
        defw    api_reloc_4+2
        defw    api_reloc_5+3	;DE load
        defw    api_reloc_6+2     
        defw    api_reloc_7+3	;DE load
        defw    api_reloc_8+2
        defw    api_reloc_9+2
;        defw    api_reloc_10+3	;DE load
;        defw    api_reloc_11+2
        defw    api_reloc_12+2
        defw    api_reloc_13+2
        defw    api_reloc_14+2
        defw    api_reloc_15+2	;DE immediate load so normal!!
        defw    api_reloc_15a+2
        defw    api_reloc_16+2
                
        defw    chn_reloc_1+3	;IX load
        defw    chn_reloc_2+2
        defw    chn_reloc_3+2
        defw    chn_reloc_4+2
        defw    chn_reloc_5+2
        defw    chn_reloc_6+2
        defw    chn_reloc_7+2
        defw    chn_reloc_8+2
;        defw    chn_reloc_9+2
;        defw    chn_reloc_10+3	;DE
;        defw    chn_reloc_11+2
;        defw    chn_reloc_12+2
        defw    chn_reloc_13+2
        defw    chn_reloc_14+2
        defw    chn_reloc_15+2
        defw    chn_reloc_16+2
        defw    chn_reloc_17+2
        defw    chn_reloc_18+2
        defw    chn_reloc_19+3	;IX load

        defw	sub_reloc_0+3	;IX
        defw	sub_reloc_1+2
        defw	sub_reloc_2+3	;DE
        defw	sub_reloc_3+2


reloc_end:




