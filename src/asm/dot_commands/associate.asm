; ***************************************************************************
; * Dot command to manage browser.cfg associations                          *
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
m_errh                  equ     $95             ; install error handler
f_open                  equ     $9a             ; opens a file
f_close                 equ     $9b             ; closes a file
f_read                  equ     $9d             ; read file
f_write                 equ     $9e             ; write file

; Error codes
esx_enoent              equ     $05             ; file/dir not found

; File access modes
esx_mode_read           equ     $01             ; read access
esx_mode_write          equ     $02             ; write access
esx_mode_open_exist     equ     $00             ; open existing files only
esx_mode_creat_trunc    equ     $0c             ; create new, delete existing

; 48K ROM calls
BC_SPACES_r3            equ     $0030           ; allocate workspace
PR_STRING_r3            equ     $203c           ; print string DE,BC

; Next Registers
next_reg_select         equ     $243b
next_reg_access         equ     $253b
nxr_turbo               equ     $07
turbo_max               equ     2


; ***************************************************************************
; * Internal definitions                                                    *
; ***************************************************************************

; Possible actions
action_list             equ     $01
action_show             equ     $02
action_delete           equ     $03
action_add              equ     $04

; Maximum size of browser.cfg
MAX_CFG_SIZE            equ     2048


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

        org     $2000

associate_init:
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
        jr      c,bad_nextzxos          ; must be esxDOS if error
        ld      hl,'N'<<8+'X'
        sbc     hl,bc                   ; check NextZXOS signature
        jr      nz,bad_nextzxos
        ld      hl,$0199
        ex      de,hl
        sbc     hl,de                   ; check version number >= 1.99
        jr      c,bad_nextzxos
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
        call    get_sizedarg            ; get an argument
        jr      nc,show_usage           ; if none, just show usage
        call    check_options
        jr      nz,show_usage           ; only options are allowed
        call    get_sizedarg
        jr      nc,associate_start      ; only one option is allowed
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        jr      error_handler           ; restore turbo setting and exit


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

error_handler:
        ld      sp,(saved_sp)           ; restore entry SP
        push    af
        ld      a,(saved_turbo)
        nxtrega nxr_turbo               ; restore entry turbo setting
        pop     af
        ret


; ***************************************************************************
; * Main operation                                                          *
; ***************************************************************************

associate_start:
        ; Reserve workspace to hold browser.cfg contents
        ld      bc,MAX_CFG_SIZE+1
        call48k BC_SPACES_r3            ; reserve the space, at DE
        ld      (workspace_addr),de

        ; Read the current browser.cfg file
        ld      a,'$'                   ; system drive
        ld      hl,msg_browsercfgname
        ld      b,esx_mode_read+esx_mode_open_exist
        callesx f_open                  ; attempt to open the file
        jr      nc,openedcfg
        cp      esx_enoent
        scf
        jr      nz,error_handler        ; cause any error except file not found
        ld      hl,msg_nobrowsercfg
        call    printmsg                ; warn that it wasn't found
        jr      usenewcfg
openedcfg:
        push    af                      ; save file handle
        ld      hl,(workspace_addr)
        ld      bc,MAX_CFG_SIZE+1       ; attempt to read max size + 1
        callesx f_read                  ; read the file
        pop     de                      ; D=file handle
        push    af                      ; save error condition
        push    bc                      ; save bytes read
        ld      a,d
        callesx f_close                 ; close the file
        pop     bc                      ; restore bytes read
        pop     af                      ; restore error condition
        jr      c,error_handler         ; exit with any error
        ld      hl,MAX_CFG_SIZE+1
        sbc     hl,bc                   ; were all bytes read?
        jr      nz,cfgsizeok
        ld      hl,msg_truncate
        call    printmsg                ; warn that it will be truncated
        ld      bc,MAX_CFG_SIZE         ; and limit size to maximum
cfgsizeok:
        ld      (cfg_size),bc           ; store size of file contents
usenewcfg:

        ; Probe the first line to determine line-ending convention
        call    probe_lineends          ; sets (lineend_type)

        ; Check which action is required and perform it.
        ld      a,(selected_action)
        cp      action_show
        jp      z,do_show_action
        cp      action_add
        jp      z,do_add_action
        cp      action_delete
        jp      z,do_delete_action
        ; drop through to do_list_action

; ***************************************************************************
; * Action: list                                                            *
; ***************************************************************************

do_list_action:
        ld      hl,0                    ; start of file
        push    hl
