; ***************************************************************************
; * Dot command for reading/writing to the metadata cache                   *
; * .metadata r filename key                                                *
; * .metadata w filename key data [loc]                                     *
; ***************************************************************************

include "nexthw.def"
include "macros.def"

macro callesx,hook
        rst     $8
        defb    hook
endm

macro callp3d,callid
        exx
        ld      de,callid
        ld      c,7
        callesx m_p3dos
endm

macro rom_print
        rst     $10
endm


; ***************************************************************************
; * API and other definitions required                                      *
; ***************************************************************************

; esxDOS calls
m_p3dos                 equ     $94             ; call +3DOS API
f_close                 equ     $9b             ; close file/dir
f_opendir               equ     $a3             ; open dir
f_readdir               equ     $a4             ; read dir

; esxDOS constants
esx_mode_use_wildcards  equ     $20
esx_mode_short_only     equ     $00
esx_mode_lfn_only       equ     $10
esx_mode_lfn_and_short  equ     $18

; esxDOS error codes
esx_enoent              equ     5               ; no such file/dir

; +3DOS API calls
DOS_OPEN                equ     $0106           ; open file
DOS_CLOSE               equ     $0109           ; close file
DOS_READ                equ     $0112           ; read file
DOS_WRITE               equ     $0115           ; write file
DOS_RENAME              equ     $0127           ; rename file
DOS_SET_POSITION        equ     $0136           ; set file position
IDE_BANK                equ     $01bd           ; bank allocation

; +3DOS error codes
rc_nofile               equ     $17             ; file not found
rc_notdir               equ     $45             ; invalid path


; ***************************************************************************
; * Constants                                                               *
; ***************************************************************************

MAX_METADATA            equ     8192            ; allow entire 8K bank of data


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************
; Dot commands always start at $2000, with HL=address of command tail
; (terminated by $00, $0d or ':').

        org     $2000

        ld      a,h
        or      l
        jr      z,show_usage            ; no tail provided if HL=0
        ld      de,keydata
        call    get_sizedarg            ; get R or W temporarily to keydata
        jr      nc,show_usage
        push    hl
        ld      hl,(keydata)
        res     5,l                     ; HL=capitalised letter (R or W)
        ld      de,'R'
        xor     a                       ; A=0 for read
        sbc     hl,de
        jr      z,got_rwmode
        ld      de,'W'-'R'
        ld      a,1                     ; A=1 for write
        and     a
        sbc     hl,de
got_rwmode:
        jr      nz,show_usage           ; must be read or write
        ld      (rwmode),a
        pop     hl
        ld      de,filename
        call    get_sizedarg            ; get next argument to filename
        jr      nc,show_usage           ; if none, just go to show usage
        ld      de,keyname
        call    get_sizedarg            ; get next argument to keyname
        jr      nc,show_usage           ; if none, just go to show usage
        ld      a,(rwmode)
        and     a
        jr      z,got_allargs           ; no further arguments if read mode
        ld      de,keydata
        call    get_sizedarg            ; get next argument to keydata
        jr      nc,show_usage           ; if none, just go to show usage
        ld      de,location
        push    de
        call    get_sizedarg            ; get optional argument to location
        pop     hl
        jr      nc,metadata_start
        ld      a,(hl)
        sub     '0'
        jr      c,show_usage
        cp      2
        jr      nc,show_usage
        ld      (hl),a                  ; set location to 0 or 1
        inc     hl
        ld      a,(hl)
        and     a
        jr      nz,show_usage           ; must not be more than 1 char
        jr      metadata_start

got_allargs:
        ld      de,0                    ; further args to ROM
        call    get_sizedarg            ; check if any further args
        jr      nc,metadata_start       ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        ret


; ***************************************************************************
; * Allocate workspace memory in main RAM                                   *
; ***************************************************************************

metadata_start:
        ld      hl,$0001                ; allocate a ZX bank
        callp3d IDE_BANK
        jp      nc,out_of_memory        ; on if error
        ld      a,e
        ld      (workspace_bank),a      ; save bank id
        ld      hl,0
        add     hl,sp
        ld      a,h
        cp      $c0
        ld      d,nxr_mmu7              ; use MMU7 for workspace if SP<$c000
        ld      hl,$e000
        jr      c,use_mmu
        ld      d,nxr_mmu4              ; use MMU4 if SP>=$c000
        ld      hl,$8000
