PLUS3DOS _.   �- ��-                                                                                                         � 
o �h(h$=16*$)=16    *(�h$-48  0  -(7    �h$(1    )>"9"))+�h$(2    )-48  0  -(7    �h$(2    )>"9") / �n$(h=�(hh)=�(h+48  0  +(7    �h>9  	  )) > �h$(h=�n$h)=�n$(�(h/16    ))+�n$(h-16    *�(h/16    )) (0 %s=%�7&3:��3    :attrp=%�23693:bordcr=%�23624 29 ���23693  �\ ,attrp:�23624  H\ ,bordcr:��:��:��%s:��:� < x=�5808  �  F � P$ �"c:/nextzxos/usr0.bin"�40960   �  Z� hwm=0     : hwa=0     : hwt=0     : hw1=0     : hw2=0     : hwf=0     : hwx=0     : hwo=0     : hwg=0     : hws=0     : hwk=0     : hwi=1    : hwu=1    : hwp=1    : hwprn=1     d. mn=0     : mp=0     : m4=0     : b=0      n �controlDefaults() x �decodeOpts(f$)�k,o$ � �k=0     �adj=1     �( �adj�k=0     :�setScheme():�showmenu() � � �  �:�adj �o     ss=%s:��17    ,27    ;�1    ;(" 3"�ss=0     )+(" 7"�ss=1    )+("14"�ss=2    )+("28"�ss=3    ) �    �#0     �k �  ��1     �&  �k=�"a"�k=�"A"˓hwmenu():�showmenu() �,  �k=�"j"�k=�"J"˓editControls():�showmenu() �  �k=�"s"�k=�"S"�%s=%(s+1)&3 �  �k=�"1"˓prepare():�� �M  �k=�"0"˓prepare():��:�:�9275  ;$ ,36  $  :�40960   � ,b:�x=�40961  �  �`  �k=�"4"�m4=1    :�prepare():��:�48  0  :�9275  ;$ ,36  $  :�40960   � ,b:�x=�40961  � r  �k=�"c"�k=�"C"�m4=1    : b=1    :�prepare():��:�48  0  :�9275  ;$ ,36  $  :�40960   � ,b:�x=�40961  � L  �k=�"n"�k=�"N"�mn=1    :�prepare():��:�"t:":�41984   � ,b:��41985  � �  �k=�"p"�k=�"P"�mp=1    :�prepare():��:�:�9275  ;$ ,3    :�9531  ;% ,192  �  :�9275  ;$ ,8    :�9531  ;% ,64  @  +�9531  ;% :�9275  ;$ ,36  $  :�40960   � ,b:�x=�40961  � "
 ��0     , ;6 �showmenu()@  �J  �showBanner("TZX Loader")T4  ��0     ,0     ;"To begin loading, select mode:"^6  ��2    ,3    ;�1    ;"1";�0     ;" 128K mode"h6  ��4    ,3    ;�1    ;"0";�0     ;" USR0 mode"r5  ��6    ,3    ;�1    ;"4";�0     ;" 48K mode"|J  ��8    ,3    ;�1    ;"C";�0     ;" 48K CODE mode (LOAD """"CODE)"�>  ��10  
  ,3    ;�1    ;"P";�0     ;" Pentagon timings"�:  ��12    ,3    ;�1    ;"N";�0     ;" Next/+3 mode"�  ��14    ,0     ;"Options:"�E  ��15    ,3    ;�1    ;"A";�0     ;"dvanced hardware options"�=  ��16    ,3    ;�1    ;"J";�0     ;"oystick controls"�I  ��17    ,3    ;�1    ;"S";�0     ;"elect load/play speed:   MHz"  ��18    ,3    ;�1    ;"NOTE:";�0     ;" TZX loading requires an";�19    ,9  	  ;"accelerated Next (with";�20    ,9  	  ;"Pi Zero installed)"� �� ;� �prepare()�  �saveOpts()�  �initpi()�  ��mn˓sethw()  �setControls()(  �23693  �\ ,attrp:�23624  H\ ,bordcr  ��:��&  �0  �:  ��%sD  �%$5c76,0     N �X ;b
 �initpi()l  �v    ��Z    �5434  : ,64  @  :�9275  ;$ ,162  �  :�9531  ;% ,211  �  :.pisend -q:�5    :��
  �%�127=0�    �piError()�  ��0     �   .$ pisend f$��  �100  d  : g$="-c printf ""\x14\x57\x03\xAE\x06\x08\x00\x00\x02\x00\x00\xFF\xFF"" > /ram/tzxfix.bin ; cat """+f$+""" /ram/tzxfix.bin > /ram/file.tzx"�   .$ pisend g$�  �50  2  �.   g$="-c tape2wav /ram/file.tzx /ram/out.wav"�   .$ pisend g$�  �200  �  �	   v=%�17�  �x=0     �v:�hertz:�x$   ss=%1�s:�ss=8    �ss=6.57�R=p�.   g$="-c play -r"+�(ss*hertz)+" /ram/out.wav"  �100  d      .$ pisend g$:*  �162  �  ,211  �  4 �> ;H �piError()R�  �:��0     ,0     ;"Error communicating with Pi..."''"Press ";�1    ;"R";�0     ;" in a few moments"'"to retry"''"Press any other key to exit"\  �#0     �kf  �k=�"r"�k=�"R"˒:��p ;z	 �sethw()�6  �130  �  ,218  �  +(32     *hwm)+(4    *mp)+hwt�3  �131  �  ,(32     *hwu)+(20    *hwi)+11    �}  �132  �  ,(128  �  *hws)+(64  @  *hwg)+(32     *hwo)+(16    *hwx)+(8    *hwf)+(4    *hw2)+(2    *hw1)+(hwa��m4)�+  �133  �  ,(4    *mp)+(2    *hwm)+hwp�"   %k=hwk:�8    ,%�8&@11111110|k�%   %p=hwprn:�%$5b68,%�$5b68&$ef|(p�4)�  �184  �  ,%p^1�1�  �216  �  ,0     � �� ;�
 �hwmenu()�  ��0  �"Toggle options then press ";�1    ;"SPACE"F  �'"NOTE: All hardware options are"'"always enabled in Next/+3 mode.""  �'"D";�1    ;"M";�0     ;"A:"/  ��1    ;"A";�0     ;"Y sound in 48K mode:"$)  ��1    ;"T";�0     ;"imex graphics:".2  �"DAC Soundrive mode ";�1    ;"1";�0     ;":"82  �"DAC Soundrive mode ";�1    ;"2";�0     ;":"B-  �"DAC Pro";�1    ;"f";�0     ;"i covox:"L.  �"DAC Stereo covo";�1    ;"x";�0     ;":"V.  �"DAC Pentag";�1    ;"o";�0     ;"n/atm:"`*  �"DAC ";�1    ;"G";�0     ;"S covox:"j*  �"DAC ";�1    ;"S";�0     ;"pecDrum:"t*  �'�1    ;"K";�0     ;"eyboard issue:"~-  �"Pri";�1    ;"n";�0     ;"ter support:"�)  �'"UART & ";�1    ;"i";�0     ;"2c:"�#  �"Mo";�1    ;"u";�0     ;"se:"�%  �"ULA";�1    ;"p";�0     ;"lus:"�  ��8    ��5    ,28    ;�1    ;("ON "�hwm)+("OFF"��hwm)�8    ��6    ,28    ;�1    ;("ON "�hwa)+("OFF"��hwa)�8    ��7    ,28    ;�1    ;("ON "�hwt)+("OFF"��hwt)�8    ��8    ,28    ;�1    ;("ON "�hw1)+("OFF"��hw1)�8    ��9  	  ,28    ;�1    ;("ON "�hw2)+("OFF"��hw2)�9    ��10  
  ,28    ;�1    ;("ON "�hwf)+("OFF"��hwf)�9    ��11    ,28    ;�1    ;("ON "�hwx)+("OFF"��hwx)�9    ��12    ,28    ;�1    ;("ON "�hwo)+("OFF"��hwo) 9    ��13    ,28    ;�1    ;("ON "�hwg)+("OFF"��hwg)
9    ��14    ,28    ;�1    ;("ON "�hws)+("OFF"��hws)9    ��16    ,28    ;�1    ;(" 2 "�hwk)+(" 3 "��hwk)=    ��17    ,28    ;�1    ;("ON "��hwprn)+("OFF"�hwprn)(9    ��19    ,28    ;�1    ;("ON "�hwi)+("OFF"��hwi)29    ��20    ,28    ;�1    ;("ON "�hwu)+("OFF"��hwu)<9    ��21    ,28    ;�1    ;("ON "�hwp)+("OFF"��hwp)F    �#0     �kP    �k=�"m"�k=�"M"�hwm=�hwmZ    �k=�"a"�k=�"A"�hwa=�hwad    �k=�"t"�k=�"T"�hwt=�hwtn    �k=�"1"�hw1=�hw1x    �k=�"2"�hw2=�hw2�    �k=�"f"�k=�"F"�hwf=�hwf�    �k=�"x"�k=�"X"�hwx=�hwx�    �k=�"o"�k=�"O"�hwo=�hwo�    �k=�"g"�k=�"G"�hwg=�hwg�    �k=�"s"�k=�"S"�hws=�hws�    �k=�"n"�k=�"N"�hwprn=�hwprn�    �k=�"i"�k=�"I"�hwi=�hwi�    �k=�"u"�k=�"U"�hwu=�hwu�    �k=�"p"�k=�"P"�hwp=�hwp�    �k=�"k"�k=�"K"�hwk=�hwk�  ��k=32     � �� ; �decodeOpts(f$)<  ��f$<5    �f$(�f$-4    ̱f$-3    )�"}."˒=0     ,""   optlen =�h(f$(�f$-6    �))"2  �optlen<19    �optlenȱf$-4    ˒=0     ,"",0   o$=f$(�f$-4    -optlen+1    ̱f$-4    )6%  �o$(�6    )�"{LOAD="˒=0     ,""@.   k=�o$(7    ):%s=�o$(8    ):%s=%(s-48)&3J   %d=�h(o$(9  	  �))TX   hws=%d�7&1:hwg=%d�6&1:hwo=%d�5&1:hwx=%d�4&1:hwf=%d�3&1:hw2=%d�2&1:hw1=%d�1&1:hwa=%d&1^   %d=�h(o$(11    �))hX   hwm=%d�7&1:hwt=%d�6&1:hwk=%d�5&1:hwprn=%d�4&1:hwi=%d�3&1:hwu=%d�2&1:hwp=%d�1&1:b=%d&1r   %d=�h(o$(15    �))|   joyl=%d�4&15:joyr=%d&15�   n=17    �U  �joyl=8    �optlen�(n+10  
  +3    )�a$(1    )=o$(n�n+10  
  ):n=n+11    �H  �joyr=8    �optlen�(n+10  
  +3    )�a$(2    )=o$(n�n+10  
  )� �=k,o$� ;� �saveOpts()�   ss=%s�p   o0=(hws*128  �  )+(hwg*64  @  )+(hwo*32     )+(hwx*16    )+(hwf*8    )+(hw2*4    )+(hw1*2    )+hwa�p   o1=(hwm*128  �  )+(hwt*64  @  )+(hwk*32     )+(hwprn*16    )+(hwi*8    )+(hwu*4    )+(hwp*2    )+b�   o2=0     �   o3=(joyl*16    )+joyr�@   n$="{LOAD="+�k+�(48  0  +ss)+�h$(o0)+�h$(o1)+�h$(o2)+�h$(o3)�!  �joyl=8    �n$=n$+a$(1    )!  �joyr=8    �n$=n$+a$(2    )   n$=n$+�h$(�n$+3    )+"}"�  ���:��1    ;"Error saving options to filename"''�0     ;"Press any key to load anyway"'"with selected options":�#0     �x:f$=g$:�&7  �n$�o$�g$=f$:f$=f$(̱f$-�o$-4    )+n$+".tzx":�g$�f$0 �: ;D �editControls()N  �X1  �"Select controls then press ";�1    ;"SPACE"b3  �'�5    ;�1    ;"L";�0     ;"eft  joystick:"l2  ��5    ;�1    ;"R";�0     ;"ight joystick:"v[  �'"Keyjoy setup:"'�21    ;"L";�1    ;"e";�0     ;"ft  R";�1    ;"i";�0     ;"ght"��  �'�12    ;"Up"'�12    ;"Down"'�12    ;"Left"'�12    ;"Right"'�12    ;"Fire/B"'�12    ;"Fire 2/C"'�12    ;"Start"'�12    ;"Button A"'�12    ;"Button X"'�12    ;"Button Y"'�12    ;"Button Z"�S  ��20    ,1    ;"Keys available for keyjoy:"'" A..Z 0..9 ENTER SPACE SYM CAPS"�  �n=1    �11    �A    �controlDesc(a$(1    ,n))�x$:�controlDesc(a$(2    ,n))�y$�2    ��7    +n,21    ;x$;�7    +n,27    ;y$�  �n�  ��J    ��2    ,22    ;j$(joyl+1    );�3    ,22    ;j$(joyr+1    )�    �#0     �k�;    �k=�"l"�k=�"L"�joyl=joyl+1    -(9  	  �joyl=8    )�;    �k=�"r"�k=�"R"�joyr=joyr+1    -(9  	  �joyr=8    )�D    �k=�"e"�k=�"E"˓editKeyjoy(1    ,2    ,2    ):joyl=8    �D    �k=�"i"�k=�"I"˓editKeyjoy(2    ,5    ,2    ):joyr=8    
  ��k=�" " � ;  �editKeyjoy(j,%r,%c)*  �n=1    �11    45    ��7    +n,15    +(j*6    );�1    ;"PRESS">!    �:��%�(65534-(1�(r+8)))&(1�c)H    �getControl()�row,colR(     a$(j,n)=c$(row+1    ,col+1    )\    �controlDesc(a$(j,n))�x$f'    ��7    +n,15    +(j*6    );x$p     %r=row:%c=colz  �n�  �:��%�(65534-(1�(r+8)))&(1�c)� �� ;� �getControl()�  �%r,%c,%i�   %r=-1    �  ��     %r=%r+1&7�     %i=%�(65534-(1�(r+8)))&63�	  ��%i�63�   %c=-1    �  ��     %c=%c+1	  ��%i&(1�c)=0	 �=%r,%c	 ;	$ �controlDesc(x$)	.  �x$�"Z"˒="  "+x$+"  "	8  �x$="e"˒="ENTER"	B  �x$="c"˒="CAPS "	L  �x$="s"˒=" SYM "	V  �x$="_"˒="SPACE"	`	 �="none"	j ;	t �setControls()	~#  �joyl=8    ˓setKeyjoy(1    )	�#  �joyr=8    ˓setKeyjoy(2    )	�	   %j=%�5	�7  �joyl�%x=joyl-1    :%j=%j&@00110111|(x&4�1)|(x&3�6)	�7  �joyr�%x=joyr-1    :%j=%j&@11001101|(x&4�1)|(x&3�4)	�  �5    ,%j	� �	� ;	� �setKeyjoy(j)	�4  �40  (  ,128  �  :�41  )  ,16    *(j-1    )	�  �%n=0     �10  
  	�     n=%o(n)	�     %x=�a$(j,n)
 �    �%x<48�%d=%s(39):��%x�57�%d=%s(x-48):��%x�90�%d=%s(x-55):��%x=101�%d=%s(36):��%x=99�%d=%s(37):��%x=115�%d=%s(38):��%x=95�%d=%s(39):�%d=0     

    �43  +  ,%d
  �%n
 �
( ;
2 �controlDefaults()
<B  �a$(2    ,11    ):�c$(8    ,5    ):�j$(9  	  ,10  
  )
F4   a$(1    )="QAOP_MSeXYZ":a$(2    )=a$(1    )
P.  �n=1    �8    :�c$(n):�m=1    �5    
Z1     %x=�c$(n,m):%i=(n-1    )*8    +m-1    
dt    �%x�57�%s(x-48)=%i:��%x�90�%s(x-55)=%i:��%x=101�%s(36)=%i:��%x=99�%s(37)=%i:��%x=115�%s(38)=%i:��%x=95�%s(39)=%i
n  �m:�n
x!  �%n=0     �10  
  :�%o(n):�%n
�  �n=1    �9  	  :�j$(n):�n
�   joyl=0     :joyr=0     
� �
� ;
� �showBanner(n$)
�L  ��"a",%1,%3,%7,%15,%31,%63,%127,%255,%254,%252,%248,%240,%224,%192,%128,%0
�U  �23693  �\ ,%c(6):��21    ,0     ;(n$+"                          ")(�26    );
�  �23693  �\ ,%c(1):�"�";
�  �23693  �\ ,%c(2):�"�";
�  �23693  �\ ,%c(3):�"�";
�  �23693  �\ ,%c(4):�"�";
�  �23693  �\ ,%c(5):�"�";
�  �23693  �\ ,%c(6):�" ";  �23693  �\ ,%c(0) � ;" �setScheme(),   .editprefs --get-scheme c6
  �0     @  �%n=0     �31    J    ��0     ,%n,%c(n+32)T  �%n^  �23693  �\ ,%c(0)h  �%c(0)�3&7r �| ;�A �"cZXCV","ASDFG","QWERT","12345","09876","POIUY","eLKJH","_sMNB"�$ �%4,%3,%2,%1,%5,%6,%8,%7,%10,%11,%9�_ �"default","Sinclair 2","Kempston 1","Cursor","Sinclair 1","Kempston 2","MD 1","MD 2","Keyjoy"�a �44100  D� ,45000  ȯ ,46406  F� ,47250  �� ,48825  �� ,50400  �� ,51975  � ,42525  � 