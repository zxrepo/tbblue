PLUS3DOS o   �
 �                                                                                                         * 
" ; NextBASIC Invaders example game  ; 
 ��2     ( �main() 2 ; < �playGame() F � P �� Z% �%k=%��(65,0�35,7):�%k˓kill(%k&127) d �%��(64,68�71,6,7)˓die() n7 �%��(a(t),1)=(h+(t*20)+8)˓moveDown():�%(h+(b*20))<240 xJ �%m=%((�i(0)&k(0)=v(0))-(�i(1)&k(1)=v(1)))�1:�%(p+m)<304��%p=%p+m:�%64,%p �% �%(�i(2)&k(2)=v(2))�(�65=0)˓shoot() �( �%((�100>85)��(�68ƞ69ƞ70ƞ71))˓zap() �1 �%(e<10)�(e<(d+(n/5)))�(��(a(b),5)=0)˓speedUp() �% �%((�50000>49950)�(�35=0))˓saucer() � ��%a=0 �3 ��0     ,11    ;�1    ;�6    ;"GAME OVER!"  � �%i=1    �20     � �octave=%�9 �  �p$="O"+�octave+"M56X16384UW0c" �
 �p$,p$,p$ � �%i �4 ��2    ,5    ;�1    ;"Press any key for menu" � �#0     �key � ; �updateMovement()" �%y,%o,( �Update x limits for each anchor sprite6 �%y=0     �4    @4 �%e(y)˞�%a(y),%32+(20*(l(y)-l))�%272-(20*(r-l(y)))J �%yT �^ ;h	 �shoot()r! �Start shot from player position|' �65  A  ,%p,240  �  ,1    ,1    �= ��65  A  ,%p�,0     �240  �  �-4    �,1    ,�11    �' �"M56X2048W0U1c","X2048U1c","X2048U1c"� �� ;� �zap()�
 �%i,x,y,o�% �Find an unused alien missile sprite� �%i=67  C  � ��	 �%i=%i+1� ��%�i=0� �Choose a column� �%x=%l+�(r-l+1):�%y=%b& �Find row of lowest invader in column/ �:�%�(((l(y)<x)ƞ(a(y)+x))�((l(y)=x)ƞ(a(y))))	 �%y=%y-1& ��%(y=-1) 0	 �%y=-1˒:$ �Start missile in middle of invaderD �%o=%��(a(y),1)+8N/ �%i,%��(a(y),0)+((x-l(y))*20),%o,%2+�2,1    X7 ��%i,�,%o�255  �  �2    �,2    �3    ,�11    b �l ;v �score(%s)� �%i� �%i=1    �5    �- �%i+80,%312-(i*8),8    ,%(s�10)+14,1    �
 �%s=%s/10� �%i�( �%80,312  8 ,8    ,14    ,1    � �� ;�
 �kill(%k)� �%y,%x� �65  A  ,,,,0     � �Special handling for saucer� �%k=35˓killSaucer():�	 �%n=%n+1 �Find grid position of victim	 �%y=%k/7   �%k=a(y)��%x=%l(y):��%x=%k-a(y)*) �Find pixel position & pattern of anchor40 �%u=%��(a(y),0):�%v=%��(a(y),1):�%w=%��(a(y),2)> �%z=%z+(5-y)H �score(%z)R. �Set sprite 3 to explosion at victim location\- �66  B  ,%u+(x-l(y)*20),%v,24    ,1    f8 ��66  B  ,�,�,24    �27    ,�1100000  `  ,3    p* �"O0M56X6144UW0c","O0X6144Uc","O0X6144Uc"z �Disable victim's sprite� �%l(y)=r(y)˓removeRow(%y):��$ �%l(y)=x˓removeLeft(%y,%u,%v,%w):�� �%�{-k},,,,0     � �%r(y)=x˓removeRight(%y)� �� ;�
 �saucer()�! �Start saucer from left to right�+ �35  #  ,0     ,8    ,28    ,1    �? ��35  #  ,0     �319  ? �1    �,�,28    ,�11    ,%�2� �� ;� �killSaucer() �Change saucer into explosion �35  #  ,,,24    8 ��35  #  ,�,�,24    �27    ,�1100000  `  ,3    $
 �%z=%z+10. �score(%z)8* �"O6M56X8192UW0c","O6X8192Uc","O6X8192Uc"B �L ;V �removeLeft(%y,%u,%v,%w)` �%xj" �Find grid position of new anchort �%x=%l(y)+1~ �� �%�(a(y)+x)=0�	 �%x=%x+1�
 ��0     � �Set anchor to new position�& �%a(y),%u+((x-l(y))*20),%v,%w,1    �' �Disable the one we promoted to anchor� �%�{-(a(y)+x)},,,,0     �
 �%l(y)=%x�% �Update offsets of remaining sprites� �%i=%x+1�6    � �%�{-(a(y)+i)},%(i-x)*20� �%i > �To prevent flicker when anchor changes, perform updates now,
< �but waiting until the scanline after the row being changed �Ѻ%(v+16)&255 �findLeft()( �2 ;< �findLeft()F �%iP �%l=99  c  Z �%i=0     �4    d �%(e(i)�(l(i)<l))��%l=%l(i)n �%ix �updateMovement()� �� ;� �removeRight(%y)� �%x� �%x=6    � �� �%�(a(y)+x)=0�	 �%x=%x-1�
 ��0     � �%x=0��%r(y)=%l(y):��%r(y)=%x� �findRight()� �� ; �findRight() �%i �%r=0     " �%i=0     �4    , �%(e(i)�(r(i)>r))��%r=%r(i)6 �%i@ �updateMovement()J �T ;^ �removeRow(%y)h �%ir �%a(y),,,,0     | �%e(y)=0     � �findLeft()� �findRight()� �Find top/bottom enabled rows� �%t=99  c  :�%b=0     � �%i=0     �4    � �%(e(i)�(i<t))��%t=%i� �%(e(i)�(i>b))��%b=%i� �%i�	 �%t<99˒� �%i=1    �16    :��:�%i� �.5�    ,10  
  �$ �Increase difficulty for next sheet� �%d<10��%d=%d+1 �initSheet() � ;& �moveDown()0 �%y:	 �%h=%h+8D! �Update y limits for each anchorN �%y=0     �4    X. �%e(y)˞�%a(y),,%h+(y*20)�%h+(y*20)+8�8    b �%yl �v ;� �setSpeed(%i)� �%e=%i�* �Invader "slowness": 20/18/16/14/12/.../2� �%s=%2*(10-i)�# �Use "slowness" 1 at maximum speed� �%i=10��%s=1    � �� ;� �speedUp()� �%y� �setSpeed(%e+1)�% �Update rate & delay for each anchor�
 �%y=%t�%b! �%e(y)˞�%a(y),,,,,%5*s,%(5-y)*s �%y �  ;* �die()4 �%i,o,p$,octave> �Change base into explosionH �64  @  ,,,24    R0 ��64  @  ,�,�,24    �27    ,�1100000  `  \ �Loop through animationf �%i=1    �5    p ��z �octave=%�9� �p$="O"+�octave+"M56X6144UW0c"�
 �p$,p$,p$� �%i� �Reduce lives�	 �%a=%a-1� �%a>0˞%128-a,,,,0     � �%p=0     �" �%a˞64  @  ,%p,,0     ,1    � �� ;� �initSheet()�
 �%y,%x,%i� �Remove any missiles	 �%i=68  D  �71  G  	 �%i,,,,0     	 �%i	$! �Remove saucer and player's shot	. �35  #  ,,,,0     	8 �65  A  ,,,,0     	B �Invaders killed	L �%n=0     	V �Initialise speed	` �setSpeed(%d)	j �Initial height of top row	t �%h=32     	~ �%y=0     �4    	� �Set anchor for each row	� �%a(y)=%y*7	�6 �%a(y),32     ,%h+(y*20),%4+(y*2),1    ,�000     	� �%x=1    �6    	� �Set remaining row sprites	�8 �%�{-(a(y)+x)},%x*20,0     ,0     ,1    ,�110    	� �%x	� ��:�.2~L���,0      	� �%y	� �%y=0     �4    	�% �Set auto-movement on anchor sprites	�[ ��%a(y),�8    �,%h+(y*20)�%h+(y*20)+8�8    �,%4+(y*2)�%5+(y*2),�01    ,%5*s,%(5-y)*s
 6 �Record leftmost/rightmost positions and mark enabled

- �%l(y)=0     :�%r(y)=6    :�%e(y)=1    
 �%y
0 �Record overall left/right/top/bottom positions
( �%l=0     :�%r=6    
2 �%t=0     :�%b=4    
< �updateMovement()
F �
P ;
Z �initGame()
d ;
n �%i
x �
� �Score
� �%z=0     
� �score(%z)
� �Player
� �%p=0     
�' �64  @  ,%p,240  �  ,0     ,1    
� �Lives
� �%a=3    
� �%i=1    �%a-1
�* �%128-i,%(i-1)*20,0     ,0     ,1    
� �%i
� �Show player & lives
� �� �initSheet() � ;" �initSprites(), ��:��6 �"basicInvaders.spr"�12    @ ��12    J �T ;^ �main()h �keyr �initSprites()| �ctrls=1    � �� ��:��� �Use batching mode� ��� �0     :�7    :�0     :�� ��1    :��1    �) �23658  j\ ,0     :�turn off CAPS LOCK�; ��0     ,6    ;�6    ;�1    ;" NextBASIC Invaders "�K ��4    ,0     ;"Press ";�1    ;"K";�0     ;" for keys (O, P, SPACE)"�J ��6    ,0     ;"Press ";�1    ;"J";�0     ;" for Kempston joystick"�a ��12    ,0     ;"Press ";�1    ;"0";�0     ;" to ";�1    ;"9";�0     ;" for difficulty"�5 ��13    ,0     ;"to start (0=easiest, 9=hardest)"� �setInput(ctrls) � �#0     �key/ �key=�"k"˓setInput(1    ):�.5�    ,0     &/ �key=�"j"˓setInput(2    ):�.5�    ,0     0 �%d=key-�"0": ��%d�9D �.5�    ,%2*dN �initGame()X �playGame()b
 ��0     l �v ;� �setInput(l)�
 �%i,%n,t$�	 �ctrls=l� �� �%n=1    �l� �t$� �%i=0     �2    � �%i(i),%k(i),%v(i)� �%i� �%n�+ ��8    ,0     ;"Controls: ";�1    ;t$� �� ;` �"KEYBOARD",57342  �� ,1    ,0     ,57342  �� ,2    ,0     ,32766  � ,1    ,0     Y �"JOYSTICK",31    ,1    ,1    ,31    ,2    ,2    ,31    ,16    ,16    ; �"basicInvaders.bas"�0     :.bas2txt -s basicInvaders.bas