use_mmu:
        ld      bc,next_reg_select
        out     (c),d
        inc     b
        in      a,(c)
        out     (c),e                   ; page in allocated bank for workspace
        ld      e,a                     ; E=previously-paged bank
        ld      (workspace_mmubank),de  ; save previous bank & MMU id
        ld      (workspace_addr),hl
        ; drop through to obtain_lfn

; ***************************************************************************
; * Obtain the canonical LFN                                                *
; ***************************************************************************

obtain_lfn:
        ld      hl,filename
        push    hl
olfn_loop
        ld      a,(hl)
        inc     hl
        cp      '/'
        jr      z,olfn_gotseg
        cp      '\'
        jr      z,olfn_gotseg
        cp      ':'
        jr      nz,olfn_notseg
olfn_gotseg:
        pop     de
        push    hl                      ; replace final segment start
olfn_notseg:
        and     a
        jr      nz,olfn_loop            ; until null-terminator
        pop     hl
        ld      de,(workspace_addr)
        push    de
        push    hl
        call    copy_nulltermdata       ; copy filename part to workspace
        pop     hl
        ld      (hl),0                  ; terminate the path part
        ld      a,'*'
        ld      hl,filename             ; A,HL=path part
        pop     de                      ; DE=filename part, used as wildcard
        push    de
        ld      b,esx_mode_lfn_only+esx_mode_use_wildcards
        callesx f_opendir
        pop     de                      ; DE=filename part, used as wildcard
        jr      c,olfn_badlfn
        push    af                      ; save handle
        ld      hl,attr_original
        callesx f_readdir               ; get the directory data
        pop     bc
        push    af
        ld      a,b
        callesx f_close
        pop     af
        jp      c,exit_error
        cp      1
olfn_badlfn:
        ld      a,esx_enoent            ; no such file/dir if no entry returned
        jp      c,exit_error
        ; drop through to open_file

; ***************************************************************************
; * Open the metadata file                                                  *
; ***************************************************************************

open_file:
        call    check_fname_meta        ; check if filename contains metadata
        ld      de,(workspace_addr)
        call    generate_filespec       ; generate canonical filespec
        ld      b,0                     ; start with file zero
        ld      a,(rwmode)              ; A=0 for read, 1 for write
        scf
        adc     a,a                     ; A=1 for read, 3 for read/write
        or      %1100                   ; set bit 2 (shared), 3 (metadata fork)
        ld      c,a                     ; C=access mode
open_file_retry:
        push    bc
        ld      hl,(workspace_addr)     ; HL=$ff-terminated filename
        callp3d DOS_OPEN                ; attempt to open metadata fork
        pop     bc
        jr      c,file_opened
        cp      rc_nofile               ; okay if not found (reading a file
        jr      z,got_metadata          ; which has no metadata)
        cp      rc_notdir
        jr      z,got_metadata          ; or invalid path
        inc     b                       ; next file number
        ld      a,b
        cp      16
        jr      c,open_file_retry
        ld      hl,msg_nodata
        jp      err_custom


; ***************************************************************************
; * Read the metadata file                                                  *
; ***************************************************************************

file_opened:
        ld      a,b
        ld      (filenum),a             ; store file number
        ld      hl,(workspace_addr)
        ld      de,MAX_METADATA
        push    de
        ld      c,7
        callp3d DOS_READ
        pop     hl
        jr      c,file_allread
        sbc     hl,de                   ; HL=bytes read
file_allread:
        ld      (metasize),hl           ; store total data size
        ; drop through to got_metadata

; ***************************************************************************
; * Read/write the requested key in the metadata                            *
; ***************************************************************************

got_metadata:
        ld      a,(rwmode)
        and     a
        jr      nz,write_key            ; on to write a key
        ; drop through to read_key

; ***************************************************************************
; * Read key                                                                *
; ***************************************************************************

read_key:
        nxtregn nxr_user0,$ff           ; key not found
        ld      hl,(lfnmeta_start)
        ld      a,h
        or      l
        jr      z,read_key_cache        ; on if no metadata in LFN
        inc     hl                      ; skip '{'
        call    check_key_nobc
        jr      nc,read_key_cache       ; on if LFN metadata doesn't match
        ld      hl,(lfnmeta_end)
        dec     hl
        dec     hl
        dec     hl
        ld      (hl),$0d                ; replace first hex digit with $0d
        ld      a,1                     ; found in filename
        jr      print_key_a

