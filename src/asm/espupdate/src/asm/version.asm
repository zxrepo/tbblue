; version.asm
;
; Auto-generated by ZXVersion.exe
; On 21 Feb 2020 at 18:16

BuildNo                 macro()
                        db "71"
mend

BuildNoValue            equ "71"
BuildNoWidth            equ 0 + FW7 + FW1



BuildDate               macro()
                        db "21 Feb 2020"
mend

BuildDateValue          equ "21 Feb 2020"
BuildDateWidth          equ 0 + FW2 + FW1 + FWSpace + FWF + FWe + FWb + FWSpace + FW2 + FW0 + FW2 + FW0



BuildTime               macro()
                        db "18:16"
mend

BuildTimeValue          equ "18:16"
BuildTimeWidth          equ 0 + FW1 + FW8 + FWColon + FW1 + FW6



BuildTimeSecs           macro()
                        db "18:16:41"
mend

BuildTimeSecsValue      equ "18:16:41"
BuildTimeSecsWidth      equ 0 + FW1 + FW8 + FWColon + FW1 + FW6 + FWColon + FW4 + FW1