do_list_loop:
        pop     hl                      ; HL=current line offset
        push    hl
        call    get_line_length
        ex      (sp),hl                 ; get current line offset, stack next
        ld      a,d
        or      e
        jr      z,do_list_end
        ld      de,(workspace_addr)
        add     hl,de
        ex      de,hl                   ; DE=line address, BC=length
        call48k PR_STRING_r3            ; use ROM to print it
        ld      a,$0d                   ; CR
        print_char
        jr      do_list_loop
do_list_end:
        pop     hl                      ; discard line offset
finished:
        and     a                       ; completed successfully
        jp      error_handler           ; exit via err handler to restore turbo


; ***************************************************************************
; * Action: show                                                            *
; ***************************************************************************

do_show_action:
        call    find_type               ; find the appropriate line
        jr      nc,type_not_found
        ld      de,(workspace_addr)
        add     hl,de                   ; HL=address of line
        ex      de,hl                   ; DE=line address, BC=length
        call48k PR_STRING_r3            ; use ROM to print it
        ld      a,$0d                   ; CR
        print_char
        jr      finished
type_not_found:
        ld      hl,msg_nomatchingline
        jp      err_custom


; ***************************************************************************
; * Action: delete                                                          *
; ***************************************************************************

do_delete_action:
        call    delete_type             ; delete the appropriate line
        jr      nc,type_not_found
do_delete_multiple:
        call    delete_type             ; delete any more matches
        jr      c,do_delete_multiple
        call    save_cfgfile            ; save the updated browser.cfg
        jp      error_handler           ; exit with any error


; ***************************************************************************
; * Action: add                                                             *
; ***************************************************************************

do_add_action:
        call    delete_type             ; delete any existing matching line
        jr      c,do_add_action         ; make sure multiple matches deleted
        ld      hl,(ext_size)           ; HL=size of type
        ld      bc,(linearg_size)       ; BC=size of line
        add     hl,bc
        inc     hl                      ; HL=size of type+line+CR or LF
        ld      a,(lineend_type)
        and     a
        jr      nz,add_not_crlf
        inc     hl                      ; increment again if CRLF
add_not_crlf:
        ld      b,h
        ld      c,l                     ; BC=total size to insert
        ld      hl,(cfg_size)
        add     hl,bc
        ex      de,hl                   ; DE=final size of file
        ld      hl,MAX_CFG_SIZE
        and     a
        sbc     hl,de
        ld      hl,msg_cfgoverflow
        jp      c,err_custom            ; error if final size > maximum
        push    de                      ; save final size
        ld      hl,parsed_ext
add_check_wild_loop:
        ld      a,(hl)                  ; get next type char
        inc     hl
        and     a
        jr      z,add_at_start          ; if finished, insert at start
        cp      '*'
        jr      z,add_at_end            ; if wildcard, insert at end
        cp      '?'
        jr      nz,add_check_wild_loop
add_at_end:
        ld      hl,(cfg_size)           ; offset to insert is at end of file
        jr      add_got_offset
add_at_start:
        ld      hl,(workspace_addr)
        add     hl,de
        dec     hl
        ex      de,hl                   ; DE=final address of expanded file
        ld      hl,(workspace_addr)
        ld      bc,(cfg_size)           ; BC=current size of file
        ld      a,b
        or      c
        jr      z,add_no_move           ; nothing to do if currently empty file
        add     hl,bc
        dec     hl                      ; HL=final address of current file
        lddr                            ; shift whole file up
add_no_move:
        ld      hl,0                    ; offset to insert is at start of file
add_got_offset:
        ld      de,(workspace_addr)
        add     hl,de
        ex      de,hl                   ; DE=address to place new line
        ld      hl,parsed_ext
add_copy_ext:
        ld      a,(hl)                  ; get next char of type
        inc     hl
        and     a
        jr      z,add_copy_line         ; on if finished
        ld      (de),a                  ; store in file
        inc     de
        jr      add_copy_ext
add_copy_line:
        ld      hl,linearg
        ld      bc,(linearg_size)
        ldir                            ; copy in the line
        ld      a,(lineend_type)
        and     a
        jr      nz,add_cr_or_lf         ; on if line end is just CR or LF
        ld      a,$0d
        ld      (de),a                  ; else insert a CR first
        inc     de
        ld      a,$0a                   ; and then use a LF
add_cr_or_lf:
        ld      (de),a                  ; copy the terminator in
        pop     hl
        ld      (cfg_size),hl           ; update buffer size
        call    save_cfgfile            ; save the updated browser.cfg
        jp      error_handler           ; exit with any error


