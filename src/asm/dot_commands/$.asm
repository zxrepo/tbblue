; ***************************************************************************
; * Dot command with string argument executor                               *
; * .$                                                                      *
; ***************************************************************************

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
m_gethandle             equ     $8d             ; get dot command file handle
f_open                  equ     $9a             ; opens a file
f_close                 equ     $9b             ; closes a file
f_read                  equ     $9d             ; read file

; ROM 3 routines
NEXT_ONE_r3             equ     $19b8           ; find next variable
BC_SPACES_r3            equ     $0030           ; allocate workspace
OUT_CODE_r3             equ     $15ef           ; digit output
OUT_SP_NO_r3            equ     $192a           ; numeric place output

; System variables
VARS                    equ     $5c4b           ; addr of variables area

; File access modes
esx_mode_read           equ     $01             ; read access
esx_mode_open_exist     equ     $00             ; open existing files only


; ***************************************************************************
; * Argument parsing                                                        *
; ***************************************************************************
; Dot commands always start at $2000, with HL=address of command tail
; (terminated by $00, $0d or ':').

        org     $2000

        push    hl
        callesx m_dosversion            ; esxDOS or NextZXOS?
        jr      c,isesxdos              ; must be esxDOS if error
        ld      hl,'N'<<8+'X'
        sbc     hl,bc
        jr      z,isnextzxos
isesxdos:
        ld      hl,esxcmdname
        ld      de,commandname
        ld      bc,filename-commandname
        ldir                            ; replace "/DOT/" with "/BIN/"
        jr      notnextzxos
isnextzxos:
        callesx m_gethandle             ; close $'s handle, so the same handle
        callesx f_close                 ; will be used for the chained dot
notnextzxos:
        pop     hl
        ld      a,h
        or      l
        jr      z,show_usage            ; no tail provided if HL=0
        ld      de,filename
        call    get_sizedarg            ; get first argument to filename
        jr      nc,show_usage           ; if none, just go to show usage
        ld      (command_len),bc        ; store command length
        ld      de,varname
        call    get_sizedarg            ; get second argument to varname
        jr      nc,show_usage           ; if none, just go to show usage
        ld      a,b
        and     a
        jr      nz,show_usage           ; length must be 2
        ld      a,c
        cp      2
        jr      nz,show_usage
        ld      a,(varname+1)
        cp      '$'                     ; 2nd char must be '$'
        jr      nz,show_usage
        ld      de,0                    ; further args to ROM
        call    get_sizedarg            ; check if any further args
        jr      nc,string_start         ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        ret

string_start:
        ld      a,(varname)             ; get the string letter
        and     $df                     ; capitalise
        cp      'A'
        jr      c,show_usage            ; show help if < A
        cp      'Z'+1
        jr      nc,show_usage           ; or if > Z
        and     $1f
        ld      c,a                     ; C=bits 0..4 of letter
        set     6,c                     ; bit 6=1 for strings
        ld      hl,(VARS)
v_each:
        ld      a,(hl)                  ; first letter of next variable
        and     $7f
        jr      z,v_not_found           ; on if $80 encountered (end of vars)
        cp      c
        jr      z,v_found               ; on if matches string name
        push    bc
        call48k NEXT_ONE_r3             ; DE=next variable
        pop     bc
        ex      de,hl                   ; HL=next variable
        jr      v_each                  ; back to check it
v_found:
        inc     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC=string length
        inc     hl                      ; HL=string address
trimstring:
        ld      a,b
        or      c
        jr      z,gotstring
        ld      a,(hl)
        cp      ' '
        jr      nz,gotstring            ; on when non-space encountered
        inc     hl                      ; trim the space
        dec     bc
        jr      trimstring
gotstring:
        ld      (string_len),bc         ; save string length
        inc     bc                      ; increment length for terminator
        push    hl
        push    bc
        ld      hl,routine_end-routine
        add     hl,bc                   ; add space for routine to load dot
        ld      bc,(command_len)
        add     hl,bc                   ; add space for command name
        inc     hl                      ; and a separating space
        ld      b,h
        ld      c,l
        call48k BC_SPACES_r3            ; reserve workspace for string
        ld      (name_addr),de          ; save start of command name in workspace
        ld      hl,filename
        ld      bc,(command_len)
        ldir                            ; copy command in
        ld      a,' '
        ld      (de),a                  ; insert separating space
        inc     de
        pop     bc
        pop     hl
        ld      (string_addr),de        ; save start of string in workspace
        ldir                            ; copy string+1 byte
        dec     de
        ld      a,$0d
        ld      (de),a                  ; place terminator in final byte
        inc     de                      ; DE=address after string
        push    de
        ld      hl,routine
        ld      bc,routine_end-routine
        ldir                            ; copy routine into RAM workspace
        ld      a,'$'
        ld      hl,commandname
        ld      b,esx_mode_read+esx_mode_open_exist
        callesx f_open                  ; attempt to open dot command
        pop     hl                      ; HL=address of RAM routine
        ret     c                       ; exit with any error
        jp      (hl)                    ; execute rest of routine in RAM

v_not_found:
        ld      hl,msg_varnotfound
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
; * Routine to be executed in main RAM workspace                            *
; ***************************************************************************

routine:
        ld      hl,(string_addr)
        push    hl                      ; save address of argument for command
        ld      hl,(name_addr)
        push    hl                      ; save address of full command line
        ld      hl,$2000
        ld      bc,$2000
        callesx f_read                  ; read dot command into dot area
        pop     bc                      ; BC=address of full command line
        pop     hl                      ; HL=address of argument
        ret     c                       ; exit if error reading
        jp      $2000                   ; jump to execute new dot command
routine_end:


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
        defm    "$ v1.3 by Garry Lancaster",$0d
        defm    "Executes any dot command with a",$0d
        defm    "string argument.",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .$ <COMMAND> <LETTER>$",$0d,$0d
        defm    "INFO:",$0d
        defm    "eg:  LET x$=",'"',"myfile.dsk",'"',$0d
        defm    "     .$ DEFRAG x$",$0d,$0d
        defm    "does the same as:",$0d
        defm    "     .DEFRAG myfile.dsk",$0d,0


msg_varnotfound:
        defm    "Variable not foun",'d'+$80


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

routine_addr:
        defw    0

name_addr:
        defw    0

string_addr:
        defw    0

string_len:
        defw    0

command_len:
        defw    0

esxcmdname:
        defm    "/BIN/"

commandname:
        defm    "/DOT/"
filename:
        defs    256

varname:
        defs    256

