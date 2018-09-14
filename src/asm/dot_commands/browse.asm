; ***************************************************************************
; * Dot command to show a Browser dialog and return the results             *
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
m_gethandle             equ     $8d             ; get dot command's filehandle
m_p3dos                 equ     $94             ; execute +3DOS call
m_errh                  equ     $95             ; install error handler
f_close                 equ     $9b             ; close a file

; +3DOS calls
IDE_STREAM_OPEN         equ     $0056           ; open stream to ext. channel
IDE_STREAM_CLOSE        equ     $0059           ; close stream
IDE_WINDOW_LINEIN       equ     $01c3           ; input string in window
IDE_WINDOW_STRING       equ     $01c6           ; output string to window
IDE_BROWSER             equ     $01ba           ; file browser dialog
IDE_MODE                equ     $01d5           ; query/set mode

; Capability masks for IDE_BROWSER
BROWSERCAPS_COPY        equ     $01
BROWSERCAPS_RENAME      equ     $02
BROWSERCAPS_MKDIR       equ     $04
BROWSERCAPS_ERASE       equ     $08
BROWSERCAPS_REMOUNT     equ     $10
BROWSERCAPS_UNMOUNT     equ     $20

; 48K ROM calls
BC_SPACES_r3            equ     $0030           ; allocate workspace
CLS_r3                  equ     $0d6b           ; CLS (for layer 0)
CHAN_OPEN_r3            equ     $1601           ; open channel to stream
CLASS_01_r3             equ     $1c1f           ; class 01, variable to assign
STK_STO_S_r3            equ     $2ab2           ; store string on calc stack
LET_r3                  equ     $2aff           ; LET

; System variables
OLDSP                   equ     $5b6a
TMPVARS                 equ     $5b8a
TSTACK                  equ     $5bff
STRMS                   equ     $5c10
CURCHL                  equ     $5c51
CH_ADD                  equ     $5c5d

; Next Registers
next_reg_select         equ     $243b
next_reg_access         equ     $253b
nxr_turbo               equ     $07
turbo_max               equ     2
nxr_mmu6                equ     $56
nxr_mmu7                equ     $57

; Limits
MAX_FILETYPES           equ     12              ; should be more than enough
MAX_HELP_SIZE           equ     166             ; 2*51 chars plus control chars
MAX_LFN_SIZE            equ     261             ; max LFN length inc terminator

; Use some main RAM below $c000 for buffers to pass to IDE_BROWSER,
; IDE_WINDOW_STRING  and IDE_WINDOW_LINEIN, and to receive a filename
; (this RAM will be saved/restored in DivMMC RAM). The stack will also
; be located here
ram_buffer              equ     $6000
; Space for "X$=" plus an LFN, and a 128-byte stack
RAM_BUFFER_SIZE         equ     MAX_LFN_SIZE+3+128

if (RAM_BUFFER_SIZE < (MAX_HELP_SIZE+1+(4*MAX_FILETYPES)+1))
.ERROR RAM_BUFFER_SIZE not large enough to hold help and filetypes
endif

; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

        org     $2000

browse_init:
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
        jr      nz,bad_nextzxos         ; need to be in NextZXOS mode
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
parse_firstarg:
        call    get_sizedarg            ; get an argument
        jr      nc,show_usage           ; if none, just go to show usage
        call    check_options
        jr      z,parse_firstarg        ; if it was an option, try again
        ld      hl,msg_badstring
        ld      a,c
        cp      2
        jr      nz,err_custom           ; actual argument must be 2 chars
        ld      a,(temparg)
        and     $df                     ; capitalise
        cp      'A'
        jr      c,err_custom            ; must be a letter
        cp      'Z'+1
        jr      nc,err_custom
        ld      (var_name),a            ; store as variable name
        ld      a,(temparg+1)
        cp      '$'                     ; must be followed by '$'
        jr      nz,err_custom
parse_remaining:
        call    get_sizedarg            ; get an argument
        jr      nc,browse_start         ; okay if none
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