; ***************************************************************************
; * Delete a line matching the type                                         *
; ***************************************************************************
; Entry: parsed_ext contains type to find
; Exit:  Fc=0 if not found
;        Fc=1 if found and deleted

delete_type:
        call    find_type               ; find the appropriate line
        ret     nc                      ; exit if not found
        push    de                      ; save size to delete
        ex      de,hl                   ; DE=offset to move to, HL=line length
        add     hl,de                   ; HL=offset to move from
        ex      de,hl                   ; HL=move to offset, DE=move from offset
        push    hl
        ld      hl,(cfg_size)
        and     a
        sbc     hl,de
        ld      b,h
        ld      c,l                     ; BC=size to move
        pop     hl
        jr      z,delete_nomove         ; on if nothing to move
        push    bc
        ld      bc,(workspace_addr)
        add     hl,bc
        ex      de,hl                   ; DE=move to address
        add     hl,bc                   ; HL=move from address
        pop     bc                      ; BC=size to move
        ldir                            ; do the copy
delete_nomove:
        ld      hl,(cfg_size)
        pop     de
        and     a
        sbc     hl,de
        ld      (cfg_size),hl           ; update size
        scf                             ; Fc=1, line was found
        ret


; ***************************************************************************
; * Check line-ending convention                                            *
; ***************************************************************************

probe_lineends:
        ld      hl,0
        call    get_line_length         ; HL=next offset, DE-BC=lineend size
        ex      de,hl
        and     a
        sbc     hl,bc                   ; HL=length of lineend
        jr      z,probe_assume_crlf     ; if no lineend, default to CRLF (L=0)
        dec     l
        ld      l,0
        jr      nz,probe_assume_crlf    ; if 2 char lineend, use CRLF (L=0)
        ld      hl,(workspace_addr)
        add     hl,de                   ; HL=address of next line
        dec     hl                      ; address of line end
        ld      l,(hl)                  ; L=line end char, $0d or $0a
probe_assume_crlf:
        ld      a,l
        ld      (lineend_type),a        ; set line ending type: $0d, $0a, $00
        ret


; ***************************************************************************
; * Find line containing type                                               *
; ***************************************************************************
; Entry: parsed_ext contains type to find
; Exit:  Fc=0 if not found
;        Fc=1 if found, and:
;        HL=offset of found line
;        BC=line length, excluding CR and/or LF
;        DE=line length, including CR and/or LF

find_type:
        ld      hl,0                    ; starting offset
        push    hl
find_type_loop:
        pop     hl                      ; HL=offset of next line
        push    hl
        call    get_line_length         ; get length of this line
        ex      (sp),hl                 ; stack offset of next line, get current
        ld      a,d
        or      e
        jr      z,find_type_fail        ; on if end of file, with Fc=0
        push    bc
        push    de
        push    hl
        call    check_ext_match         ; does this line match?
        pop     hl
        pop     de
        pop     bc
        jr      nc,find_type_loop       ; keep searching if not
        pop     af                      ; discard offset of next line
        scf                             ; Fc=1, found
        ret
find_type_fail:
        pop     hl                      ; discard next line offset
        ret                             ; exit with Fc=0, not found


; ***************************************************************************
; * Get next line                                                           *
; ***************************************************************************
; Entry: HL=offset within browser.cfg
; Exit:  HL=offset of following line
;        BC=line length, excluding CR and/or LF
;        DE=line length, including CR and/or LF

get_line_length:
        ex      de,hl                   ; DE=offset
        ld      hl,(cfg_size)
        and     a
        sbc     hl,de                   ; HL=size remaining at offset
        ex      de,hl                   ; HL=offset, DE=size remaining
        ld      bc,(workspace_addr)
        add     hl,bc                   ; HL=address
        ld      bc,0                    ; BC=line length
        ld      ix,0                    ; IX=number of terminator chars
gll_loop:
        ld      a,d
        or      e
        jr      z,gll_endfile           ; finish if no bytes left
        ld      a,(hl)                  ; get next byte
        inc     hl
        dec     de
        cp      $0d
        jr      z,gll_endline           ; end of line if CR
        cp      $0a
        jr      z,gll_endline           ; or LF
        inc     bc                      ; increment line length
        jr      gll_loop
