; ***************************************************************************
; * Dot command for uninstalling loadable drivers:                          *
; * .uninstall filename.drv                                                 *
; ***************************************************************************
; Assemble with: pasmo uninstall.asm uninstall
; Place in C:/DOT directory and execute with:  .uninstall filename.drv


; ***************************************************************************
; * .DRV file format                                                        *
; ***************************************************************************
; A valid .DRV file is laid out as:
;
;       defm    "NDRV"          ; .DRV file signature
;
;       defb    id              ; 7-bit unique driver id in bits 0..6
;                               ; bit 7=1 if to be called on IM1 interrupts
;
;       defb    relocs          ; number of relocation entries (0..255)
;
;       defb    mmcbanks        ; number of additional 8K DivMMC RAM banks
;                               ; required (0..8)
;
;       Additionally if bit 7 of mmcbanks is set:
;       .INSTALL will call driver function $80
;       .UNINSTALL will call driver function $81
;       Entry parameters:
;         HL=address of: byte 0: # allocated ZX RAM banks
;                        bytes 1+: list of ZX RAM bank ids
;         DE=address of: byte 0: # allocated DivMMC RAM banks
;                        bytes 1+: list of DivMMC RAM bank ids
;       If carry is set on exit, .INSTALL/.UNINSTALL will be aborted.
;
;       defb    zxbanks         ; number of additional 8K Spectrum RAM banks
;                               ; required (0..200)
;
;       defs    512             ; 512-byte driver code, assembed at ORG 0
;
;       defs    relocs*2        ; for each relocation, a 2-byte offset (0..511)
;                               ; of the high byte of the address to be relocated
;
;       Then, for each mmcbank requested:
;
;       defb    bnk_patches     ; number of driver patches for this bank id
;       defw    bnk_size        ; size of data to pre-load into bank (0..8191)
;       defs    bnk_size        ; data to pre-load into bank
;       defs    bnk_patches*2   ; for each patch, a 2-byte offset (0..511) in
;                               ; the 512-byte driver to write the bank id to
;       NOTE: The first patch for each mmcbank should never be changed, as
;             .uninstall will use the value for deallocating.
;
;       Then, for each zxbank requested:
;
;       defb    bnk_patches     ; number of driver patches for this bank id
;       defw    bnk_size        ; size of data to pre-load into bank (0..8191)
;       defs    bnk_size        ; data to pre-load into bank
;       defs    bnk_patches*2   ; for each patch, a 2-byte offset (0..511) in
;                               ; the 512-byte driver to write the bank id to
;       NOTE: The first patch for each zxbank should never be changed, as
;             .uninstall will use the value for deallocating.
;


; ***************************************************************************
; * esxDOS API and other definitions required                               *
; ***************************************************************************

; Calls
f_open                  equ     $9a             ; opens a file
f_close                 equ     $9b             ; closes a file
f_read                  equ     $9d             ; read file
f_seek                  equ     $9f             ; seek
m_drvapi                equ     $92             ; driver API
m_p3dos                 equ     $94             ; call +3DOS API

; ROM 3 routines
BC_SPACES_r3            equ     $0030           ; allocate workspace

; File access modes
esx_mode_read           equ     $01             ; read access
esx_mode_open_exist     equ     $00             ; open existing files only

; Seek modes
esx_seek_fwd            equ     1               ; seek forward

; Constants
drv_header_len          equ     8               ; size of .DRV header

; +3DOS API calls
ide_bank                equ     $01bd           ; bank allocation


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
        jr      nc,uninstall_start      ; okay if not
show_usage:
        ld      hl,msg_help
        call    printmsg
        and     a                       ; Fc=0, successful
        ret


; ***************************************************************************
; * Open file and validate header                                           *
; ***************************************************************************

uninstall_start:
        di                              ; ensure interrupts disabled
                                        ; for remainder of command
        ld      a,'*'                   ; default drive
        ld      hl,filename
        ld      b,esx_mode_read+esx_mode_open_exist
        rst     $08
        defb    f_open                  ; attempt to open the file
        ret     c                       ; exit with any error

        ld      (filehandle),a          ; store the filehandle for later
        ld      hl,fileheader
        ld      bc,8
        rst     $08
        defb    f_read                  ; read the 8-byte header
        jp      c,exit_error            ; exit with any error

        ld      hl,(fileheader)         ; validate signature
        ld      de,(filesig)
        and     a
        sbc     hl,de
        jp      nz,err_badsig
        ld      hl,(fileheader+2)
        ld      de,(filesig+2)
        and     a
        sbc     hl,de
        jp      nz,err_badsig


; ***************************************************************************
; * Allocate workspace memory in main RAM                                   *
; ***************************************************************************

        ld      hl,(fileheader+5)       ; L=#relocs
        ld      h,0
        add     hl,hl                   ; HL=size of relocations
        inc     h                       ; +512 for driver
        inc     h
        push    hl                      ; save size of driver+relocs
        ld      bc,512+512+512          ; 512 for bank lists,
                                        ; 512 for driver
                                        ; 512 for relocs/bank patches
        rst     $18
        defw    BC_SPACES_r3            ; allocate workspace memory for driver
                                        ; returns with BC unchanged, DE=address

        ex      de,hl                   ; HL=address for list of MMC banks
        ld      (mmcbanklist_addr),hl
        inc     h                       ; HL=address of list of ZX banks
        ld      (zxbanklist_addr),hl
        inc     h                       ; HL=address to load driver+reloc
        ld      (driver_addr),hl
        pop     bc                      ; BC=size of driver+relocs


; ***************************************************************************
; * Read driver from the file into newly-allocated workspace                *
; ***************************************************************************
; HL=(driver_addr) from above, BC=size of driver+relocs

        ld      a,(filehandle)
        rst     $08
        defb    f_read                  ; read the driver+relocs
        jp      c,exit_error            ; exit with any error reading the file


; ***************************************************************************
; * Read installed driver image                                             *
; ***************************************************************************

        ld      hl,(driver_addr)        ; buffer for driver
        ld      a,(fileheader+4)
        ld      e,a                     ; E=id
        ld      bc,$0400                ; C=0, driver API. B=4, get driver.
        rst     $08
        defb    m_drvapi                ; get the driver image
        jr      c,exit_error            ; exit if there is an error


; ***************************************************************************
; * Obtain the banklists from the driver image                              *
; ***************************************************************************

        ld      hl,(mmcbanklist_addr)
        ld      a,(fileheader+6)
        and     $7f                     ; A=# MMC banks
        call    generate_banklist       ; get the allocated MMC banks
        ld      hl,(zxbanklist_addr)
        ld      a,(fileheader+7)        ; A=# ZX banks
        call    generate_banklist       ; get the allocated ZX banks


; ***************************************************************************
; * Shutdown the driver                                                     *
; ***************************************************************************

        ld      a,(fileheader+6)
        bit     7,a
        jr      z,shutdown_success      ; on if shutdown not needed
        ld      a,(fileheader+4)
        and     $7f
        ld      c,a                     ; C=driver id
        ld      b,$81                   ; B=$81, shutdown
        ld      hl,(zxbanklist_addr)    ; HL=number and list of ZX banks
        ld      de,(mmcbanklist_addr)   ; DE=number and list of MMC banks
        rst     $08
        defb    m_drvapi                ; initialise the driver
        ld      hl,msg_shutdownfail
        jr      c,err_custom            ; exit if failed


; ***************************************************************************
; * Attempt to uninstall the driver                                         *
; ***************************************************************************

shutdown_success:
        ld      a,(fileheader+4)
        ld      e,a                     ; E=id

        ld      bc,$0200                ; C=0, driver API. B=2, uninstall.
        rst     $08
        defb    m_drvapi                ; uninstall the driver
        jr      c,exit_error            ; exit if there is an error


; ***************************************************************************
; * Deallocate the banks associated with the driver                         *
; ***************************************************************************

        ld      hl,(mmcbanklist_addr)
        ld      d,1                     ; rc_banktype_mmc
        call    deallocate_banks        ; deallocate
        ld      hl,(zxbanklist_addr)
        ld      d,0                     ; rc_banktype_zx
        call    deallocate_banks
        xor     a                       ; Fc=0, success!


; ***************************************************************************
; * Close file and exit with any error condition                            *
; ***************************************************************************

exit_error:
        push    af                      ; save error status
        push    hl
        ld      a,(filehandle)
        rst     $08
        defb    f_close                 ; close the file
        pop     hl                      ; restore error status
        pop     af
        ei                              ; re-enable interrupts
        ret


; ***************************************************************************
; * Custom error generation                                                 *
; ***************************************************************************

err_badsig:
        ld      hl,msg_badsig
err_custom:
        xor     a                       ; A=0, custom error
        scf                             ; Fc=1, error condition
        jr      exit_error


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
; * Deallocate banks                                                        *
; ***************************************************************************
; Entry: D=rc_banktype_mmc (1) or rc_banktype_zx (0)
;        HL=(mmcbanklist_addr) or (zxbanklist_addr)

deallocate_banks:
        ld      a,(hl)
        and     a
        ret     z                       ; exit if none to deallocate
        ld      e,3                     ; rc_bank_free
        ld      (hl),0                  ; clear number allocated
        ld      b,a                     ; B=# banks to free
deallocate_banks_loop:
        push    bc                      ; save number still to deallocate
        push    de                      ; save allocation reasons
        inc     hl
        push    hl                      ; save address of next bank
        ld      l,(hl)                  ; L=bank id
        ex      de,hl                   ; H=banktype, L=alloc, E=bank id
        exx                             ; place params in alternates
        ld      de,ide_bank
        ld      c,7
        rst     $08
        defb    m_p3dos                 ; call IDE_BANK
        pop     hl
        pop     de
        pop     bc
        jr      nc,dealloc_error        ; exit if error
        djnz    deallocate_banks_loop   ; back for more
        ret

dealloc_error:
        pop     hl                      ; discard return address
        ld      hl,msg_baddealloc
        jr      err_custom


; ***************************************************************************
; * Generate list of allocated bank ids                                     *
; ***************************************************************************
; Entry: HL=(mmcbanklist_addr) or (zxbanklist_addr)
;        A=# banks

generate_banklist:
        ld      (hl),a                  ; store # banks
        and     a
        ret     z                       ; exit if no banks allocated
        ld      (saved_sp),sp           ; save current SP
        ld      b,a                     ; B=number of banks
generate_banklist_loop:
        push    bc                      ; save remaining banks
        inc     hl
        push    hl                      ; save address of current bank id
        ld      hl,bank_patches
        ld      bc,3
        ld      a,(filehandle)
        rst     $08
        defb    f_read                  ; read #patches & size of preload
        jp      c,generate_error        ; exit with any error
        ld      a,(bank_patches)
        and     a                       ; if 0, A=0 (custom error)
        scf
        ld      hl,msg_need1patch
        jp      z,generate_error        ; exit if zero bank patches
        ld      hl,(bank_preloadsize)
        ld      bc,8193
        xor     a                       ; A=0, custom error; Fc=0
        sbc     hl,bc
        ccf
        ld      hl,msg_badpreloadsize
        jp      c,generate_error        ; exit if preload size > 8192
        ld      de,(bank_preloadsize)
        ld      a,d
        or      e
        jr      z,skipped_preload       ; nothing to do if zero
        ld      bc,0
        ld      l,esx_seek_fwd
        ld      a,(filehandle)
        rst     $08
        defb    f_seek                  ; skip the preload data
skipped_preload:
        ld      hl,(bank_patches)
        ld      h,0
        add     hl,hl                   ; size of patch list
        ld      b,h
        ld      c,l
        ld      hl,(driver_addr)
        inc     h
        inc     h                       ; bank patch data overwrites relocs
        push    hl
        ld      a,(filehandle)
        rst     $08
        defb    f_read                  ; read the patch data
        jr      c,generate_error
        pop     hl
        ld      c,(hl)
        inc     hl
        ld      b,(hl)                  ; BC=offset of first patch
        ld      hl,(driver_addr)
        add     hl,bc                   ; address of first patch
        ld      a,(hl)                  ; A=allocated bank id
        pop     hl
        ld      (hl),a                  ; store in bank list
        pop     bc
        djnz    generate_banklist_loop
        ret

generate_error:
        ld      sp,(saved_sp)           ; restore SP
        jp      exit_error


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

filehandle:
        defb    0

filename:
        defs    256

fileheader:
        defs    8

filesig:
        defm    "NDRV"

mmcbanklist_addr:
        defw    0

zxbanklist_addr:
        defw    0

bank_patches:
        defb    0
bank_preloadsize:
        defw    0
if (bank_preloadsize != (bank_patches+1))
.ERROR Incorrect assumption: bank_preloadsize=bank_patches+1
endif

driver_addr:
        defw    0

saved_sp:
        defw    0


; ***************************************************************************
; * Messages                                                                *
; ***************************************************************************

msg_badsig:
        defm    "Invalid .DRV fil",'e'+$80

msg_need1patch:
        defm    "Bank must have 1+ patche",'s'+$80

msg_badpreloadsize:
        defm    "Preload size > 8192 byte",'s'+$80

msg_shutdownfail:
        defm    "Driver in us",'e'+$80

msg_baddealloc:
        defm    "Error deallocating ban",'k'+$80

msg_help:
        defm    "UNINSTALLv1.2 by Garry Lancaster",$0d
        defm    "Uninstalls a NextZXOS driver",$0d,$0d
        defm    "SYNOPSIS:",$0d
        defm    " .UNINSTALL NAME.DRV",$0d,0