read_key_cache:
        ld      hl,(workspace_addr)
        ld      bc,(metasize)
check_line:
        call    find_line               ; HL=address of next line
        jp      nc,exit_error           ; no more lines, exit with Fc=0 (ok)
        call    check_key
        jr      c,print_key_0           ; on if key matched
        call    skip_line               ; else skip to next line
        jr      check_line

print_key_0:
        xor     a                       ; found in cache
print_key_a:
        nxtrega nxr_user0               ; set user nextreg (127) to location
print_key:
        ld      a,b
        or      c
        jp      z,exit_error            ; done (Fc=0, success) if metadata end
        ld      a,(de)
        inc     de
        dec     bc
        cp      $0d
        jp      z,exit_error            ; or end of line
        cp      $0a
        jp      z,exit_error
        call    print_char
        jr      print_key


; ***************************************************************************
; * Write key                                                               *
; ***************************************************************************

write_key:
        ld      hl,(workspace_addr)
        ld      bc,(metasize)
        ld      a,b
        and     $e0
        ld      (fullflag),a            ; if size<8192, fullflag=0
shuffle_loop:
        ld      d,h
        ld      e,l                     ; DE=current address
        call    find_line               ; HL=start of next line
        call    trim_data               ; trim out surplus CR/LFs
        jr      nc,shuffle_end
        call    check_key
        jr      nc,retain_line
        ld      d,h
        ld      e,l                     ; DE=start of current key line
        call    skip_line
        call    c,find_line             ; HL=address of following line
        call    trim_data
        jr      shuffle_loop
retain_line:
        call    skip_line
        jr      c,retain_onecr
        ld      a,(fullflag)
        and     a
        jr      nz,shuffle_end          ; on if no space to append a CR
retain_onecr:
        ld      (hl),$0d                ; use CR line-endings
        inc     hl
        dec     bc
        jr      shuffle_loop

shuffle_end:
        push    hl                      ; save address to append key
        ld      de,(workspace_addr)
        and     a
        sbc     hl,de
        ld      b,h
        ld      c,l                     ; BC=current metadata size
        pop     de                      ; DE=address to append key
        ld      hl,keyname
        call    append_metadata         ; append the keyname
        ld      hl,msg_equals
        call    append_metadata         ; append '='
        ld      hl,keydata
        call    append_metadata         ; append the key data
        ld      hl,msg_cr
        call    append_metadata         ; append CR
        ld      hl,(metasize)
        and     a
        sbc     hl,bc
        jr      c,write_meta_file       ; no need to pad if size has increased
        jr      z,write_meta_file       ; or stayed the same
        ex      de,hl
pad_file_loop:
        ld      (hl),$0d                ; pad with CR
        inc     hl
        inc     bc
        dec     de
        ld      a,d
        or      e
        jr      nz,pad_file_loop

write_meta_file:
        push    bc                      ; save final metadata size
        ld      a,(filenum)
        ld      b,a
        ld      hl,0
        ld      e,l
        callp3d DOS_SET_POSITION        ; reset filepointer
        jr      nc,err_filewrite
        pop     de                      ; DE=total metadata size
        ld      hl,(workspace_addr)
        ld      a,(filenum)
        ld      b,a
        callp3d DOS_WRITE               ; write the file data
        jr      c,write_filename        ; on if successful
err_filewrite:
        ld      hl,msg_writefail
        jp      err_custom

write_filename:
        call    close_file              ; must close metadata file before rename
        ld      hl,(lfnmeta_start)
        ld      a,(location)            ; on if writing to filename
        and     a
        jr      nz,write_filename_do
        or      h                       ; if no filename metadata currently
        jp      z,exit_error            ; present, exit with success
        inc     hl                      ; skip '{' in existing filename metadata
        call    check_key_nobc
        jp      nc,exit_error           ; don't remove if not key being updated
write_filename_do:
        ld      de,(workspace_addr)
        push    de
        call    generate_filespec       ; generate current filespec
        inc     de
        push    de
        ld      hl,(lfnmeta_end)
        ld      de,lfn_extension
        call    copy_nulltermdata       ; copy any extension out of the way
        ld      de,(lfnmeta_start)
        ld      a,d
        or      e
        jr      nz,write_filename_meta  ; overwrite any old metadata
        ld      de,(lfnmeta_end)        ; otherwise overwrite from extension
