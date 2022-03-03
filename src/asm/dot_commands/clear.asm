; ***************************************************************************
; * Dot command for clearing user-installed drivers, allocated memory etc   *
; * .clear                                                                  *
; ***************************************************************************

include "macros.def"
include "nexthw.def"


; ***************************************************************************
; * Macros                                                                  *
; ***************************************************************************

macro call48k,address
        rst     $18
        defw    address
endm

macro callesx,hook
        rst     $8
        defb    hook
endm


; ***************************************************************************
; * esxDOS API and other definitions required                               *
; ***************************************************************************

; Calls
m_drvapi                equ     $92
m_p3dos                 equ     $94

; +3DOS API calls
ide_bank                equ     $01bd
ide_basic               equ     $01c0

; ROM 3 routines
BC_SPACES_r3            equ     $0030           ; allocate workspace

; Tokens
token_bank              equ     $9a
token_peek              equ     $be
token_to                equ     $cc
token_for               equ     $eb
token_next              equ     $f3
token_clear             equ     $fd


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************
; Dot commands always start at $2000, with HL=address of command tail
; (terminated by $00, $0d or ':').

        org     $2000

        ld      bc,next_reg_select
        ld      a,nxr_turbo
        out     (c),a
        inc     b
        in      a,(c)                   ; get current turbo setting
        ld      (saved_turbo),a
        ld      a,turbo_max
        out     (c),a                   ; and set to maximum
        ld      a,h
        or      l
        jr      z,clear_start           ; no tail provided if HL=0
        ld      de,0                    ; any args to ROM
        call    get_sizedarg            ; get first argument to filename
        jr      nc,clear_start          ; if none, perform clear
show_usage:
        ld      hl,msg_help
        call    printmsg
clear_finish:
        ld      a,(saved_turbo)
        nxtrega nxr_turbo               ; restore entry turbo setting
        and     a                       ; Fc=0, successful
        ret


; ***************************************************************************
; * Uninstall drivers                                                       *
; ***************************************************************************

clear_start:
        ld      bc,$817f                ; C=max driver id; B=$81, shutdown
uninstall_loop:
        push    bc
        callesx m_drvapi                ; shut down the driver, if need be
        pop     bc
        push    bc
        ld      e,c                     ; E=driver ID
        ld      bc,$0200                ; C=0, driver API; B=$02, uninstall
        callesx m_drvapi                ; uninstall the driver
        pop     bc
        dec     c
        jr      nz,uninstall_loop

; ***************************************************************************
; * Deallocate ZX memory allocated for non-BASIC purposes                   *
; ***************************************************************************

        ld      hl,$0000                ; get total number of ZX banks
        exx
        ld      de,ide_bank
        ld      c,7
        callesx m_p3dos                 ; E=total number of ZX banks
dealloczx_loop:
        push    de
        dec     e                       ; E=next bank id
        ld      hl,$0003                ; free ZX bank
        exx
        ld      de,ide_bank
        ld      c,7
        callesx m_p3dos                 ; free ZX bank E
        pop     de
        dec     e
        jr      nz,dealloczx_loop

; ***************************************************************************
; * Deallocate ZX memory allocated for BASIC purposes                       *
; ***************************************************************************

        ld      bc,msg_bankclear_end-msg_bankclear
        call48k BC_SPACES_r3            ; DE=workspace address
        ld      hl,msg_bankclear
        ld      bc,msg_bankclear_end-msg_bankclear
        push    de
        ldir                            ; copy command to RAM buffer
        pop     hl                      ; command address
        exx
        ld      c,0                     ; RAM 0
        ld      de,ide_basic
        callesx m_p3dos                 ; release BASIC-allocated banks
        jp      clear_finish


; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        and     a
        ret     z                       ; exit if terminator
        rst     $10                     ; print character
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
; * Data                                                                    *
; ***************************************************************************

saved_turbo:
        defb    0


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

msg_help:
        defm    "CLEAR v1.0 by Garry Lancaster",$0d
        defm    "Releases all allocated resources",$0d
        defm    "leaving maximum available memory",$0d,$0d
        defm    "NOTE: Uses integer register %a",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .CLEAR",$0d,0

msg_bankclear:
        defm    token_for,"%a=%12",token_to,"%",token_peek
        defm    "23401:",token_bank,"%a",token_clear,":"
        defm    token_next,"%a:%a=%0",$0d
msg_bankclear_end:
