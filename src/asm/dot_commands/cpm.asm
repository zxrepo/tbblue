; ***************************************************************************
; * CP/M loader dot command                                                 *
; * .cpm                                                                    *
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


; ***************************************************************************
; * Argument parsing                                                        *
; ***************************************************************************
; Dot commands always start at $2000, with HL=address of command tail
; (terminated by $00, $0d or ':').

        org     $2000

        ld      hl,msg_help
        call    printmsg                ; for now just show usage info
        and     a                       ; Fc=0, successful
        ret                             ; exit


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
        ret


; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        and     a
        ret     z                       ; exit if terminator
        print_char()
        jr      printmsg


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

msg_help:       ;12345678901234567890123456789012
        defm    "CP/M Loader v0.2",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .CPM",$0d,$0d

        defm    "INFO:",$0d
        defm    "Support for CP/M is currently",$0d
        defm    "under development.",$0d,$0d

        defm    "Once available it will allow you",$0d
        defm    "to run classic utilities,",$0d
        defm    "productivity software, games",$0d
        defm    "and more written to run on the",$0d
        defm    "CP/M 2 or 3 operating systems.",$0d,$0d

        defm    "Keep an eye on www.specnext.com",$0d
        defm    "for details of how to get this",$0d
        defm    "running on your Next.",$0d,$0d,0

msg_badnextzxos:
        defm    "Requires NextZXOS v1.99",'+'+$80


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************
