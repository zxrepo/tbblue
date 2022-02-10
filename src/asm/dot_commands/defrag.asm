; ***************************************************************************
; * Dot command for defragmenting files                                     *
; * .defrag filename                                                        *
; ***************************************************************************

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

; Definitions
filemap_size            equ     257             ; allows for 4GB if each
                                                ; span is 32768 sectors
                                                ; (256*32768*0.5K)

buffer_size             equ     4096            ; size of RAM copy buffer
                                                ; (also used for filemap)


; ***************************************************************************
; * Initialisation                                                          *
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
        ld      de,0                    ; further args to ROM
        call    get_sizedarg            ; check if any further args
        jr      nc,defrag_init          ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg                ; else just show usage info
        and     a                       ; Fc=0, successful
        ret                             ; exit


; ***************************************************************************
; * Initialisation                                                          *
; ***************************************************************************

defrag_init:
        di                              ; disable interrupts for the duration
        ld      bc,buffer_size
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
        jp      err_custom


; ***************************************************************************
; * Open file                                                               *
; ***************************************************************************

good_nextzxos:
        ld      a,'*'                   ; default drive
        ld      hl,filename
        ld      b,esx_mode_read+esx_mode_open_exist
        callesx f_open                  ; attempt to open the file
        jr      c,exit_error            ; exit with any error

        ld      (filehandle),a          ; store the filehandle for later
        call    check_fragmentation     ; is it fragmented?
        jr      c,exit_error
        jr      nz,dodefrag             ; on if it is
        ld      hl,msg_notfragmented    ; report that file is unfragmented
        call    printmsg
        and     a                       ; successful
        jr      exit_error              ; close file and exit


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
        ld      a,(filehandle)
        callesx f_close                 ; close the file
        ld      a,(old_caps)
        callesx m_setcaps               ; restore original caps
        ld      a,(saved_speed)
        nxtrega nxr_turbo               ; restore original speed
        pop     hl                      ; restore error status
        pop     af
        ei                              ; re-enable interrupts
        ret


; ***************************************************************************
; * Get the file size                                                       *
; ***************************************************************************

dodefrag:
        ld      a,(filehandle)
        ld      hl,fstat_buffer
        callesx f_fstat                 ; get file information
        jr      c,exit_error
        ld      hl,msg_findingspace
        call    printmsg                ; "Finding space..."
defrag_search_loop:
        ld      a,'.'
        print_char()
        ld      hl,(temp_num)
        inc     hl                      ; HL=next temporary file number
        ld      (temp_num),hl
        call    settempfilename         ; set up the temporary file name
        ld      hl,msg_tmpfilename
        ld      b,esx_mode_write+esx_mode_read+esx_mode_creat_trunc
        ld      a,'*'
        callesx f_open                  ; create new temporary file
        jp      c,defrag_failed_creatent; if failed, delete temps & exit
        ld      (tmpfilehandle),a
        ld      de,(file_size)
        ld      bc,(file_size+2)
        callesx f_ftruncate             ; expand to required size
        jp      c,defrag_failed_expand  ; if failed, delete temps & exit
        ld      a,(tmpfilehandle)
        call    check_fragmentation     ; is it fragmented?
        jp      c,defrag_failed_fragm   ; if failed, delete temps & exit
        jr      z,defrag_found
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the temporary file
        jr      defrag_search_loop      ; back for more

defrag_found:
        ld      a,(filehandle)
        ld      bc,0
        ld      de,0
        ld      l,esx_seek_set
        callesx f_seek                  ; seek to start of source file
        ld      a,(tmpfilehandle)
        ld      bc,0
        ld      de,0
        ld      l,esx_seek_set
        callesx f_seek                  ; seek to start of dest file
        ld      hl,msg_okay
        call    printmsg
        ld      hl,msg_copyingdata
        call    printmsg                ; "Copying data"
        ld      bc,0                    ; no bytes copied initially
copy_loop:
        ld      hl,(file_size)
        ld      de,(file_size+2)
        and     a
        sbc     hl,bc                   ; subtract bytes copied last iteration
        ld      (file_size),hl
        jr      nc,size_adjusted
        dec     de
        ld      (file_size+2),de
size_adjusted:
        ld      a,d
        or      e
        or      h
        or      l
        jr      z,copy_finished         ; on if 0 bytes left
        push    hl
        push    de
        call    print_byte_size
        pop     de
        pop     hl
        ld      bc,buffer_size          ; 4K to copy
        ld      a,h
        and     $f0
        or      d
        or      e
        jr      nz,got_copy_size
        ld      b,h                     ; just copy remaining bytes if <4K
        ld      c,l