write_filename_meta:
        ld      a,(location)
        and     a
        jr      z,write_filename_none   ; on if no metadata wanted in filename
        ld      bc,3                    ; metadata tail size ( 2 hex digits+} )
        ld      hl,msg_meta_start
        call    append_metadata         ; append '{'
        ld      hl,keyname
        call    append_metadata         ; append the keyname
        ld      hl,msg_equals
        call    append_metadata         ; append '='
        ld      hl,keydata
        call    append_metadata         ; append the key data
        ld      hl,msg_meta_tail
        push    hl
        ld      a,c
        swapnib()
        call    nibble_to_ascii
        ld      (hl),a                  ; store high hex digit
        inc     hl
        ld      a,c
        call    nibble_to_ascii
        ld      (hl),a                  ; store low hex digit
        pop     hl
        call    append_metadata         ; append the hex digits and '}'
write_filename_none:
        ld      hl,lfn_extension
        call    copy_nulltermdata       ; re-append the extension and null
        pop     de
        push    de
        call    generate_filespec       ; generate new filespec
        pop     de
        pop     hl
        callp3d DOS_RENAME              ; rename the file
        ld      hl,msg_namefail
        jp      nc,err_custom
        and     a
        jp      exit_error              ; finish successfully


; ***************************************************************************
; * Generate canonical filespec ($ff-terminated)                            *
; ***************************************************************************
; Entry:        DE=destination
; Exit:         DE=address of $ff-terminator

generate_filespec:
        ld      hl,filename
        call    copy_nulltermdata       ; copy path
        ld      hl,lfn_original
        call    copy_nulltermdata       ; append canonical filename
        ld      a,$ff
        ld      (de),a                  ; convert to $ff-terminated
        ret


; ***************************************************************************
; * Copy null-terminated data                                               *
; ***************************************************************************
; Entry:        HL=null-terminated data
;               DE=destination
; Exit:         DE=address of null in copied data

copy_nulltermdata:
        ld      a,(hl)
        ld      (de),a
        inc     hl
        inc     de
        and     a
        jr      nz,copy_nulltermdata
        dec     de
        ret


; ***************************************************************************
; * Find start of next metadata line                                        *
; ***************************************************************************
; Entry:        HL=address
;               BC=remaining size
; Exit:         Fc=1, HL=address of non-CR/LF, BC=remaining size
;               Fc=0, no more lines, HL=final address, BC=0

find_line:
        ld      a,b
        or      c
        ret     z                       ; done (Fc=0) if no more data
        ld      a,(hl)
        cp      $0d
        jr      z,find_line_inc
        cp      $0a
        scf
        ret     nz                      ; done (Fc=1) if non-CRLF
find_line_inc:
        inc     hl
        dec     bc
        jr      find_line


; ***************************************************************************
; * Skip to end of current line                                             *
; ***************************************************************************
; Entry:        HL=address
;               BC=remaining size
; Exit:         Fc=1, HL=address of CR/LF, BC=remaining size
;               Fc=0, no more lines, HL=final address, BC=0

skip_line_loop:
        inc     hl
        dec     bc
skip_line:
        ld      a,b
        or      c
        ret     z                       ; done (Fc=0) if no more data
        ld      a,(hl)
        cp      $0d
        jr      z,skip_line_end
        cp      $0a
        jr      nz,skip_line_loop
skip_line_end:
        scf
        ret                             ; done (Fc=1) if CR or LF


; ***************************************************************************
; * Check key                                                               *
; ***************************************************************************
; Entry:        HL=line address
;               BC=data length (or enter at check_key_nobc)
; Exit:         Fc=1, key match; DE=address of key data
;               Fc=0, no match
; BC,HL preserved

check_key_nobc:
        ld      b,$ff
check_key:
        push    bc
        push    hl
        ld      de,keyname
        jr      check_key_start
check_key_loop:
        inc     de
        inc     hl
        dec     bc
check_key_start:
        ld      a,b
        or      c
        jr      z,key_mismatch
        ld      a,(de)
        and     a
        jr      z,key_match
        cp      (hl)
        jr      z,check_key_loop
        cp      'A'
        jr      c,key_mismatch
        cp      'Z'+1
        jr      c,check_key_letter
        cp      'a'
        jr      c,key_mismatch
        cp      'z'+1
        jr      nc,key_mismatch
check_key_letter:
        xor     $20
        cp      (hl)
        jr      z,check_key_loop
key_mismatch:
        pop     hl
        pop     bc
        and     a                       ; Fc=0, no match
        ret

