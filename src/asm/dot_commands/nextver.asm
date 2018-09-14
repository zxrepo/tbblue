; ***************************************************************************
; * Dot command to return version of NextZXOS running                       *
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

; 48K ROM calls
BC_SPACES_r3            equ     $0030           ; allocate workspace
CALL_JUMP_r3            equ     $162c           ; execute routine at HL
CLASS_01_r3             equ     $1c1f           ; class 01, variable to assign
LET_r3                  equ     $2aff           ; LET
STACK_A_r3              equ     $2d28           ; push A to calculator stack

; System variables
CH_ADD                  equ     $5c5d


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

        org     $2000

nextver_init:
        ld      (saved_sp),sp           ; save entry SP for error handler
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
        jr      nc,no_argument
        call    check_options
        jr      z,parse_firstarg        ; if it was an option, try again
        ld      hl,msg_badvariable
        ld      a,c
        cp      1
        jr      nz,err_custom           ; actual argument must be 1 chars
        ld      a,(temparg)
        and     $df                     ; capitalise
        cp      'A'
        jr      c,err_custom            ; must be a letter
        cp      'Z'+1
        jr      nc,err_custom
        ld      (var_name),a            ; store as variable name
parse_remaining:
        call    get_sizedarg            ; get an argument
        jr      nc,nextver_start        ; okay if none
        call    check_options
        jr      z,parse_remaining       ; okay if a valid option
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        jr      error_handler           ; restore turbo setting and exit


; ***************************************************************************
; * Custom error generation                                                 *
; ***************************************************************************

err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        ; drop through to error_handler

; ***************************************************************************
; * Exit with any error condition                                           *
; ***************************************************************************

error_handler:
        ld      sp,(saved_sp)           ; restore entry SP
        ret


; ***************************************************************************
; * Calculator routine                                                      *
; ***************************************************************************
; This routine is executed from RAM with ROM 3 in place.
; It expects: MAJOR,MIDDLE,MINOR on the calculator stack and returns
; with the floating point value MAJOR+((MIDDLE+(MINOR/10))/10).

calc_routine:
        rst     $28                     ; engage FP calculator
        defb    $a4                     ; stk-10
        defb    $05                     ; division
        defb    $0f                     ; addition
        defb    $a4                     ; stk-10
        defb    $05                     ; division
        defb    $0f                     ; addition
        defb    $38                     ; end-calc
        ret
calc_routine_end:


; ***************************************************************************
; * No argument, but possibly --verbose option                              *
; ***************************************************************************

no_argument:
        ld      a,(display_ver)
        and     a
        jr      z,show_usage            ; if not verbose, show usage
        ; drop through to nextver_start

; ***************************************************************************
; * Main operation                                                          *
; ***************************************************************************

nextver_start:
        ; Reserve some workspace for the calculator routine/variable assignment.
        ld      bc,calc_routine_end-calc_routine
        call48k BC_SPACES_r3            ; reserve the space, at DE
        ld      (workspace_addr),de

        ; Obtain the NextZXOS version.
        callesx m_dosversion
        ld      ix,$0000                ; use version 0.00 if not NextZXOS
        jr      c,got_version           ; must be esxDOS if error
        jr      nz,got_version          ; need to be in NextZXOS mode
        ld      hl,'N'<<8+'X'
        sbc     hl,bc                   ; check NextZXOS signature
        jr      nz,got_version
        push    de
        pop     ix                      ; IX=version passed in DE
got_version:
        push    ix                      ; save version for later display
        ld      a,(var_name)
        and     a
        jr      z,skip_assign           ; skip if variable not provided
        ld      a,ixh
        call48k STACK_A_r3              ; CALC: major
        ld      a,ixl
        rrca
        rrca
        rrca
        rrca
        and     $0f
        call48k STACK_A_r3              ; CALC: major,middle
        ld      a,ixl
        and     $0f
        call48k STACK_A_r3              ; CALC: major,middle,minor
        ld      hl,calc_routine
        ld      de,(workspace_addr)
        ld      bc,calc_routine_end-calc_routine
        ldir                            ; copy routine into workspace
        ld      hl,(workspace_addr)
        call48k CALL_JUMP_r3            ; execute routine with ROM3 in place

        ; Assign the stacked value to the desired variable.
        ld      hl,(CH_ADD)
        push    hl
        ld      hl,(workspace_addr)
        ld      (CH_ADD),hl             ; temporarily move CH_ADD into workspace
        ld      a,(var_name)
        ld      (hl),a                  ; and store variable name there
        inc     hl
        ld      (hl),'='
        call48k CLASS_01_r3             ; initiate the assignment
        call48k LET_r3                  ; perform the assignment
        pop     hl
        ld      (CH_ADD),hl             ; restore CH_ADD

skip_assign:

        ; If verbose mode, display the version.
        pop     ix                      ; IX=version
        ld      a,(display_ver)
        and     a
        jr      z,finished
        ld      a,ixh
        add     a,'0'                   ; major
        print_char
        ld      a,'.'
        print_char
        ld      a,ixl
        rrca
        rrca
        rrca
        rrca
        and     $0f
        add     a,'0'                   ; middle
        print_char
        ld      a,ixl
        and     $0f
        add     a,'0'                   ; minor
        print_char
        ld      a,$0d
        print_char

finished:
        and     a                       ; completed successfully
        jp      error_handler           ; exit via err handler to restore turbo


; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        inc     a
        ret     z                       ; exit if terminator
        dec     a
        print_char
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
        addhl_A                         ; skip the option name
        inc     hl                      ; and the routine address
        inc     hl
        jr      check_next_option

invalid_option:
        ld      hl,temparg-1
        ld      a,c
        addhl_A
        set     7,(hl)                  ; set error terminator at end of option
        ld      hl,msg_unknownoption
        jp      err_custom


; ***************************************************************************
; * Options table                                                           *
; ***************************************************************************

option_table:

        defb    opt0_a-opt0
opt0:   defm    "-v"
opt0_a: defw    option_verbose

        defb    opt1_a-opt1
opt1:   defm    "--verbose"
opt1_a: defw    option_verbose

        defb    opt2_a-opt2
opt2:   defm    "-h"
opt2_a: defw    show_usage

        defb    opt3_a-opt3
opt3:   defm    "--help"
opt3_a: defw    show_usage

        ; End of table
        defb    0


; ***************************************************************************
; * -v, --verbose                                                           *
; ***************************************************************************

option_verbose:
        ld      a,1
        ld      (display_ver),a
        ret


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

; TAB 32 used within help message so it is formatted wide in 64/85 column mode.
msg_help:
        defm    "NEXTVER v1.0 by Garry Lancaster",$0d
        defm    "Set variable to NextZXOS version",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .NEXTVER [OPTION]... VARIABLE",$0d
        defm    "OPTIONS:",$0d
        defm    " -h, --help",23,32,0
        defm    "     Display this help",$0d
        defm    " -v, --verbose",23,32,0
        defm    "     Display the version",$0d
        defm    "INFO:",$0d
        defm    "Returns 0 if not NextZXOS mode",$0d
        defm    $ff

msg_unknownoption:
        defm    "Unknown option: "
temparg:
        defs    256

msg_badvariable:
        defm    "Var must be single lette",'r'+$80


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

saved_sp:
        defw    0

workspace_addr:
        defw    0

var_name:
        defb    0

display_ver:
        defb    0

command_tail:
        defw    0