got_copy_size:
        push    bc
        ld      a,(filehandle)
        ld      hl,(bufferaddr)
        callesx f_read                  ; read data from the original file
        jr      c,defrag_failed_read    ; exit if error
        pop     hl
        push    hl
        and     a
        sbc     hl,bc                   ; were all bytes read?
        scf
        ld      a,esx_eio
        jr      nz,defrag_failed_rdsize ; error if not
        ld      a,(tmpfilehandle)
        ld      hl,(bufferaddr)
        callesx f_write                 ; write data to the new file
        jr      c,defrag_failed_write
        pop     hl
        push    hl
        and     a
        sbc     hl,bc                   ; were all bytes written?
        scf
        ld      a,esx_eio
        jr      nz,defrag_failed_wrsize ; error if not
        ld      hl,msg_erasesize
        call    printmsg
        pop     bc                      ; BC=#bytes just copied
        jr      copy_loop
copy_finished:
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the new file
        jr      c,defrag_failed_newclose
        ld      a,(filehandle)
        callesx f_close                 ; close the original file
        jr      c,defrag_failed_oldclose
        ld      a,'*'
        ld      hl,filename
        callesx f_unlink                ; delete the original file
        jr      c,defrag_failed_delete
        ld      a,'*'
        ld      hl,msg_tmpfilename
        ld      de,filename
        callesx f_rename                ; rename temp to original
        jr      c,defrag_failed_rename
        ld      hl,msg_okay
        call    printmsg
        call    delete_tmps             ; delete remaining temporary files
        and     a
        jp      exit_error              ; for now just close the file & exit


; ***************************************************************************
; * Defragmentation search failed                                           *
; ***************************************************************************

defrag_failed_creatent:
        ld      hl,msg_failed_create
        jr      defrag_failed_notmp
defrag_failed_expand:
        ld      de,msg_failed_expand
        jr      defrag_failed_all
defrag_failed_fragm:
        ld      de,msg_failed_fragm
        jr      defrag_failed_all
defrag_failed_read:
        ld      de,msg_failed_read
        jr      defrag_failed_all
defrag_failed_rdsize:
        ld      de,msg_failed_readsize
        jr      defrag_failed_all
defrag_failed_write:
        ld      de,msg_failed_write
        jr      defrag_failed_all
defrag_failed_wrsize:
        ld      de,msg_failed_writesize
        jr      defrag_failed_all
defrag_failed_newclose:
        ld      de,msg_failed_newclose
        jr      defrag_failed_all
defrag_failed_oldclose:
        ld      de,msg_failed_oldclose
        jr      defrag_failed_all
defrag_failed_delete:
        ld      de,msg_failed_delete
        jr      defrag_failed_all
defrag_failed_rename:
        ld      de,msg_failed_rename
        jr      defrag_failed_all

defrag_failed_all:
        push    de
        push    af
        ld      a,(tmpfilehandle)
        callesx f_close                 ; close the temporary file
        pop     af
        pop     hl
defrag_failed_notmp:
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
        print_char()
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
        ld      hl,(bufferaddr)
        ld      bc,1
        callesx f_read                  ; read 1 byte to ensure starting cluster
        pop     af
        ld      hl,(bufferaddr)
        ld      de,filemap_size
        callesx disk_filemap
        ret     c
        push    hl                      ; save address after last buffer entry
        ld      hl,(bufferaddr)
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ld      e,(hl)
        inc     hl
        ld      d,(hl)
        inc     hl
        push    de                      ; TOS,BC=4-byte card address
check_frag_loop:
        ld      e,(hl)
        inc     hl
        ld      d,(hl)                  ; DE=sector count
        inc     hl
        ex      de,hl                   ; DE=buffer address, HL=sector count
        bit     1,a
        jr      nz,check_frag_add_blocks
check_frag_add_bytes:
        ; If byte-addressed, add 512*sector count to the card address
        push    hl
        ld      h,l
        ld      l,0
        ex      (sp),hl
        pop     ix
        ld      l,h
        ld      h,0                     ; HLIX=256*sector count
        add     ix,ix
        adc     hl,hl                   ; HLIX=512*sector count
        add     ix,bc
        pop     bc
        adc     hl,bc                   ; HLIX=following card address
        jr      check_frag_test_next
check_frag_add_blocks:
        ; If block-addressed, add sector count to the card address
        add     hl,bc
        push    hl
        pop     ix
        pop     bc
        ld      hl,0
        adc     hl,bc                   ; HLIX=following card address
