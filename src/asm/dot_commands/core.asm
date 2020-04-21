; ***************************************************************************
; * Dot command to reboot to an alternative core                            *
; ***************************************************************************

Z80N    equ     1
include "macros.def"
include "nexthw.def"

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
; * API and other definitions required                                      *
; ***************************************************************************

; esxDOS calls
m_dosversion            equ     $88             ; get version information
m_errh                  equ     $95             ; install error handler

; ROM3 calls
BC_SPACES_r3            equ     $0030           ; allocate workspace


; ***************************************************************************
; * Internal definitions                                                    *
; ***************************************************************************

MIN_NEXTZXOS_VER        equ     $0205   ; v2.05 needed for AltROMs


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

        org     $2000

core_init:
        ld      (saved_sp),sp           ; save entry SP for error handler
        push    hl                      ; save address of arguments
        ld      bc,next_reg_select
        ld      a,nxr_turbo
        out     (c),a
        inc     b
        in      a,(c)                   ; get current turbo setting
        ld      (saved_turbo),a
        ld      a,turbo_max
        out     (c),a                   ; and set to maximum
        callesx m_dosversion
        jp      c,bad_nextzxos          ; must be esxDOS if error
        ld      hl,'N'<<8+'X'
        sbc     hl,bc                   ; check NextZXOS signature
        jp      nz,bad_nextzxos
        ld      hl,MIN_NEXTZXOS_VER
        ex      de,hl
        sbc     hl,de                   ; check version number
        jp      c,bad_nextzxos
        ld      hl,error_handler
        callesx m_errh                  ; install error handler to reset turbo
        pop     hl                      ; restore address of arguments
        ; drop through to parse_arguments

; ***************************************************************************
; * Argument parsing                                                        *
; ***************************************************************************
; Entry: HL=0, or address of command tail (terminated by $00, $0d or ':').

parse_arguments:
        ld      a,h
        or      l
        jr      z,show_usage            ; no tail provided if HL=0
        ld      (command_tail),hl       ; initialise pointer
parse_firstarg:
        call    get_sizedarg            ; get an argument
        jr      nc,show_usage           ; if none, just show usage
        call    check_options
        jr      z,parse_firstarg        ; if it was an option, try again
        ld      de,coreboot_dirname
        call    set_corearg             ; use 1st arg as core name
parse_2ndarg:
        call    get_sizedarg            ; get an argument
        jr      nc,core_start           ; start processing if no more args
        call    check_options
        jr      z,parse_2ndarg          ; if it was an option, try again
        ld      de,coreboot_filename
        call    set_corearg             ; use 2nd arg as launch filename
parse_remaining:
        call    get_sizedarg            ; get an argument
        jr      nc,core_start           ; start processing if no more args
        call    check_options
        jr      z,parse_remaining       ; if it was an option, try again
                                        ; if 3+ args provided, just show usage
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        jr      error_handler           ; exit via error handler to tidy up


; ***************************************************************************
; * Custom error generation                                                 *
; ***************************************************************************

bad_nextzxos:
        ld      hl,msg_badnextzxos
        ; drop through to err_custom
err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        ; drop through to error_handler

; ***************************************************************************
; * Exit with any error condition                                           *
; ***************************************************************************
; NOTE: It's not necessary to close any files that may be open, since NextZXOS
;       does this automatically when the dot command terminates.

error_handler:
        ld      sp,(saved_sp)           ; restore entry SP
        push    af
        ld      a,(saved_turbo)
        nxtrega nxr_turbo               ; restore entry turbo setting
        pop     af
        ret


; ***************************************************************************
; * Set a core name / file name argument                                    *
; ***************************************************************************
; Entry: DE=destination
;        BC=length, 1-255

set_corearg:
        ld      hl,temparg
        ld      a,c
        ld      b,a
        cp      16
        jr      c,set_corearg_copy
        ld      b,15                    ; limit to max 15 chars
set_corearg_copy:
        ld      a,(hl)
        inc     hl
        cp      'a'
        jr      c,set_corearg_notlower
        cp      'z'+1
        jr      nc,set_corearg_notlower
        and     $df                     ; make letters uppercase
set_corearg_notlower:
        ld      (de),a
        inc     de
        djnz    set_corearg_copy
        ret


; ***************************************************************************
; * Main operation                                                          *
; ***************************************************************************

core_start:
        ld      hl,coreboot_struct
        ld      b,127
        xor     a
core_checksum_loop:
        add     a,(hl)
        inc     hl
        djnz    core_checksum_loop
        sub     $cb
        neg
        ld      (hl),a                  ; ensure checksummed value is 0xCB
        ld      bc,coreboot_launcher_end-coreboot_launcher
        push    bc
        call48k BC_SPACES_r3            ; reserve space for launcher, at DE
        pop     bc
        ld      hl,coreboot_launcher
        push    de                      ; save address of workspace destination
        ldir                            ; copy launcher to workspace
        pop     hl                      ; HL=address of launcher
        jp      (hl)                    ; execute it


; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        inc     a
        ret     z                       ; exit if terminator
        dec     a
        print_char()
        jr      printmsg


; ***************************************************************************
; * Parse an argument from the command tail                                 *
; ***************************************************************************
; Entry: (command_tail)=remaining command tail
; Exit:  Fc=0 if no argument
;        Fc=1: parsed argument has been copied to temparg and null-terminated
;        (command_tail)=command tail after this argument
;        BC=length of argument
; NOTE: BC is validated to be 0..255; if not, it does not return but instead
;       exits via show_usage.