bad_nextzxos:
        ld      hl,msg_badnextzxos
        ; drop through to err_custom
err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        ; drop through to error_handler

; ***************************************************************************
; * Restore turbo setting and exit with any error condition                 *
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

browse_start:
        ; Reserve some workspace for a window definition and for a temporary
        ; store for the final filename before assigning to a string variable.
        ld      bc,MAX_LFN_SIZE
        call48k BC_SPACES_r3            ; reserve the space, at DE
        ld      (workspace_addr),de

        ; Close the system handle for our dot command file. If we didn't do
        ; this, it wouldn't be possible to remount from within the browser.
        callesx m_gethandle
        callesx f_close

        ; Save the current layer/mode and switch to layer 0
        call    get_mode
        push    af
        and     $03
        ld      (saved_layer),a         ; save the original layer
        pop     af
        rrca
        rrca
        and     $03
        ld      (saved_submode),a       ; save submode for layer 1
        ld      bc,$0101
        call    set_mode                ; set mode to layer 1,1
        ld      a,b
        ld      (saved_l11size),a       ; save character size for layer 1,1
        ld      a,e
        ld      (saved_l11attr),a       ; save attributes for layer 1,1

        ; Open a text window for editing the filename if necessary
        ld      hl,(CURCHL)
        ld      (saved_curchl),hl       ; save current channel pointer
        ld      hl,(STRMS+36)
        ld      (saved_strm15),hl       ; save original #15 pointer
        ld      hl,0
        ld      (STRMS+36),hl           ; and zero so it's available to us
        ld      hl,windef
        ld      de,(workspace_addr)
        ld      bc,windef_end-windef
        push    de
        push    bc
        ldir                            ; copy window def into main RAM
        pop     bc
        pop     de
        ld      a,15
        exx
        ld      c,0                     ; IDE_STREAM_OPEN needs main RAM
        ld      de,IDE_STREAM_OPEN
        callesx m_p3dos                 ; open the text window
        ld      a,15
        call48k CHAN_OPEN_r3            ; make our #15 window current
        ld      hl,(CURCHL)
        ld      (window_curchl),hl      ; and save the channel pointer for it

        ; Save data in the main RAM buffer, and copy in filetypes & help
        ; The stack is also relocated into the main RAM buffer so it is
        ; below $c000 and safe for use with +3DOS calls.
        ld      hl,ram_buffer
        ld      de,saved_ram
        ld      bc,RAM_BUFFER_SIZE
        ldir                            ; save some RAM below $c000
        ld      sp,ram_buffer+RAM_BUFFER_SIZE
        ld      hl,filetypes
        ld      de,ram_buffer
        push    de                      ; save address of filetypes buffer
        ld      hl,filetypes
        ld      bc,4*MAX_FILETYPES+1
        ldir                            ; copy filetypes buffer into main RAM
        push    de                      ; save address of help
        ld      hl,helptext
        ld      bc,MAX_HELP_SIZE+1
        ldir                            ; copy help text into main RAM
        ld      (de),a                  ; terminate with $ff

        ; Save TSTACK memory and reset OLDSP to the top. This is necessary
        ; because M_P3DOS switches the stack to OLDSP when making a call
        ; in the ROM2/5/2/7 configuration. However, if a REMOUNT is performed
        ; within the Browser dialog, the stack usage exceeds the available
        ; space and some system variables (notably COORDSX..PAPER2) are
        ; overwritten.
        ld      hl,(OLDSP)
        ld      (saved_oldsp),hl
        ld      hl,TSTACK
        ld      (OLDSP),hl
        ld      de,saved_tstack
        ld      bc,TSTACK+1-TMPVARS
        lddr

        ; Show the dialog
        pop     de                      ; DE=help text
        pop     hl                      ; HL=filetypes buffer
        ld      a,(browser_caps)        ; A=capabilities
        exx
        ld      c,7                     ; RAM 7
        ld      de,IDE_BROWSER
        callesx m_p3dos                 ; run the Browser
        push    hl
        ld      hl,(window_curchl)      ; make window the current channel again
        ld      (CURCHL),hl             ; as IDE_BROWSER may have changed it
        pop     hl
        jr      nc,browse_error         ; if error, assume an empty string
        ex      de,hl                   ; HL=LFN, DE=short name
        jr      z,browse_gotselected    ; on if a file was selected
