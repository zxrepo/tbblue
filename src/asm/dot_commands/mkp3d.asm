; ***************************************************************************
; * Dot commands for creating data or swap partitions                       *
; * .mkdata filename [size]                                                 *
; * .mkswap filename [size]                                                 *
; ***************************************************************************

Z80N    equ     1
include "macros.def"

macro call48k,address
        rst     $18
        defw    address
endm

macro callesx,hook
        rst     $8
        defb    hook
endm

macro print_char
        rst     $10
endm


; ***************************************************************************
; * esxDOS API and other definitions required                               *
; ***************************************************************************

; Calls
disk_filemap            equ     $85             ; obtain file allocation map
m_dosversion            equ     $88             ; get version information
m_setcaps               equ     $91             ; set capabilities
f_open                  equ     $9a             ; opens a file
f_close                 equ     $9b             ; closes a file
f_read                  equ     $9d             ; read file
f_write                 equ     $9e             ; write file
f_seek                  equ     $9f             ; seek to position in file
f_fstat                 equ     $a1             ; get file stats
f_ftruncate             equ     $a2             ; resize file
f_unlink                equ     $ad             ; delete file
f_rename                equ     $b0             ; rename file

; ROM 3 routines
BC_SPACES_r3            equ     $0030           ; allocate workspace
OUT_CODE_r3             equ     $15ef           ; digit output
OUT_SP_NO_r3            equ     $192a           ; numeric place output

; File access modes
esx_mode_read           equ     $01             ; read access
esx_mode_open_exist     equ     $00             ; open existing files only
esx_mode_write          equ     $02             ; read access
esx_mode_creat_trunc    equ     $0c             ; create new file, delete existing

esx_seek_set            equ     $00             ; set fileposition

; Errors
esx_eio                 equ     6

; ZX Next registers
next_reg_select         equ     $243b
nxr_turbo               equ     $07
turbo_max               equ     2

; Definitions
filemap_size            equ     2               ; must be at least 2 to detect
                                                ; if file is fragmented or not

if MKDATA
MAX_SIZE_MB             equ     16
else
MAX_SIZE_MB             equ     30
endif


; ***************************************************************************
; * Argument parsing                                                        *
; ***************************************************************************
; Dot commands always start at $2000, with HL=address of command tail
; (terminated by $00, $0d or ':').

        org     $2000

        ld      a,h
        or      l
        jr      z,show_usage            ; no tail provided if HL=0
        ld      de,filename
        call    get_sizedarg            ; get first argument to filename
        jr      nc,show_usage           ; if none, just go to show usage
        ld      de,sizeparam
        call    get_sizedarg            ; see if there is a size argument
        jr      nc,use_default_size     ; if not, just use the default
        ld      de,0                    ; further args to ROM
        call    get_sizedarg            ; check if any further args
        jr      nc,parse_size           ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        ret

parse_size:
        ld      hl,0                    ; initialise size to 0
        ld      de,sizeparam            ; start of argument
parse_size_loop:
        ld      a,(de)                  ; get next character from parameter
        inc     de
        and     a
        jr      z,got_size              ; on when reached the end
        sub     '0'                     ; put next digit in range 0..9
        jr      c,show_usage            ; if not a digit, show the help
        cp      10
        jr      nc,show_usage
        add     hl,hl                   ; HL=curvalue*2
        ld      b,h
        ld      c,l                     ; BC=curvalue*2
        add     hl,hl
        add     hl,hl                   ; HL=curvalue*8
        add     hl,bc                   ; HL=curvalue*10
        ld      b,0
        ld      c,a
        add     hl,bc                   ; add in new digit
        ld      a,h
        and     a
        jr      nz,show_usage           ; error if >=256
        jr      parse_size_loop

use_default_size:
        ld      hl,MAX_SIZE_MB          ; default size is the maximum
got_size:
        ld      a,l                     ; ensure valid size 1-MAX_SIZE_MB
        and     a
        jr      z,show_usage
        cp      MAX_SIZE_MB+1
        jr      nc,show_usage
        ld      (drivesize),a           ; save size for later
        ; fall through to mkp3d_init

; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

mkp3d_init:
        di                              ; disable interrupts for the duration
        ld      bc,4096
        call48k BC_SPACES_r3            ; ensure enough space for 4K buffer
        ld      (bufferaddr),de         ; and save its address
        ld      bc,next_reg_select
        ld      a,nxr_turbo
        out     (c),a
        inc     b
        in      a,(c)                   ; get current turbo setting
        ld      (saved_speed),a         ; save it
        ld      a,turbo_max
        out     (c),a                   ; and increase to maximum
        ld      a,$80                   ; set do not erase with truncate
        callesx m_setcaps
        ld      a,e
        ld      (old_caps),a            ; save old capabilities for restoring
        callesx m_dosversion
        jr      c,bad_nextzxos          ; must be esxDOS if error
        ld      hl,'N'<<8+'X'
        sbc     hl,bc                   ; check NextZXOS signature
        jr      nz,bad_nextzxos
        ld      hl,$0198
        ex      de,hl
        sbc     hl,de                   ; check version number >= 1.98
        jr      nc,good_nextzxos
bad_nextzxos:
        ld      hl,msg_badnextzxos
        ; fall through to err_custom

; ***************************************************************************
; * Custom error generation                                                 *
; ***************************************************************************

err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        ; fall through to exit_error

; ***************************************************************************
; * Close file and exit with any error condition                            *
; ***************************************************************************

exit_error:
        push    af                      ; save error status
        push    hl
        ld      a,(old_caps)
        callesx m_setcaps               ; restore original caps
        ld      a,(saved_speed)
        nxtrega nxr_turbo               ; restore original speed
        pop     hl                      ; restore error status
        pop     af
        ei                              ; re-enable interrupts
        ret


; ***************************************************************************
; * Create an unfragmented file                                             *
; ***************************************************************************

good_nextzxos:
        ld      hl,(drivesize)
        ld      h,0                     ; HL=size required in MB
        add     hl,hl
        add     hl,hl
        add     hl,hl
        add     hl,hl                   ; HL00=size required in bytes
        ld      (file_size+2),hl
        ld      hl,512                  ; add 512 bytes for P3D header
        ld      (file_size),hl
        ld      hl,msg_findingspace
        call    printmsg                ; "Finding space..."
unfrag_search_loop:
        ld      a,'.'
        print_char
        ld      hl,(temp_num)
        inc     hl                      ; HL=next temporary file number
        ld      (temp_num),hl
        call    settempfilename         ; set up the temporary file name
        ld      hl,msg_tmpfilename
        ld      b,esx_mode_write+esx_mode_read+esx_mode_creat_trunc
        ld      a,'*'
        callesx f_open                  ; create new temporary file
        jp      c,mkp3d_failed_creatent ; if failed, delete temps & exit
        ld      (tmpfilehandle),a
        ld      de,(file_size)
        ld      bc,(file_size+2)
        callesx f_ftruncate             ; expand to required size
        jp      c,mkp3d_failed_expand   ; if failed, delete temps & exit
        ld      a,(tmpfilehandle)
        call    check_fragmentation     ; is it fragmented?
        jp      c,mkp3d_failed_fragm    ; if failed, delete temps & exit
        jr      z,mkp3d_found
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the temporary file
        jr      unfrag_search_loop      ; back for more


; ***************************************************************************
; * Generate the P3D header                                                 *
; ***************************************************************************

mkp3d_found:
        ld      hl,msg_okay
        call    printmsg
        ld      hl,msg_formatting
        call    printmsg                ; "Formatting image..."
