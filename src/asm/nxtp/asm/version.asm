; version.asm
;
; Auto-generated by ZXVersion.exe
; On 22 Jan 2020 at 20:12

BuildNo                 macro()
                        db "60"
mend

BuildNoValue            equ "60"
BuildNoWidth            equ 0 + FW6 + FW0



BuildDate               macro()
                        db "22 Jan 2020"
mend

BuildDateValue          equ "22 Jan 2020"
BuildDateWidth          equ 0 + FW2 + FW2 + FWSpace + FWJ + FWa + FWn + FWSpace + FW2 + FW0 + FW2 + FW0



BuildTime               macro()
                        db "20:12"
mend

BuildTimeValue          equ "20:12"
BuildTimeWidth          equ 0 + FW2 + FW0 + FWColon + FW1 + FW2



BuildTimeSecs           macro()
                        db "20:12:22"
mend

BuildTimeSecsValue      equ "20:12:22"
BuildTimeSecsWidth      equ 0 + FW2 + FW0 + FWColon + FW1 + FW2 + FWColon + FW2 + FW2