browse_error:
        ld      hl,ram_buffer           ; if not, use empty string for LFN
        ld      (hl),$ff
        ld      d,h                     ; also use empty string for short name
        ld      e,l
browse_gotselected:
        ld      a,(save_dialog)         ; is this a save dialog?
        and     a
        jr      z,browse_gotfile

        ; Ask the user to edit/enter a filename
        ld      de,saved_filename
        call    copy_RAM7_to_de         ; copy filename from RAM 7 to DivMMC RAM
        ld      (saved_namelen),bc      ; and save its length
        ld      hl,ram_buffer
        push    hl
        ld      (hl),24                 ; "set attributes" code
        inc     hl
        ld      a,($5aff)               ; use current bottom-right attribute
        ld      (hl),a
        inc     hl
        ld      (hl),14                 ; "clear window" code
        pop     hl
        ld      e,3                     ; string length 3
        exx
        ld      c,7                     ; RAM 7
        ld      de,IDE_WINDOW_STRING
        callesx m_p3dos                 ; clear the window to current colours
        ld      hl,edittext
        ld      de,ram_buffer
        call    copy_RAM7_to_de         ; copy edit prompt string to main RAM
        push    bc                      ; save string length
        ld      hl,ram_buffer
        ld      e,$ff                   ; string is $ff-terminated
        exx
        ld      c,7                     ; RAM 7
        ld      de,IDE_WINDOW_STRING
        callesx m_p3dos                 ; output the edit prompt
        ld      hl,saved_filename
        ld      de,ram_buffer
        ld      bc,(saved_namelen)
        push    bc
        inc     bc
        ldir                            ; copy filename (inc $ff) to ram_buffer
        pop     bc                      ; BC=length of filename
        pop     de                      ; DE=length of edit prompt
        ld      hl,51*2-1               ; maximum space in window (exc cursor)
        and     a
        sbc     hl,de                   ; HL=maximum length of editable string
        push    hl
        sbc     hl,bc                   ; HL=max length - LFN length
        pop     hl
        jr      nc,edit_lengthok
        ld      c,l                     ; C=truncated LFN length
edit_lengthok:
        ld      a,l                     ; A=max length of string
        ld      e,c                     ; E=current length of string
        ld      hl,ram_buffer
        exx
        ld      c,7
        ld      de,IDE_WINDOW_LINEIN
        callesx m_p3dos                 ; ask the user to edit the string
        ld      hl,ram_buffer
        push    hl
        ld      d,0                     ; DE=length of returned string
        add     hl,de
        ld      (hl),$ff                ; terminate it
        pop     hl
        jr      browse_gotfile_hl

        ; Switch to the short name if required
browse_gotfile:
        ld      a,(return_short)
        and     a
        jr      z,browse_gotfile_hl     ; if want LFN, already in HL
        ex      de,hl                   ; else switch short name to HL