check_frag_test_next:
        ; HLIX=next card address
        ; DE=buffer address after current entry
        ; TOS=buffer address after last entry
        ex      (sp),hl                 ; HL=buffer address after last entry
        and     a
        sbc     hl,de
        pop     bc
        ret     z                       ; exit with Fc=0, Fz=1 if done
        push    bc
        add     hl,de                   ; reform address
        ex      (sp),hl                 ; and re-stack
        ex      de,hl                   ; HL=buffer address after current
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        push    ix
        ex      (sp),hl
        and     a
        sbc     hl,bc                   ; is low word of card addr the same?
        jr      nz,check_frag_failed    ; if not, file is fragmented
        pop     hl
        push    bc
        ld      c,(hl)
        inc     hl
        ld      b,(hl)
        inc     hl
        ex      de,hl
        and     a
        sbc     hl,bc                   ; is high word of card addr the same?
        jr      nz,check_frag_failed    ; if not, file is fragmented
        pop     hl
        push    bc
        ld      b,h
        ld      c,l                     ; TOS,BC=4-byte card address
        ex      de,hl                   ; HL=buffer address of sector count
        jr      check_frag_loop
check_frag_failed:
        pop     bc                      ; discard values
        pop     bc
        xor     a
        inc     a                       ; Fc=0, Fz=0, fragmented
        ret


; ***************************************************************************
; * Display size in K/M, aligned                                            *
; ***************************************************************************
; Entry: DEHL=size in bytes

print_byte_size:
        ld      bc,$0a00+'K'    ; >>10 for capacity in KB
        ld      a,d             ; if below 32MB
        cp      2
        jr      c,shift_to_units
        ld      bc,$1400+'M'    ; >>20 for capacity in MB
shift_to_units:
        xor     a               ; no truncation occurred
shift_to_units_loop:
        srl     d               ; calculate HL=capacity in appropriate units
        rr      e
        rr      h
        rr      l
        adc     a,0             ; A=A+Fc
        djnz    shift_to_units_loop
        and     a
        jr      z,no_rounding
        inc     hl              ; increment if anything got shifted out
no_rounding:
        push    bc
        ld      e,' '
        ld      bc,$d8f0        ; -10000
        call48k OUT_SP_NO_r3    ; output 10000s
        ld      bc,$fc18        ; -1000
        call48k OUT_SP_NO_r3    ; output 1000s
        ld      bc,$ff9c        ; -100
        call48k OUT_SP_NO_r3    ; output 100s
        ld      c,$f6           ; -10
        call48k OUT_SP_NO_r3    ; output 10s
        ld      a,l
        call48k OUT_CODE_r3     ; output units
        pop     bc
        ld      a,c
        print_char()            ; "K" or "M"
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
        defm    "DEFRAG v1.7 by Garry Lancaster",$0d
        defm    "Defragments a file",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .DEFRAG FILE",$0d,0

msg_notfragmented:
        defm    "File is already defragmented!",$0d,$0d,0

msg_findingspace:
        defm    "Finding space..",0

msg_deletingtemps:
        defm    "Erasing temps.",0

msg_copyingdata:
        defm    "Copying data....",0

msg_erasesize:
        defm    8,8,8,8,8,8,0

msg_failed_create:
        defm    $0d," - FAILED creating tmp file",$0d,0

msg_failed_expand:
        defm    $0d," - FAILED reserving space",$0d,0

msg_failed_fragm:
        defm    $0d," - FAILED checking fragmentation",$0d,0

msg_failed_read:
        defm    $0d," - FAILED reading file",$0d,0

msg_failed_readsize:
        defm    $0d," - FAILED file read size",$0d,0

msg_failed_write:
        defm    $0d," - FAILED writing file",$0d,0

msg_failed_writesize:
        defm    $0d," - FAILED file write size",$0d,0

msg_failed_newclose:
        defm    $0d," - FAILED closing new file",$0d,0

msg_failed_oldclose:
        defm    $0d," - FAILED closing old file",$0d,0

msg_failed_delete:
        defm    $0d," - FAILED deleting old file",$0d,0

msg_failed_rename:
        defm    $0d," - FAILED renaming new file",$0d,0

msg_origfile:
        defm    "Old file: '",0

msg_newfile:
        defm    "'",$0d,"New file: '",0

msg_endfilenames:
        defm    "'",$0d,0

msg_okay:
        defm    "OK    ",$0d,0

msg_tmpfilename:
        defm    "$$$defrag_tmp"
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

filehandle:
        defb    $ff

tmpfilehandle:
        defb    $ff

filename:
        defs    256

fstat_buffer:
        defb    0                       ; drive
        defb    0                       ; drive details
        defb    0                       ; attributes
        defw    0,0                     ; time, date
file_size:
        defw    0,0                     ; filesize

temp_num:
        defw    0                       ; number of current temporary file

bufferaddr:
        defw    0                       ; address of 4K buffer in main RAM
if ((filemap_size*6) > buffer_size)
.ERROR Filemap exceeds allocated buffer space
endif