get_sizedarg:
        ld      hl,(command_tail)
        ld      de,temparg
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
        ld      (command_tail),hl       ; update command tail pointer
        scf                             ; Fc=1, argument found
        ret
get_sizedarg_quoted:
        ld      a,(hl)
        and     a
        jr      z,get_sizedarg_complete ; finished if found $00
        cp      $0d
        jr      z,get_sizedarg_complete ; or CR
        inc     hl
        cp      '"'                     ; if a quote, need to check if escaped or not
        jr      z,get_sizedarg_checkendquote
        ld      (de),a                  ; store next char into dest
        inc     de
        inc     c                       ; increment length
        jr      z,get_sizedarg_badsize  ; don't allow >255
        jr      get_sizedarg_quoted
get_sizedarg_badsize:
        pop     af                      ; discard return address
        jp      show_usage
get_sizedarg_checkendquote:
        inc     c
        dec     c
        jr      z,get_sizedarg_complete ; definitely endquote if no chars yet
        dec     de
        ld      a,(de)
        inc     de
        cp      '\'                     ; was it escaped?
        jr      nz,get_sizedarg_complete; if not, was an endquote
        dec     de
        ld      a,'"'
        ld      (de),a                  ; otherwise replace \ with "
        inc     de
        jr      get_sizedarg_quoted


; ***************************************************************************
; * Check for options                                                       *
; ***************************************************************************
; Entry: temparg contains argument, possibly option name
;        C=length of argument
; Exit:  C=length of argument (preserved if not an option)
;        Fz=1 if was an option (and has been processed)
;        Fz=0 if not an option

check_options:
        ld      a,(temparg)
        cp      '-'
        ret     nz                      ; exit with Fz=0 if not an option
        ld      hl,option_table
check_next_option:
        ld      a,(hl)
        inc     hl
        and     a
        jr      z,invalid_option        ; cause error if end of table
        cp      c
        jr      nz,skip_option          ; no match if lengths differ
        ld      b,a                     ; length to compare
        ld      de,temparg
check_option_name_loop:
        ld      a,(de)
        inc     de
        cp      'A'
        jr      c,check_opt_notupper
        cp      'Z'+1
        jr      nc,check_opt_notupper
        or      $20                     ; convert uppercase to lowercase
check_opt_notupper:
        cp      (hl)
        jr      nz,option_mismatch
        inc     hl
        djnz    check_option_name_loop
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE=routine address
        pushval perform_option_end
        push    de
        ret                             ; execute the option routine
perform_option_end:
        xor     a                       ; Fz=1, option was found
        ret
option_mismatch:
        ld      a,b                     ; A=remaining characters to skip
skip_option:
        addhl_A()                       ; skip the option name
        inc     hl                      ; and the routine address
        inc     hl
        jr      check_next_option

invalid_option:
        ld      hl,temparg-1
        ld      a,c
        addhl_A()
        set     7,(hl)                  ; set error terminator at end of option
        ld      hl,msg_unknownoption
        jp      err_custom


; ***************************************************************************
; * Options table                                                           *
; ***************************************************************************

option_table:

        defb    opt0_a-opt0
opt0:   defm    "-h"
opt0_a: defw    show_usage

        defb    opt1_a-opt1
opt1:   defm    "--help"
opt1_a: defw    show_usage

        ; End of table
        defb    0


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

; TAB 32 used within help message so it is formatted wide in 64/85 column mode.
msg_help:
        defm    "CORE v0.1 by Garry Lancaster",$0d
        defm    "Boot an alternative core",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    ".CORE [OPT] CORENAME [FILE]",$0d,$0d
        defm    "OPTIONS:",$0d
        defm    " -h, --help",23,32,0
        defm    "     Display this help",$0d,$0d
        defm    "Depending upon the core, a file",$0d
        defm    "located in the core's standard",$0d
        defm    "files directory (eg a game ROM)",$0d
        defm    "may be specified",$0d,$0d
        defm    "Examples:",$0d
        defm    "  .core atom",$0d
        defm    "  .core cpc6128 game.dsk",$0d,$0d
        defm    $ff

msg_badnextzxos:
        defm    "Requires NextZXOS v"
        defb    '0'+((MIN_NEXTZXOS_VER/$100)&$0f)
        defb    '.'
        defb    '0'+((MIN_NEXTZXOS_VER/$10)&$0f)
        defb    '0'+(MIN_NEXTZXOS_VER&$0f)
        defb    '+'+$80

msg_unknownoption:
        defm    "Unknown option: "
temparg:
        defs    256


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

saved_sp:
        defw    0

saved_turbo:
        defb    0

command_tail:
        defw    0

coreboot_launcher:
        di
        xor     a
        out     (div_memctl),a          ; page out DivMMC
        nxtregn nxr_altrom,$d0          ; lock AltROM0 for writing
        addhl_N coreboot_struct-coreboot_launcher
        ld      de,0
        ld      bc,128
        ldir                            ; copy struct into AltROM0
        nxtregn nxr_reset,2             ; hard reset

coreboot_struct:
        defm    "COREBOOT"
coreboot_dirname:
        defs    16
coreboot_filename:
        defs    16
coreboot_padding:
        defs    87
coreboot_checksum:
        defb    0
coreboot_launcher_end:
