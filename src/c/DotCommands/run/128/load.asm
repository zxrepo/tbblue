INCLUDE "config_zxn_private.inc"

SECTION code_user

PUBLIC _load_snap
PUBLIC _load_nex

defc MAX_NAME_LEN = 12         ; 8.3 only

EXTERN _dirent_sfn

defc PROGRAM_NAME = _dirent_sfn + 1;

;;;;;;;;;;;;;;;;;;;;;;
; void load_snap(void)
;;;;;;;;;;;;;;;;;;;;;;

_load_snap:

   ld sp,(__SYSVAR_ERRSP)
   ld iy,__SYS_IY

   call close_dot_handle

   ; make room for snap stub
   
   ld bc,snap_stub_end - snap_stub + MAX_NAME_LEN + 1
   
   rst __ESX_RST_ROM
   defw __ROM3_BC_SPACES
   
   push de                     ; save start address
   
   ; copy snap_stub
   
   ld hl,snap_stub
   ld bc,snap_stub_end - snap_stub
   
   ldir
   
   push de                     ; save filename address
   
   ; copy filename
   
   call copy_filename
   
   ld a,0xff
   ld (de),a
   
   ; start the snap
   
   pop ix                      ; ix = filename

   pop hl                      ; hl = start address   
   rst __ESX_RST_EXITDOT

snap_stub:

   push ix
   pop hl
   
   exx
   
   ld de,__NEXTOS_IDE_SNAPLOAD
   ld c,7
   
   rst __ESX_RST_SYS
   defb __ESX_M_P3DOS
   
   ld iy,__SYS_IY
   
   rst 8
   defb __ERRB_Q_PARAMETER_ERROR - 1

snap_stub_end:

;;;;;;;;;;;;;;;;;;;;;
; void load_nex(void)
;;;;;;;;;;;;;;;;;;;;;

_load_nex:

   ld sp,(__SYSVAR_ERRSP)
   ld iy,__SYS_IY

   call close_dot_handle

   ; make room for nex stub

   ld bc,nex_stub_end - nex_stub + MAX_NAME_LEN + 1
   
   rst __ESX_RST_ROM
   defw __ROM3_BC_SPACES
   
   push de                     ; save start address
   
   ; copy snap_stub
   
   ld hl,nex_stub
   ld bc,nex_stub_end - nex_stub
   
   ldir

   ; copy filename
   
   ld ix,nex_stub_cmd - nex_stub_end
   add ix,de                   ; ix = address of dot command
   
   call copy_filename
   
   xor a
   ld (de),a

   ; start nex
   
   pop hl                      ; hl = start address
   rst __ESX_RST_EXITDOT

nex_stub:

   push ix
   pop hl
   
   rst __ESX_RST_SYS
   defb __ESX_M_EXECCMD
   
   rst 8
   defb __ERRB_Q_PARAMETER_ERROR - 1

nex_stub_cmd:

   defm "nexload "

nex_stub_end:

;;;;;;;;;;;;;;;;;;
; close dot handle
;;;;;;;;;;;;;;;;;;

; exit via rst$20 does not close the dot handle

close_dot_handle:

   rst __ESX_RST_SYS
   defb __ESX_M_GETHANDLE
   
   rst __ESX_RST_SYS
   defb __ESX_F_CLOSE
   
   ret

;;;;;;;;;;;;;;;
; copy filename
;;;;;;;;;;;;;;;

copy_filename:

   ld hl,PROGRAM_NAME
   ld bc,MAX_NAME_LEN
   
   xor a
   
loop_name:

   cp (hl)
   ret z                       ; if terminator met
   
   ldi
   jp pe, loop_name            ; if max len not exceeded
   
   ret
