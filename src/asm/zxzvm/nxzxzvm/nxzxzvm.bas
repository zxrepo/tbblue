PLUS3DOS �   u�u                                                                                                         K 
 �main()   ; 	 �setup() ( ��:�1    ,1      2  ; < �Set preferred colours F �7    :�7    :�1     P ��30    ;�5    ;:� Z  ; d9 �Set screen offset and width/height to suit your monitor n �oy=line start (0=top) x �ox=col start (0=left) � �h=height, w=width � �Max: oy+h=32, ox+w=80 � �oy=2    :�h=28     � �ox=0     :�w=80  P   �' �49152   � ,oy:�49153  � ,h-2     � �49154  � ,ox:�49155  � ,w �  ; �, �Set up your printer on #3 for transcripts: � �:OPEN # 3,"" �  ; � � �  ; � �main()	 �setup() �welcome() �"   �chooseStory()�f$,   �start(f$)6
 ��0     @ �J  ;T �chooseStory()^}  .browse -t Z? -p "Choose a story file to play (.z3 .z4 .z5 .z7 .z8)  Press SPACE to exit ZXZVM                         " f$h	 �f$=""��r �=f$|  ;� �start(f$)�* �n=1    ̱f$:�28763   [p + n,�f$(n):�n� �28763   [p + n, 255  �  �! �1    ,1    :�x=�28672   p � ��  ;� �loadZXZVM(p$)�
 ��2    � �p$+"nxzxzvm.bin"�%$6800� �p$+"fonts/normal.fnt"�%$cf00�  �p$+"fonts/emphasis.fnt"�%$d200� �p$+"fonts/accent.fnt"�%$d500�  �p$+"fonts/accentem.fnt"�%$d780 �p$+"fonts/font3.fnt"�%$da00 �p$+"fonts/font3em.fnt"�%$dd00 �&  ;0 �story(f$,p$): �loadZXZVM(p$)D	 �setup()N �start(f$)X �b �l  ;v �welcome()�@ ��1    ;�11    ;"ZXZVM for the ZX Spectrum Next";�0     ''�W �'"This is John Elliott's ZXZVM, ported to the"'"ZX Spectrum Next by Garry Lancaster."�J �'"It allows you to play text adventure games written for the Z-Machine."�� �'"This includes classic games from Infocom such as"'"Zork and Planetfall, as well as hundreds of newer"'"games written between 1993 and the present day."�� �'"Some games can be found in C:/games/Z-Machine on"'"your Next's SD card. The definitive source for"'"Z-Machine games on the internet is:"''�13    ;"https://www.ifarchive.org"�d �'"ZXZVM can play version 3, 4, 5, 7 and 8 games."'"Filenames should end with: .z3 .z4 .z5 .z7 .z8"�: �''�1    ;�18    ;"Press any key";�0     :�0     :�� ��  ;� �%$67ff� �loadZXZVM("")� �main()