browse_gotfile_hl:
        ld      de,saved_filename
        call    copy_RAM7_to_de         ; copy filename from RAM 7 to DivMMC RAM
        ld      (saved_namelen),bc      ; and save its length

        ; Restore the saved TSTACK.
        ld      hl,(saved_oldsp)
        ld      (OLDSP),hl
        ld      hl,saved_tstack
        ld      de,TSTACK
        ld      bc,TSTACK+1-TMPVARS
        lddr

        ; Restore the main RAM that we saved
        ld      sp,temp_stack           ; move SP to temp area in DivMMC RAM
        ld      hl,saved_ram
        ld      de,ram_buffer
        ld      bc,RAM_BUFFER_SIZE
        ldir                            ; restore the RAM we used
        ld      sp,(saved_sp)           ; restore SP to that set by BASIC

        ; Close the text window and restore the original stream 15
        ld      a,15
        ld      c,0                     ; IDE_STREAM_CLOSE needs main RAM
        ld      de,IDE_STREAM_CLOSE
        callesx m_p3dos                 ; close the text window
        ld      hl,(saved_strm15)
        ld      (STRMS+36),hl           ; restore stream 15 pointer
        ld      hl,(saved_curchl)
        ld      (CURCHL),hl             ; restore current channel pointer

        ; Start an assignment to the desired string.
        ld      hl,(CH_ADD)
        push    hl
        ld      hl,(workspace_addr)
        ld      (CH_ADD),hl             ; temporarily move CH_ADD into workspace
        ld      a,(var_name)
        ld      (hl),a                  ; and store variable name there
        inc     hl
        ld      (hl),'$'
        inc     hl
        ld      (hl),'='
        call48k CLASS_01_r3             ; initiate the assignment
        pop     hl
        ld      (CH_ADD),hl             ; restore CH_ADD

        ; Copy the filename into the workspace area so that a 48K BASIC
        ; ROM call can be used to assign it to the string requested.
        ld      hl,saved_filename
        ld      de,(workspace_addr)
        inc     de                      ; move past X$=, still needed by LET
        inc     de
        inc     de
        ld      bc,(saved_namelen)
        push    de
        push    bc
        inc     bc                      ; ensure not zero (will include the $ff)
        ldir                            ; copy into workspace
        pop     bc
        pop     de
        call48k STK_STO_S_r3            ; store string params on calc stack
        call48k LET_r3                  ; perform the assignment

        ; Restore character size and attributes for layer 1 (changed by
        ; Browser) and then restore original layer/mode.
        ld      a,30
        print_char
        ld      a,(saved_l11size)
        print_char                      ; restore layer 1,1 char size
        ld      a,24
        print_char
        ld      a,(saved_l11attr)
        print_char                      ; restore layer 1,1 attributes
        ld      a,14
        print_char                      ; clear the layer 1,1 screen
        ld      bc,(saved_submode)
        call    set_mode                ; restore original mode
        ld      a,(saved_layer)
        and     a
        jr      z,cls_layer0            ; special case for clearing layer 0
        dec     a
        jr      nz,end_cls              ; no need to clear if layer 2
        ld      a,(saved_submode)
        cp      1
        jr      z,end_cls               ; no need to clear layer 1,1 again
        ld      a,14
        print_char                      ; otherwise clear a layer 1 screen
        jr      end_cls
cls_layer0:
        call48k CLS_r3
end_cls:
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
; * Query or set the mode                                                   *
; ***************************************************************************
; Entry: If entering at set_mode: B=layer, C=mode
; Exit:  standard results from IDE_MODE call

get_mode:
        xor     a
        jr      do_getsetmode
set_mode:
        ld      a,1
do_getsetmode:
        exx
        ld      c,7
        ld      de,IDE_MODE
        callesx m_p3dos
        ret


; ***************************************************************************
; * Copy $ff-terminated string with RAM 7 paged at top of memory            *
; ***************************************************************************
; Entry: HL=source
;        DE=dest
; Exit:  BC=string length

copy_RAM7_to_de:
        push    hl                      ; save source address
        ld      bc,next_reg_select
        ld      a,nxr_mmu6
        out     (c),a
        inc     b
        in      l,(c)                   ; L=current MMU6 binding
        ld      a,7*2+0
        out     (c),a                   ; rebind to RAM 7 low
        dec     b
        ld      a,nxr_mmu7
        out     (c),a
        inc     b
        in      h,(c)                   ; H=current MMU7 binding
        ld      a,7*2+1
        out     (c),a                   ; rebind to RAM 7 high
        ex      (sp),hl                 ; save MMU6/7 bindings, refetch source
        ld      bc,$ffff                ; string len, -1 to exclude terminator