if MKDATA
        ; Block size is chosen to ensure: 256 <= #blocks <= 2048
        ; If <256, extent masks would differ
        ; If >2048, allocation bitmaps would need to be >256 bytes
        ld      a,(drivesize)
        ld      d,a
        ld      e,0                     ; DE=size*256 (# of 4K blocks)
        cp      5
        jr      c,blk2k                 ; move on for 2K blocks (1-4MB)
        cp      9
        jr      c,blk4k                 ; move on for 4K blocks (5-8MB)
blk8k:
        srl     d                       ; DE=size*128 (# of 8K blocks)
        rr      e
        ld      hl,$3f06                ; HL=block mask & shift for 8K blocks
        ld      b,3                     ; B=extent mask for 8K blocks
        ld      a,%11000000             ; A=AL0 for 8K blocks
        jr      setxdpb
blk4k:
        ld      hl,$1f05                ; HL=block mask & shift for 4K blocks
        ld      b,1                     ; B=extent mask for 4K blocks
        ld      a,%11110000             ; A=AL0 for 4K blocks
        jr      setxdpb
blk2k:
        sla     d                       ; DE=size*512 (# of 2K blocks)
        ld      hl,$0f04                ; HL=block mask & shift for 2K blocks
        ld      b,0                     ; B=extent mask for 2K blocks
        ld      a,%11111111             ; A=AL0 for 2K blocks
setxdpb:
        ld      (default_xdpb+2),hl     ; set block mask & shift
        ld      (default_xdpb+9),a      ; set AL0
        ld      a,b
        ld      (default_xdpb+4),a      ; set extent mask
        dec     de                      ; DE=maximum block number
        ld      (default_xdpb+5),de     ; set last block number
        ld      a,(drivesize)
        add     a,a                     ; calculate A=16*size in MB
        add     a,a                     ; ie A=16*(size in sectors/2048)
        add     a,a                     ; so A=#tracks, since:
        add     a,a                     ; tracksize=128 sectors
        ld      (default_xdpb+18),a     ; set tracks
endif ; MKDATA
        ld      hl,(drivesize)
        ld      h,0
        add     hl,hl
        add     hl,hl
        add     hl,hl                   ; HL=8*size in MB so HL0=#sectors
        dec     hl                      ; HL$ff=max logical sector number
        ld      a,$ff
        ld      (default_phandle+7),a
        ld      (default_phandle+8),hl
        ld      de,(bufferaddr)         ; address to place header
        push    de
        ld      hl,default_p3dhdr
        ld      bc,48
        ldir                            ; copy signature, XDPB & phandle
        pop     hl
        inc     hl
        inc     hl
        inc     hl
        inc     hl                      ; HL=address after signature
        ld      b,44
        xor     a                       ; initialise checksum
calc_checksum:
        add     a,(hl)                  ; add in next byte
        inc     hl
        djnz    calc_checksum
        ld      d,h
        ld      e,l
        inc     de
        ld      bc,462
        ld      (hl),0                  ; erase byte 48
        ldir                            ; erase bytes 49..510
        ld      (de),a                  ; store checksum in byte 511
        ; drop through to write_p3d

; ***************************************************************************
; * Write the P3D file                                                      *
; ***************************************************************************

write_p3d:
        ld      a,(tmpfilehandle)
        ld      bc,0
        ld      de,0
        ld      l,esx_seek_set
        callesx f_seek                  ; seek to start of dest file
        ld      a,(tmpfilehandle)
        ld      hl,(bufferaddr)
        ld      bc,512
        push    bc
        callesx f_write                 ; write the P3D header
        pop     hl
        jr      c,mkp3d_failed_write
        and     a
        sbc     hl,bc                   ; were all bytes written?
        scf
        ld      a,esx_eio
        jr      nz,mkp3d_failed_wrsize  ; error if not
if MKDATA
        ld      hl,(bufferaddr)
        ld      d,h
        ld      e,l
        inc     de
        ld      (hl),$e5
        ld      bc,4095
        ldir                            ; fill 4K buffer with $e5
        ld      b,4                     ; 4x4K=16K=512 directory entries
write_dir_loop:
        push    bc
        ld      a,(tmpfilehandle)
        ld      hl,(bufferaddr)
        ld      bc,4096
        push    bc
        callesx f_write                 ; write the P3D header
        pop     hl                      ; HL=4096
        pop     de                      ; D=loop counter
        jr      c,mkp3d_failed_write
        and     a
        sbc     hl,bc                   ; were all bytes written?
        scf
        ld      a,esx_eio
        jr      nz,mkp3d_failed_wrsize  ; error if not
        ld      b,d                     ; B=loop counter
        djnz    write_dir_loop          ; back for more iterations
endif ; MKDATA
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the new file
        jr      c,mkp3d_failed_newclose
        ld      a,'*'
        ld      hl,msg_tmpfilename
        ld      de,filename
        callesx f_rename                ; rename temp to original
        jr      c,mkp3d_failed_rename
        ld      hl,msg_okay
        call    printmsg
        call    delete_tmps             ; delete remaining temporary files
        and     a
        jp      exit_error              ; for now just close the file & exit


; ***************************************************************************
; * Image creation failed                                                   *
; ***************************************************************************

mkp3d_failed_creatent:
        ld      hl,msg_failed_create
        jr      mkp3d_failed_notmp
mkp3d_failed_expand:
        ld      de,msg_failed_expand
        jr      mkp3d_failed_all
mkp3d_failed_fragm:
        ld      de,msg_failed_fragm
        jr      mkp3d_failed_all
mkp3d_failed_write:
        ld      de,msg_failed_write
        jr      mkp3d_failed_all
mkp3d_failed_wrsize:
        ld      de,msg_failed_writesize
        jr      mkp3d_failed_all
mkp3d_failed_newclose:
        ld      de,msg_failed_newclose
        jr      mkp3d_failed_all
mkp3d_failed_rename:
        ld      de,msg_failed_rename
        jr      mkp3d_failed_all

mkp3d_failed_all:
        push    de
        push    af
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the temporary file
        pop     af
        pop     hl
mkp3d_failed_notmp:
        push    af                      ; save error status
        call    printmsg
        ld      hl,msg_origfile
        call    printmsg
        ld      hl,filename
        call    printmsg
        ld      hl,msg_newfile
        call    printmsg
        ld      hl,msg_tmpfilename
        call    printmsg
        ld      hl,msg_endfilenames
        call    printmsg
        call    delete_tmps             ; delete all temporary files
        pop     af
        jp      exit_error


; ***************************************************************************
; * Delete temporary files                                                  *
; ***************************************************************************

delete_tmps:
        ld      hl,msg_deletingtemps
        call    printmsg                ; "Deleting temporary files"
delete_tmps_loop:
        ld      a,'.'
        print_char
        ld      hl,(temp_num)           ; get next temp file to delete
        ld      a,h
        or      l
        jr      z,delete_tmps_done      ; exit once none left
        call    settempfilename         ; set up the file name
        ld      a,'*'
        ld      hl,msg_tmpfilename
        callesx f_unlink                ; delete the file
        ld      hl,(temp_num)
        dec     hl
        ld      (temp_num),hl
        jr      delete_tmps_loop
delete_tmps_done:
        ld      hl,msg_okay
        jp      printmsg                ; print OK and exit


; ***************************************************************************
; * Generate temporary filename                                             *
; ***************************************************************************
; Entry: HL=temp file number (preserved)

settempfilename:
        ld      de,msg_tmpfilename_num
        ld      a,h
        call    sethighnibble
        ld      a,h
        call    setlownibble
        ld      a,l
        call    sethighnibble
        ld      a,l
        jr      setlownibble
sethighnibble:
        rrca
        rrca
        rrca
        rrca
setlownibble:
        and     $0f
        add     a,'0'
        cp      '9'+1
        jr      c,gothexnibble
        add     a,'a'-('9'+1)
gothexnibble:
        ld      (de),a
        inc     de
        ret


; ***************************************************************************
; * Check if file is fragmented                                             *
; ***************************************************************************
; Entry: A=handle
; Exit(failure):  Fc=1, A=error
; Exit(success):  Fc=0, Fz=1 if unfragmented

check_fragmentation:
        push    af
        ld      bc,0
        ld      de,0
        ld      l,esx_seek_set
        callesx f_seek                  ; seek to start of file
        pop     af
        push    af
        ld      hl,filemap_buffer
        ld      bc,1
        callesx f_read                  ; read 1 byte to ensure starting cluster
        pop     af
        ld      hl,filemap_buffer
        ld      de,filemap_size
        callesx disk_filemap
        ret     c
        ld      de,filemap_buffer+6
        sbc     hl,de                   ; Fz=1 if unfragmented
        ret     nc                      ; exit if 1+ entries in buffer
        xor     a                       ; if 0 entries in buffer, Fc=0 & Fz=1
        ret


; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        and     a
        ret     z                       ; exit if terminator
        print_char
        jr      printmsg


; ***************************************************************************
; * Parse an argument from the command tail                                 *
; ***************************************************************************
; Entry: HL=command tail
;        DE=destination for argument
; Exit:  Fc=0 if no argument
;        Fc=1: parsed argument has been copied to DE and null-terminated
;        HL=command tail after this argument
;        BC=length of argument
; NOTE: BC is validated to be 1..255; if not, it does not return but instead
;       exits via show_usage.

get_sizedarg:
        ld      bc,0                    ; initialise size to zero
get_sizedarg_loop:
        ld      a,(hl)
        inc     hl
        and     a
        ret     z                       ; exit with Fc=0 if $00
        cp      $0d
        ret     z                       ; or if CR
        cp      ':'
        ret     z                       ; or if ':'
        cp      ' '
        jr      z,get_sizedarg_loop     ; skip any spaces
        cp      '"'
        jr      z,get_sizedarg_quoted   ; on for a quoted arg
get_sizedarg_unquoted:
        ld      (de),a                  ; store next char into dest
        inc     de
        inc     c                       ; increment length
        jr      z,get_sizedarg_badsize  ; don't allow >255
        ld      a,(hl)
        and     a
        jr      z,get_sizedarg_complete ; finished if found $00
        cp      $0d
        jr      z,get_sizedarg_complete ; or CR
        cp      ':'
        jr      z,get_sizedarg_complete ; or ':'
        cp      '"'
        jr      z,get_sizedarg_complete ; or '"' indicating start of next arg
        inc     hl
        cp      ' '
        jr      nz,get_sizedarg_unquoted; continue until space
get_sizedarg_complete:
        xor     a
        ld      (de),a                  ; terminate argument with NULL
        ld      a,b
        or      c
        jr      z,get_sizedarg_badsize  ; don't allow zero-length args
        scf                             ; Fc=1, argument found
        ret
get_sizedarg_quoted:
        ld      a,(hl)
        and     a
        jr      z,get_sizedarg_complete ; finished if found $00
        cp      $0d
        jr      z,get_sizedarg_complete ; or CR
        inc     hl
        cp      '"'
        jr      z,get_sizedarg_complete ; finished when next quote consumed
        ld      (de),a                  ; store next char into dest
        inc     de
        inc     c                       ; increment length
        jr      z,get_sizedarg_badsize  ; don't allow >255
        jr      get_sizedarg_quoted
get_sizedarg_badsize:
        pop     af                      ; discard return address
        jp      show_usage


; ***************************************************************************
; * Default P3D header                                                      *
; ***************************************************************************

default_p3dhdr:
default_p3dsig:
        ; signature (4 bytes)
        defm    "P3D",$1a
if MKDATA
default_xdpb:
        ; XDPB (28 bytes)
        defw    512             ; SPT: records per track
        defb    0               ; BSH: log2(blocksize/128)      TO FILL IN
        defb    0               ; BLM: blocksize/128-1          TO FILL IN
        defb    0               ; EXM: extent mask              TO FILL IN
        defw    0               ; DSM: last block number        TO FILL IN
        defw    511             ; DRM: last directory entry
        defb    0               ; AL0: directory bitmap         TO FILL IN
        defb    0               ; AL1: directory bitmap
        defw    $8000           ; CKS: checksum - fixed disk
        defw    0               ; OFF: reserved tracks
        defb    2               ; PSH: log2(sectorsize/128)
        defb    3               ; PSM: sectorsize/128-1
        defb    0               ; sidedness
        defb    0               ; tracks per side               TO FILL IN
                                ; NOTE: Gets set to $00 for 16MB partitions.
                                ;       Okay, as unused on non-floppy drives
                                ;       if sidedness=0.
        defb    128             ; sectors per track
        defb    0               ; 1st sector
        defw    512             ; sector size
        defw    0               ; partition handle
        defb    0               ; multitrack
        defb    0               ; freeze flag
        defb    $10             ; flags: bit 4=mounted image
else ; MKDATA
        defs    28              ; no XDPB for swap partitions
endif ; MKDATA
default_phandle:
        ; partition handle (16 bytes)
if MKDATA
        defb    $03             ; partition type (ptype_p3dos)
else
        defb    $02             ; partition type (ptype_swap)
endif
        defw    0,0             ; starting LBA
        defw    0               ; unused
        defw    0,0             ; largest logical sector        TO FILL IN
        defs    5               ; type-specific data


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

msg_help:
if MKDATA
        defm    "MKDATA v1.2 by Garry Lancaster",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .MKDATA FILENAME [SIZE]",$0d,$0d
        defm    "INFO:",$0d
        defm    "Creates a mountable +3DOS drive",$0d
        defm    "image, usable by NextZXOS & CP/M",$0d
        defm    "Optional size in MB is 1..16",$0d
        defm    "(default=16)",$0d,$0d
        defm    "For automounting at startup or",$0d
        defm    "when CP/M starts, name files as:",$0d
        defm    "    C:/NEXTZXOS/DRV-d.P3D",$0d
        defm    "    C:/NEXTZXOS/CPM-d.P3D",$0d
        defm    "where 'd' is drive letter A-P",$0d,$0d
        defm    "NextZXOS uses DRV-d files first,",$0d
        defm    "then CPM-d files. CP/M uses",$0d
        defm    "CPM-d files first, then DRV-d",$0d
        defm    "files",$0d,0
else
        defm    "MKSWAP v1.2 by Garry Lancaster",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .MKSWAP FILENAME [SIZE]",$0d,$0d
        defm    "INFO:",$0d
        defm    "Creates a swap file usable by",$0d
        defm    "NextZXOS machine-code programs",$0d,$0d
        defm    "Optional size in MB is 1..30",$0d
        defm    "(default=30)",$0d,$0d
        defm    "Swap files should be named:",$0d
        defm    "    C:/NEXTZXOS/SWP-n.P3S",$0d
        defm    "where 'n' is number 0-9",$0d,0
endif

msg_findingspace:
        defm    "Finding space..",0

msg_deletingtemps:
        defm    "Erasing temps.",0

msg_formatting:
        defm    "Formatting image...",0

msg_failed_create:
        defm    $0d," - FAILED creating tmp file",$0d,0

msg_failed_expand:
        defm    $0d," - FAILED reserving space",$0d,0

msg_failed_fragm:
        defm    $0d," - FAILED checking fragmentation",$0d,0

msg_failed_write:
        defm    $0d," - FAILED writing file",$0d,0

msg_failed_writesize:
        defm    $0d," - FAILED file write size",$0d,0

msg_failed_newclose:
        defm    $0d," - FAILED closing new file",$0d,0

msg_failed_rename:
        defm    $0d," - FAILED renaming new file",$0d,0

msg_origfile:
        defm    "Final file: '",0

msg_newfile:
        defm    "'",$0d,"Temp file: '",0

msg_endfilenames:
        defm    "'",$0d,0

msg_okay:
        defm    "OK    ",$0d,0

msg_tmpfilename:
        defm    "$$$mkp3d_tmp"
msg_tmpfilename_num:
        defm    "0000$$$",0

msg_badnextzxos:
        defm    "Requires NextZXOS v1.98",'+'+$80


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

saved_speed:
        defb    0

old_caps:
        defb    0

tmpfilehandle:
        defb    $ff

filemap_buffer:
        defs    filemap_size*6          ; needs 6 bytes per entry

temp_num:
        defw    0                       ; number of current temporary file

bufferaddr:
        defw    0                       ; address of 4K buffer in main RAM

drivesize:
        defb    0                       ; size in MB of image to create (1-31)

file_size:
        defw    0,0                     ; size in bytes of image to create

filename:
        defs    256

sizeparam:
        defs    256