gll_endline:
        inc     ix                      ; increment number of terminators
        ld      a,d
        or      e
        jr      z,gll_endfile           ; finished if no bytes left
        ld      a,(hl)                  ; get char after CR/LF
        inc     hl
        dec     de
        cp      $0d
        jr      z,gll_endline           ; consume any further CR
        cp      $0a
        jr      z,gll_endline           ; or LF
        dec     hl                      ; backtrack to start of next line
gll_endfile:
        add     ix,bc                   ; IX=length+terminators
        ld      de,(workspace_addr)
        and     a
        sbc     hl,de                   ; HL=final offset
        push    ix
        pop     de                      ; DE=length including terminators
        ret


; ***************************************************************************
; * Check matching extension                                                *
; ***************************************************************************
; Entry: HL=offset within browser.cfg
;        BC=line length, excluding CR/LFs
;        parsed_ext=extension, uppercased and null-terminated
; Exit:  Fc=1 if match, Fc=0 if no match

check_ext_match:
        ld      de,(workspace_addr)
        add     hl,de                   ; HL=address
        ld      de,parsed_ext           ; DE=extension to match
check_ext_match_loop:
        ld      a,b                     ; check there are still more chars
        or      c
        ret     z                       ; exit with Fc=0, no match
        ld      a,(de)                  ; get next extension char
        inc     de
        and     a
        jr      z,check_ext_end         ; if end, check line ext also ends
        cp      (hl)                    ; check character matches in line
        scf
        ccf
        ret     nz                      ; exit with Fc=0, no match, if not
        inc     hl
        dec     bc
        jr      check_ext_match_loop
check_ext_end:
        ld      a,(hl)
        call    check_line_start        ; is the next character valid start?
        scf
        ret     z                       ; exit with Fc=1, match, if so
        ccf
        ret                             ; else exit with Fc=0, no match


; ***************************************************************************
; * Check valid line start character                                        *
; ***************************************************************************
; Entry: A=character
; Exit:  Fz=1 if character is ':', ';' or '<'

check_line_start:
        cp      ':'
        ret     z
        cp      ';'
        ret     z
        cp      '<'
        ret


; ***************************************************************************
; * Write the modified buffer back to the browser.cfg file                  *
; ***************************************************************************
; Exit: Fc=0 if successful
;       Fc=1, A=error if not

save_cfgfile:
        ld      a,'$'                   ; system drive
        ld      hl,msg_browsercfgname
        ld      b,esx_mode_write+esx_mode_creat_trunc
        callesx f_open                  ; attempt to create the file
        ret     c                       ; exit if error
        push    af                      ; save file handle
        ld      hl,(workspace_addr)
        ld      bc,(cfg_size)
        callesx f_write                 ; write the buffer
        pop     de                      ; D=file handle
        push    af                      ; save error condition
        ld      a,d
        callesx f_close                 ; close the file
        pop     hl
        ret     c                       ; exit with any error from close
        push    hl
        pop     af                      ; restore error condition from write
        ret                             ; exit with error status from write


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
opt0:   defm    "-l"
opt0_a: defw    option_list

        defb    opt1_a-opt1
opt1:   defm    "--list"
opt1_a: defw    option_list

        defb    opt2_a-opt2
opt2:   defm    "-h"
opt2_a: defw    show_usage

        defb    opt3_a-opt3
opt3:   defm    "--help"
opt3_a: defw    show_usage

        defb    opt4_a-opt4
opt4:   defm    "-s"
opt4_a: defw    option_show

        defb    opt5_a-opt5
opt5:   defm    "--show"
opt5_a: defw    option_show

        defb    opt6_a-opt6
opt6:   defm    "-d"
opt6_a: defw    option_delete

        defb    opt7_a-opt7
opt7:   defm    "--delete"
opt7_a: defw    option_delete

        defb    opt8_a-opt8
opt8:   defm    "-a"
opt8_a: defw    option_add

        defb    opt9_a-opt9
opt9:   defm    "--add"
opt9_a: defw    option_add

        ; End of table
        defb    0


; ***************************************************************************
; * -l, --list                                                              *
; ***************************************************************************

option_list:
        ld      a,action_list
        ld      (selected_action),a
        ret


; ***************************************************************************
; * -a, --add                                                               *
; ***************************************************************************

option_add:
        ld      a,action_add
        ld      (selected_action),a
        call    get_ext_arg             ; parse the type to parsed_ext
        call    get_sizedarg            ; get extension into temparg
        ld      (linearg_size),bc       ; save its size
        ld      a,b
        or      c
        ld      hl,msg_badline
        jp      z,err_custom            ; error if line length = 0
        ld      a,(temparg)
        call    check_line_start
        jp      nz,err_custom           ; or if doesn't begin with : ; <
        ld      hl,temparg
        ld      de,linearg
        ldir                            ; copy to linearg
        ret