key_match:
        ld      a,b
        or      c
        jr      z,key_mismatch
        ld      a,(hl)
        inc     hl
        dec     bc
        cp      '='                     ; '=' must follow key
        jr      nz,key_mismatch
        ex      de,hl                   ; DE=key data
        pop     hl
        pop     bc
        scf                             ; success
        ret


; ***************************************************************************
; * Trim data                                                               *
; ***************************************************************************
; Entry:        DE=start of data
;               HL=start of data to retain (HL>=DE)
;               BC=length of data at HL
; Exit:         HL=start of trimmed data (entry DE)
;               Fc=1
; AFBC preserved

trim_data:
        push    af
        push    de                      ; save data start
        ld      a,b
        or      c
        jr      z,trim_none
        push    hl
        sbc     hl,de                   ; HL=size of data being trimmed
        pop     hl
        jr      z,trim_none
        push    bc
        ldir                            ; shuffle data up
        pop     bc
        xor     a
        ld      (fullflag),a            ; allow CR to be appended at data end
trim_none:
        pop     hl                      ; HL=start of trimmed data
        pop     af
        ret


; ***************************************************************************
; * Append metadata                                                         *
; ***************************************************************************
; Entry:        HL=address of null-terminated string to append
;               DE=destination
;               BC=available size
; Exit:         Fc=1, okay
;               Fc=0, no room

append_metadata:
        ld      a,b
        and     $e0
        ret     nz                      ; fail if no more room (8K)
        ld      a,(hl)
        inc     hl
        and     a
        scf
        ret     z                       ; okay if end of string
        ld      (de),a
        inc     de
        inc     bc
        jr      append_metadata


; ***************************************************************************
; * Check if the filename contains metadata                                 *
; ***************************************************************************

check_fname_meta:
        ld      hl,lfn_original
        xor     a
        ld      b,a
        ld      c,a
        cpir                            ; find null-terminator, BC=-length
        dec     hl
        ld      d,h
        ld      e,l                     ; DE=default end of name
        push    bc                      ; save original length
cfm_find_nameend:
        dec     hl
        ld      a,(hl)
        cp      '.'                     ; find final '.'
        jr      z,cfm_got_nameend
        inc     bc
        bit     7,b
        jr      nz,cfm_find_nameend
        ex      de,hl                   ; HL=end of name
        pop     bc                      ; restore original length
        push    bc
cfm_got_nameend:
        pop     de                      ; discard original length
        ld      (lfnmeta_end),hl        ; store end of name metadata
        dec     hl
        ld      a,(hl)
        cp      '}'                     ; possible metadata string?
        ret     nz                      ; exit if not
        call    ascii_to_nibble
        ld      e,a                     ; E=low nibble of metadata length
        call    ascii_to_nibble
        swapnib()
        or      e                       ; A=metadata length
        addbc_A_badFc()                 ; BC=-length before metadata
        bit     7,b                     ; must be negative
        ret     z                       ; exit if not
        ld      b,$ff
        neg
        add     a,3
        ld      c,a
        add     hl,bc                   ; HL=address of metadata start
        ld      a,(hl)
        cp      '{'
        ret     nz                      ; exit if not valid metadata string
        ld      (lfnmeta_start),hl      ; store start of name metadata
        ret


; ***************************************************************************
; * Read a hex digit from ASCII text                                        *
; ***************************************************************************
; Entry:        HL=address+1 of ASCII hex nibble
; Exit:         A=nibble value, 0..f
;               HL=HL-1

ascii_to_nibble:
        dec     hl
        ld      a,(hl)
        sub     '0'
        cp      10
        ret     c
        sub     7
        cp      16
        ret     c
        sub     'a'-'A'
        cp      16
        ret     c
        xor     a
        ret


; ***************************************************************************
; * Generate an ASCII nibble                                                *
; ***************************************************************************
; Entry:        A=value
; Exit:         A=ASCII representation for low nibble

nibble_to_ascii:
        and     $0f
        add     a,'0'
        cp      '9'+1
        ret     c
        add     a,7
        ret


; ***************************************************************************
; * Out of memory error                                                     *
; ***************************************************************************

out_of_memory:
        ld      hl,msg_allocerror
        jr      err_custom


; ***************************************************************************
; * Metadata file full error                                                *
; ***************************************************************************

err_metafull:
        ld      hl,msg_metafull
        ; drop through to err_custom

; ***************************************************************************
; * Custom error generation                                                 *
; ***************************************************************************

err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        ; drop through to exit_error

; ***************************************************************************
; * Close file, deallocate banks and exit with any error condition          *
; ***************************************************************************

exit_error:
        push    af                      ; save error status
        push    hl
        call    close_and_deallocate    ; close file, free workspace bank
        pop     hl                      ; restore error status
        pop     af
        ret


; ***************************************************************************
; * Close file and free workspace bank                                      *
; ***************************************************************************

close_and_deallocate:
        call    close_file
        ld      hl,(workspace_mmubank)  ; get previous bank & MMU id
        ld      a,h
        and     a
        ret     z                       ; nothing to do if MMU id not valid
        ld      bc,next_reg_select
        out     (c),h
        inc     b
        out     (c),l                   ; restore MMU binding
        ld      a,(workspace_bank)
        ld      e,a                     ; E=allocated workspace bank
        ld      hl,$0003                ; free ZX bank
        callp3d IDE_BANK
        ret


; ***************************************************************************
; * Close metadata file                                                     *
; ***************************************************************************

close_file:
        ld      a,(filenum)
        ld      b,a
        inc     a
        ret     z
        callp3d DOS_CLOSE               ; close the file
        ld      a,$ff
        ld      (filenum),a
        ret

; ***************************************************************************
; * Print a message                                                         *
; ***************************************************************************

printmsg:
        ld      a,(hl)
        inc     hl
        and     a
        ret     z                       ; exit if terminator
        call    print_char
        jr      printmsg


; ***************************************************************************
; * Print a character via the ROM                                           *
; ***************************************************************************
; Entry: A=character
;
; NB: Must ensure full BASIC workspace is in place since output could go to
;     any channel, including variables/memory etc

print_char:
        push    af
        ld      a,(workspace_mmuid)
        and     a
        jr      z,print_char_normal
        ld      (set_mmu+2),a           ; patch NXTREG instruction
        ld      a,(workspace_mmubank)
        call    set_mmu                 ; restore original MMU bank
        pop     af
        rom_print()                     ; print the character
        ld      a,(workspace_bank)
        ; drop through to switch bank workspace bank
set_mmu:
        nxtrega 0                       ; gets patched to MMU register ID
        ret

print_char_normal:
        pop     af
        rom_print()
        ret


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

lfnmeta_start:
        defw    0

lfnmeta_end:
        defw    0

lfn_extension:
        defs    261

; Data from F_READDIR:
attr_original:
        defb    0
lfn_original:
        defs    261
time_original:
        defw    0
data_original:
        defw    0
size_original:
        defw    0,0

; filename follows LFN to ensure appending metadata to LFN won't overwrite
; anything important.
filename:
        defs    256

keyname:
        defs    256

keydata:
        defs    256

location:
        defs    256

rwmode:
        defb    0

fullflag:
        defb    0

workspace_mmubank:
        defb    0
workspace_mmuid:
        defb    0

workspace_bank:
        defb    0

workspace_addr:
        defw    0

filenum:
        defb    $ff

metasize:
        defw    0

metaaddr:
        defw    0


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

msg_equals:
        defm    "=",0

msg_cr:
        defm    $0d,0

msg_meta_start:
        defm    "{",0

msg_meta_tail:
        defm    "00}",0

msg_nodata:
        defm    "Unable to access metadat",'a'+$80

msg_metafull:
        defm    "No room for metadat",'a'+$80

msg_writefail:
        defm    "Error writing metadata fil",'e'+$80

msg_namefail:
        defm    "Error writing name metadat",'a'+$80

msg_allocerror:
        defm    "Out of memory bank",'s'+$80

msg_help:
        defm    "METADATA v1.0 by Garry Lancaster",$0d
        defm    "Reads/writes metadata",$0d,$0d
        defm    "SYNOPSIS:",$0d,$0d
        defm    ".METADATA R file key",$0d
        defm    "Read metadata, and sets reg 127",$0d
        defm    "to: 0=cache,1=filename,255=none",$0d,$0d
        defm    ".METADATA W file key data [loc]",$0d
        defm    "Write metadata; optional loc is:",$0d
        defm    "0=cache only,1=cache/filename",$0d,$0d
        defm    "Example:",$0d,$0d
        defm    ".METADATA r Jetpac.z80 LOAD",$0d,$0d
        defm    "Read LOAD data for Jetpac.z80",$0d,0