cr7tomain_loop:
        ld      a,(hl)                  ; copy a byte
        inc     hl
        ld      (de),a
        inc     de
        inc     bc                      ; increment string length
        inc     a
        jr      nz,cr7tomain_loop       ; back unless $ff-terminator copied
        pop     hl
        ld      a,l
        nxtrega nxr_mmu6                ; restore MMU6 binding
        ld      a,h
        nxtrega nxr_mmu7                ; restore MMU7 binding
        ret


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
opt0:   defm    "-t"
opt0_a: defw    option_type

        defb    opt1_a-opt1
opt1:   defm    "--type"
opt1_a: defw    option_type

        defb    opt2_a-opt2
opt2:   defm    "-p"
opt2_a: defw    option_prompt

        defb    opt3_a-opt3
opt3:   defm    "--prompt"
opt3_a: defw    option_prompt

        defb    opt4_a-opt4
opt4:   defm    "-e"
opt4_a: defw    option_edit

        defb    opt5_a-opt5
opt5:   defm    "--edit"
opt5_a: defw    option_edit

        defb    opt6_a-opt6
opt6:   defm    "-8"
opt6_a: defw    option_short

        defb    opt7_a-opt7
opt7:   defm    "--8.3"
opt7_a: defw    option_short

        defb    opt8_a-opt8
opt8:   defm    "-s"
opt8_a: defw    option_save

        defb    opt9_a-opt9
opt9:   defm    "--save"
opt9_a: defw    option_save

        defb    opt10_a-opt10
opt10:  defm    "-h"
opt10_a:defw    show_usage

        defb    opt11_a-opt11
opt11:  defm    "--help"
opt11_a:defw    show_usage

        defb    opt12_a-opt12
opt12:  defm    "-r"
opt12_a:defw    option_rename

        defb    opt13_a-opt13
opt13:  defm    "--rename"
opt13_a:defw    option_rename

        defb    opt14_a-opt14
opt14:  defm    "-d"
opt14_a:defw    option_erase

        defb    opt15_a-opt15
opt15:  defm    "--delete"
opt15_a:defw    option_erase

        defb    opt16_a-opt16
opt16:  defm    "-k"
opt16_a:defw    option_mkdir

        defb    opt17_a-opt17
opt17:  defm    "--mkdir"
opt17_a:defw    option_mkdir

        defb    opt18_a-opt18
opt18:  defm    "-m"
opt18_a:defw    option_remount

        defb    opt19_a-opt19
opt19:  defm    "--remount"
opt19_a:defw    option_remount

        defb    opt20_a-opt20
opt20:  defm    "-u"
opt20_a:defw    option_unmount

        defb    opt21_a-opt21
opt21:  defm    "--unmount"
opt21_a:defw    option_unmount

        defb    opt22_a-opt22
opt22:  defm    "-c"
opt22_a:defw    option_copy

        defb    opt23_a-opt23
opt23:  defm    "--copy"
opt23_a:defw    option_copy

        ; End of table
        defb    0


; ***************************************************************************
; * -t, --type  EXT                                                         *
; ***************************************************************************

option_type:
        call    get_sizedarg            ; get extension into temparg
        ld      a,c
        and     a                       ; must be 1+ chars (leaves Fc=0)
        jr      z,badext
        cp      4                       ; must be <= 3 chars
badext:
        ld      hl,msg_badtype
        jp      nc,err_custom
        ld      a,(numtypes)
        inc     a
        cp      MAX_FILETYPES+1         ; check haven't exceeded max types
        ld      hl,msg_toomanytypes
        jp      nc,err_custom
        ld      (numtypes),a
        ld      hl,(filetypeptr)
        ld      b,c                     ; B=type length
        inc     c
        ld      (hl),c                  ; store type length+1
        inc     hl
        ld      de,temparg
copy_type_loop:
        ld      a,(de)                  ; get next type char
        inc     de
        cp      'a'
        jr      c,copy_type_notlower
        cp      'z'+1
        jr      nc,copy_type_notlower
        and     $df                     ; convert letters to uppercase
copy_type_notlower:
        ld      (hl),a                  ; store next type char
        inc     hl
        djnz    copy_type_loop
        ld      (hl),':'                ; terminate type
        inc     hl
        ld      (filetypeptr),hl        ; update pointer
        ret