; ***************************************************************************
; * -d, --delete                                                            *
; ***************************************************************************

option_delete:
        ld      a,action_delete
        ld      (selected_action),a
        jr      get_ext_arg


; ***************************************************************************
; * -s, --show                                                              *
; ***************************************************************************

option_show:
        ld      a,action_show
        ld      (selected_action),a
        ; drop through into get_ext_arg

; ***************************************************************************
; * Get extension argument                                                  *
; ***************************************************************************

get_ext_arg:
        call    get_sizedarg            ; get extension into temparg
        ld      a,c
        and     a                       ; must be 1+ chars (leaves Fc=0)
        jr      z,badext
        cp      4                       ; must be <= 3 chars
badext:
        ld      hl,msg_badtype13
        jp      nc,err_custom
        ld      (ext_size),bc           ; save size
        ld      hl,temparg
        ld      de,parsed_ext
parse_ext_loop:
        ld      a,(hl)                  ; get next char
        inc     hl
        call    check_line_start
        jr      z,bad_ext_char          ; invalid if ':', ';' or '<'
        cp      'a'
        jr      c,parse_ext_not_lower
        cp      'z'+1
        jr      nc,parse_ext_not_lower
        and     $df                     ; convert lower-case to upper-case
parse_ext_not_lower:
        ld      (de),a                  ; store next char
        inc     de
        dec     c
        jr      nz,parse_ext_loop
        xor     a
        ld      (de),a                  ; add null-terminator
        ret
bad_ext_char:
        ld      hl,msg_badtypechar
        jp      err_custom


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

; TAB 32 used within help message so it is formatted wide in 64/85 column mode.
msg_help:
        defm    "ASSOCIATEv1.0 by Garry Lancaster",$0d
        defm    "Manage Browser file associations",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .ASSOCIATE [OPTION]",$0d,$0d
        defm    "OPTIONS:",$0d
        defm    " -h, --help",23,32,0
        defm    "     Display this help",$0d
        defm    " -s, --show TYPE",23,32,0
        defm    "     Show entry for TYPE",$0d
        defm    " -d, --delete TYPE",23,32,0
        defm    "     Delete entry for TYPE",$0d
        defm    " -a, --add TYPE ",'"',"LINE",'"',23,32,0
        defm    "     Add/replace entry for TYPE",$0d
        defm    " -l, --list",23,32,0
        defm    "     List all entries",$0d
        defm    $0d,"INFO:",$0d,$0d
        defm    "TYPE is 1-3 chars (? * allowed)",$0d,$0d
        defm    "LINE starts with:",$0d
        defm    "  : return to menu afterwards",$0d
        defm    "  < return to Browser afterwards",$0d
        defm    "  ; return to BASIC afterwards",$0d
        defm    "Remainder of the line are BASIC",23,32,0
        defm    "commands to execute.",$0d
        defm    "  | is replaced by filename",$0d
        defm    "  ` is replaced by language code",$0d
        defm    "Use ",'\','"'," to include quote in line",$0d
        defm    $ff

msg_nobrowsercfg:
        defm    "browser.cfg missing: will create",$0d,$ff

msg_truncate:
        defm    "browser.cfg >2K: will truncate",$0d,$ff

msg_badnextzxos:
        defm    "Requires NextZXO",'S'+$80

msg_badtype13:
        defm    "Type must be 1-3 char",'s'+$80

msg_badtypechar:
        defm    "Invalid char in typ",'e'+$80

msg_nomatchingline:
        defm    "No matching lin",'e'+$80

msg_badline:
        defm    "Line must start with : < or ",';'+$80

msg_cfgoverflow:
        defm    "No room to add lin",'e'+$80

msg_unknownoption:
        defm    "Unknown option: "
temparg:
        defs    256

msg_browsercfgname:
        defm    "/nextzxos/browser.cfg",0


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

saved_sp:
        defw    0

saved_turbo:
        defb    0

workspace_addr:
        defw    0

cfg_size:
        defw    0

command_tail:
        defw    0

selected_action:
        defb    0

lineend_type:
        defb    0

ext_size:
        defw    0

parsed_ext:
        defs    4               ; max 3 chars, followed by null terminator

linearg_size:
        defw    0

linearg:
        defs    256
