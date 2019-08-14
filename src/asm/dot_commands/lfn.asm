; ***************************************************************************
; * Dot command to convert short filename to long filename                  *
; * .LFN shortname                                                          *
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
m_dosversion            equ     $88             ; get version information
m_p3dos                 equ     $94             ; execute +3DOS call

; Errors
esx_enoent              equ     $05             ; no such file or dir

; +3DOS calls
DOS_CATALOG             equ     $011e
IDE_GET_LFN             equ     $01b7

; ROM 3 routines
BC_SPACES_r3            equ     $0030           ; allocate workspace


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
        ld      (filename_len),bc       ; store filename length
        ld      de,0                    ; further args to ROM
        call    get_sizedarg            ; check if any further args
        jr      nc,lfn_start            ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        ret


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

lfn_start:
        ld      hl,(filename_len)
        ld      bc,1+261+13+13
        add     hl,bc                   ; enough space for filenames & catalog
        ld      b,h
        ld      c,l
        call48k BC_SPACES_r3            ; reserve workspace
        ld      (filename_addr),de      ; store address for short filename
        ld      hl,filename
        ld      bc,(filename_len)
        ldir                            ; copy filename into RAM
        ld      a,$ff
        ld      (de),a                  ; and terminate with $ff
        inc     de
        ld      (catalog_addr),de       ; store address for catalog entries
        ld      b,13+13
        xor     a
erase_catloop:
        ld      (de),a                  ; erase 2 x 13-byte catalog entries
        inc     de
        djnz    erase_catloop
        ld      (lfn_addr),de           ; store address for LFN
        callesx m_dosversion
        jr      c,bad_nextzxos          ; must be esxDOS if error
        jr      nz,bad_nextzxos         ; need to be in NextZXOS mode
        ld      hl,'N'<<8+'X'
        sbc     hl,bc                   ; check NextZXOS signature
        jr      nz,bad_nextzxos
        ld      hl,$0199
        ex      de,hl
        sbc     hl,de                   ; check version number >= 1.99
        jr      nc,good_nextzxos
bad_nextzxos:
        ld      hl,msg_badnextzxos
        ; drop through to err_custom

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
; * Find the LFN                                                            *
; ***************************************************************************

good_nextzxos:
        ld      bc,$0207                ; 2 entries, include sys/lfn/dirs
        ld      de,(catalog_addr)
        ld      hl,(filename_addr)
        exx
        ld      c,7                     ; RAM 7
        ld      de,DOS_CATALOG
        callesx m_p3dos                 ; get the catalog results
        ccf
        push    hl
        pop     ix                      ; IX=directory handle
        ld      hl,msg_badcatalog
        jr      c,err_custom            ; exit if catalog call failed
        dec     b                       ; discard preloaded entry
        ld      a,esx_enoent
        scf
        ret     z                       ; file not found error if no entries
        ld      hl,(catalog_addr)
        ld      de,13
        add     hl,de
        ex      de,hl                   ; DE=address of returned entry
        ld      hl,(filename_addr)
        ld      bc,(lfn_addr)
        exx
        push    ix
        pop     hl                      ; HL=directory handle
        ld      c,7                     ; RAM 7
        ld      de,IDE_GET_LFN
        callesx m_p3dos                 ; obtain the LFN
        ccf
        ld      hl,msg_nolfn
        jr      c,err_custom            ; exit if get lfn call failed
        ld      hl,(lfn_addr)
printlfn:
        ld      a,(hl)                  ; get next LFN char
        inc     hl
        cp      $ff
        jr      z,printlfn_end          ; on if terminator found
        print_char()                    ; else print char
        jr      printlfn
printlfn_end:
        ld      a,$0d
        print_char()                    ; CR
        and     a                       ; success
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
; * Messages                                                                *
; ***************************************************************************

msg_help:
        defm    "LFN v1.2 by Garry Lancaster",$0d
        defm    "Returns the long filename for a",$0d
        defm    "short (8.3) name.",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .LFN filename",$0d,0

msg_badnextzxos:
        defm    "Requires NextZXOS mod",'e'+$80

msg_badcatalog:
        defm    "DOS_CATALOG call faile",'d'+$80

msg_nolfn:
        defm    "Couldn't obtain LF",'N'+$80


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

filename_len:
        defw    0

filename_addr:
        defw    0

catalog_addr:
        defw    0

lfn_addr:
        defw    0

filename:
        defs    256