; ***************************************************************************
; * -p, --prompt PROMPT                                                     *
; * -e, --edit   PROMPT                                                     *
; ***************************************************************************
; Supports \i for inverse, \o for normal

option_edit:
        ld      de,edittext
        ld      l,51+1                   ; restrict edit prompt to 1 line
        jr      option_prompt_or_edit
option_prompt:
        ld      de,helptext
        ld      l,MAX_HELP_SIZE+1
option_prompt_or_edit:
        push    hl
        push    de
        call    get_sizedarg            ; get prompt into temparg
        pop     de                      ; DE=destination buffer
        pop     hl
        ld      a,c
        cp      l
        ld      hl,msg_badprompt
        jp      nc,err_custom
        ld      hl,temparg
option_prompt_copy:
        ld      a,(hl)                  ; get next source char
        inc     hl
        cp      '\'                     ; check for possible ESC sequence
        jr      z,option_escape_char
option_prompt_store:
        ld      (de),a                  ; store char
        inc     de
        dec     c
        jr      nz,option_prompt_copy
        ld      a,$ff
        ld      (de),a                  ; append terminator
        ret
option_escape_char:
        dec     c                       ; reduce count for escape char
        jr      z,option_escape_ignore  ; can't be ESC sequence if last char
        ld      a,(hl)
        ld      b,1                     ; INVERSE 1 for 'i'
        cp      'i'
        jr      z,option_escape_io
        dec     b                       ; INVERSE 0 for 'o'
        cp      'o'
        jr      z,option_escape_io
option_escape_ignore:
        inc     c                       ; undo dec above
        ld      a,'\'
        jr      option_prompt_store     ; insert \ for unknow ESC sequences
option_escape_io:
        inc     hl                      ; consume 'i'/'o'
        ld      a,20                    ; INVERSE
        ld      (de),a
        inc     de
        ld      a,b                     ; 1 or 0
        jr      option_prompt_store


; ***************************************************************************
; * -8, --8.3                                                               *
; ***************************************************************************

option_short:
        ld      a,1
        ld      (return_short),a
        ret


; ***************************************************************************
; * -s, --save                                                              *
; ***************************************************************************

option_save:
        ld      a,1
        ld      (save_dialog),a
        ret


; ***************************************************************************
; * -r, --rename                                                            *
; * -d, --delete                                                            *
; * -k, --mkdir                                                             *
; * -m, --remount                                                             *
; * -u, --unmount                                                           *
; * -c, --copy                                                              *
; ***************************************************************************

option_rename:
        ld      e,BROWSERCAPS_RENAME
        jr      option_enablecaps

option_erase:
        ld      e,BROWSERCAPS_ERASE
        jr      option_enablecaps

option_mkdir:
        ld      e,BROWSERCAPS_MKDIR
        jr      option_enablecaps

option_remount:
        ld      e,BROWSERCAPS_REMOUNT
        jr      option_enablecaps

option_unmount:
        ld      e,BROWSERCAPS_UNMOUNT
        jr      option_enablecaps

option_copy:
        ld      e,BROWSERCAPS_COPY
option_enablecaps:
        ld      a,(browser_caps)
        or      e
        ld      (browser_caps),a
        ret


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

; TAB 32 used within help message so it is formatted wide in 64/85 column mode.
msg_help:
        defm    "BROWSE v1.0 by Garry Lancaster",$0d
        defm    "Uses Browser to select filename",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .BROWSE [OPTION]... VARIABLE$",$0d
        defm    "OPTIONS:",$0d
        defm    " -h, --help",23,32,0
        defm    "     Display this help",$0d
        defm    " -t, --type EXT",23,32,0
        defm    "     Add EXT to selectable types",23,32,0
        defm    "     Wildcards * or ? allowed",23,32,0
        defm    "     Multiple -t options allowed",$0d
        defm    " -p, --prompt PROMPT",23,32,0
        defm    "     Custom help prompt",23,32,0
        defm    "     Can include: ",'\',"i inverse on",23,32,0
        defm    "                  ",'\',"o inverse off",$0d
        defm    " -s, --save",23,32,0
        defm    "     Ask for new filename",$0d
        defm    " -e, --edit PROMPT",23,32,0
        defm    "     Custom prompt for edit/save",$0d
        defm    " -8, --8.3",23,32,0
        defm    "     Return short name (not LFN)",$0d
        defm    " -r, --rename",23,32,0
        defm    "     Allow rename with R key",$0d
        defm    " -d, --delete",23,32,0
        defm    "     Allow erase with E key",$0d
        defm    " -k, --mkdir",23,32,0
        defm    "     Allow mkdir with K key",$0d
        defm    " -m, --remount",23,32,0
        defm    "     Allow remount with M key",$0d
        defm    " -u, --unmount",23,32,0
        defm    "     Allow unmount with U key",$0d
        defm    " -c, --copy",23,32,0
        defm    "     Allow copy/paste with C/P",$0d
        defm    $ff

msg_badnextzxos:
        defm    "Requires NextZXOS mod",'e'+$80

msg_unknownoption:
        defm    "Unknown option: "
temparg:
        defs    256

msg_badtype:
        defm    "Type must be 1-3 char",'s'+$80

msg_toomanytypes:
        defm    "Too many type",'s'+$80

msg_badprompt:
        defm    "Prompt string too lon",'g'+$80

msg_badstring:
        defm    "Variable must be A$..Z",'$'+$80

numtypes:
        defb    0

filetypeptr:
        defw    filetypes

filetypes:
        defs    4*MAX_FILETYPES+1,$ff

helptext:
        ; Max 2 lines of 51-char text
                ;123456789012345678901234567890123456789012345678901
        defm    "Navigate with cursor keys, ENTER, EDIT and D       "
        defm    "Press ENTER on file to select, SPACE for none      "
        ; Allow extra 64 chars so 32 control characters are possible
        defs    64,$ff
        ; And final terminating char
        defb    $ff
helptext_end:

if ((helptext_end-helptext) != (MAX_HELP_SIZE+1))
.ERROR helptext is not correct length
endif

edittext:
        ; Max 1 line of 51-char text
                ;123456789012345678901234567890123456789012345678901
        defm    "Save as: ",$ff
        defs    41,$ff
        ; And final terminating char
        defb    $ff
edittext_end:

if ((edittext_end-edittext) != (51+1))
.ERROR edittext is not correct length
endif


; ***************************************************************************
; * Text window definition                                                  *
; ***************************************************************************
; A 2-line window at the bottom of the screen, char size 5.

windef:
        defm    "w>22,0,2,32,5"
windef_end:

if ((windef_end-windef) > MAX_LFN_SIZE)
.ERROR Window definition doesn't fit in reserved workspace
endif


; ***************************************************************************
; * Data                                                                    *
; ***************************************************************************

saved_sp:
        defw    0

saved_strm15:
        defw    0

saved_curchl:
        defw    0

window_curchl:
        defw    0

workspace_addr:
        defw    0

saved_filename:
        defs    MAX_LFN_SIZE

saved_namelen:
        defw    0

saved_turbo:
        defb    0

saved_l11size:
        defb    0

saved_l11attr:
        defb    0

saved_submode:
        defb    0

saved_layer:
        defb    0

; LD BC,(saved_submode) above assumes this ordering.
if (saved_layer != (saved_submode+1))
.ERROR Incorrect assumption: saved_layer=saved_submode+1
endif

return_short:
        defb    0

save_dialog:
        defb    0

browser_caps:
        defb    0

var_name:
        defb    0

command_tail:
        defw    0

        defs    256                     ; space for temporary stack
temp_stack:

saved_oldsp:
        defw    0

        defs    255                     ; space for saved TSTACK
saved_tstack:
        defs    1                       ; first byte of saved TSTACK

saved_ram:
; NOTE: Do not place anything after here
;       defs    ram_buffer_size

if ((saved_ram+ram_buffer_size) > $4000)
.ERROR saved_ram buffer exceeds DivMMC RAM area
endif
