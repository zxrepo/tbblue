PLUS3DOS �   !a�!                                                                                                         � 
 �%s=%�7&3:��3      ����%s:��:�  �x=�5808  �  ( � -$ �"c:/nextzxos/usr0.bin"�32768   �  2� �hwm=0     :�hwa=0     :�hwt=0     :�hw1=0     :�hw2=0     :�hwf=0     :�hwx=0     :�hwo=0     :�hwg=0     :�hws=0     :�hwk=0     :�hwv=1    :�hwi=1    :�hwu=1    :�hwp=1     </ �mn=0     :�mp=0     :�m4=0     :�b=0      F �showmenu()  Ku �ss=%s:��16    ,27    ;�1    ;�1    ;(" 3"�ss=0     )+(" 7"�ss=1    )+("14"�ss=2    )+("28"�ss=3    ) P �#0     �k Z �k=�"a"�k=�"A"˓hwmenu():�%70 _! �k=�"s"�k=�"S"��%s=%(s+1)&3:�%75 d! �k=�"1"�k=13    ˓prepare():�� n# �k=�"0"˓prepare():��:�:�155  �   x7 �k=�"4"��m4=1    :�prepare():��:�48  0  :�155  �   }I �k=�"c"�k=�"C"��m4=1    :�b=1    :�prepare():��:�48  0  :�155  �   �: �k=�"n"�k=�"N"��mn=1    :�prepare():��:�"t:":�160  �   �� �k=�"p"�k=�"P"��mp=1    :�prepare():��:�:�9275  ;$ ,3    :�9531  ;% ,192  �  :�9275  ;$ ,8    :�9531  ;% ,64  @  +�9531  ;% :�155  �   � �%80 � �32768   � ,b:�x=�32769  �  � �65367   W�  � �""  � �showmenu() �K ��"a",%1,%3,%7,%15,%31,%63,%127,%255,%254,%252,%248,%240,%224,%192,%128,%0 �	 ��:��:�� �/ �0     :�7    :�0     :�0     :�7    :� ܄ ��21    ,0     ;�1    ;�1    ;"TZX Loader                ";�2    ;"�";�6    ;"�";�4    ;"�";�5    ;"�";�0     ;"��" �) ��0     ,0     ;"Select mode to load:" �G ��2    ,3    ;�1    ;�1    ;"1";�0     ;�0     ;" 128K mode" �G ��4    ,3    ;�1    ;�1    ;"0";�0     ;�0     ;" USR0 mode"F ��6    ,3    ;�1    ;�1    ;"4";�0     ;�0     ;" 48K mode"	[ ��8    ,3    ;�1    ;�1    ;"C";�0     ;�0     ;" 48K CODE mode (LOAD """"CODE)"O ��10  
  ,3    ;�1    ;�1    ;"P";�0     ;�0     ;" Pentagon timings"K ��12    ,3    ;�1    ;�1    ;"N";�0     ;�0     ;" Next/+3 mode"" ��14    ,0     ;"Options:",V ��15    ,3    ;�1    ;�1    ;"A";�0     ;�0     ;"dvanced hardware options"1Z ��16    ,3    ;�1    ;�1    ;"S";�0     ;�0     ;"elect load/play speed:   MHz"3� ��18    ,3    ;�1    ;�1    ;"NOTE:";�0     ;�0     ;" TZX loading requires an";�19    ,9  	  ;"accelerated Next (with";�20    ,9  	  ;"Pi Zero installed)"6 �@ �prepare()J
 �initpi()T ��mn˓sethw()^ �h ��%sm �%$5c76,0     r �|
 �initpi()� ��  .tapein -c�W �5434  : ,64  @  :�9275  ;$ ,162  �  :�9531  ;% ,211  �  :.pisend -q:�5    :�� �%�127=0��%540�  .$ pisend f$�� �100  d  :�g$="-c printf ""\x14\x57\x03\xAE\x06\x08\x00\x00\x02\x00\x00\xFF\xFF"" > /ram/tzxfix.bin ; cat """+f$+""" /ram/tzxfix.bin > /ram/file.tzx"�  .$ pisend g$�
 �50  2  �- �g$="-c tape2wav /ram/file.tzx /ram/out.wav"�  .$ pisend g$� �200  �  �< �ss=%1�s:�g$="-c play -r"+�(ss*44100  D� )+" /ram/out.wav"�  .$ pisend g$: �162  �  ,211  �   �� �:��0     ,0     ;"Error communicating with Pi..."''"Press ";�1    ;�1    ;"R";�0     ;�0     ;" in a few moments"'"to retry"''"Press any other key to exit"& �#0     �k0 �k=�"r"�k=�"R"��%10:��:	 �sethw()D5 �130  �  ,218  �  +(32     *hwm)+(4    *mp)+hwtN? �131  �  ,(32     *hwu)+(20    *hwi)+(9  	  *hwv)+2    X| �132  �  ,(128  �  *hws)+(64  @  *hwg)+(32     *hwo)+(16    *hwx)+(8    *hwf)+(4    *hw2)+(2    *hw1)+(hwa��m4)b �133  �  ,254  �  +hwpl! �%k=hwk:�8    ,%�8&@11111110|kv ��
 �hwmenu()� ��8 �"Toggle options then press ";�1    ;�1    ;"SPACE"�E �'"NOTE: All hardware options are"'"always enabled in Next/+3 mode."�3 �'"D";�1    ;�1    ;"M";�0     ;�0     ;"A:"�@ ��1    ;�1    ;"A";�0     ;�0     ;"Y sound in 48K mode:"�: ��1    ;�1    ;"T";�0     ;�0     ;"imex graphics:"�C �"DAC Soundrive mode ";�1    ;�1    ;"1";�0     ;�0     ;":"�C �"DAC Soundrive mode ";�1    ;�1    ;"2";�0     ;�0     ;":"�> �"DAC Pro";�1    ;�1    ;"f";�0     ;�0     ;"i covox:"�? �"DAC Stereo covo";�1    ;�1    ;"x";�0     ;�0     ;":"�? �"DAC Pentag";�1    ;�1    ;"o";�0     ;�0     ;"n/atm:"�; �"DAC ";�1    ;�1    ;"G";�0     ;�0     ;"S covox:"; �"DAC ";�1    ;�1    ;"S";�0     ;�0     ;"pecDrum:"; �'�1    ;�1    ;"K";�0     ;�0     ;"eyboard issue:"< �'"Di";�1    ;�1    ;"v";�0     ;�0     ;"MMC & SPI:" 9 �"UART & ";�1    ;�1    ;"i";�0     ;�0     ;"2c:"*4 �"Mo";�1    ;�1    ;"u";�0     ;�0     ;"se:"46 �"ULA";�1    ;�1    ;"p";�0     ;�0     ;"lus:">> ��5    ,28    ;�1    ;�1    ;("ON "�hwm)+("OFF"��hwm)H> ��6    ,28    ;�1    ;�1    ;("ON "�hwa)+("OFF"��hwa)R> ��7    ,28    ;�1    ;�1    ;("ON "�hwt)+("OFF"��hwt)\> ��8    ,28    ;�1    ;�1    ;("ON "�hw1)+("OFF"��hw1)f> ��9  	  ,28    ;�1    ;�1    ;("ON "�hw2)+("OFF"��hw2)p? ��10  
  ,28    ;�1    ;�1    ;("ON "�hwf)+("OFF"��hwf)z? ��11    ,28    ;�1    ;�1    ;("ON "�hwx)+("OFF"��hwx)�? ��12    ,28    ;�1    ;�1    ;("ON "�hwo)+("OFF"��hwo)�? ��13    ,28    ;�1    ;�1    ;("ON "�hwg)+("OFF"��hwg)�? ��14    ,28    ;�1    ;�1    ;("ON "�hws)+("OFF"��hws)�? ��16    ,28    ;�1    ;�1    ;(" 2 "�hwk)+(" 3 "��hwk)�? ��18    ,28    ;�1    ;�1    ;("ON "�hwv)+("OFF"��hwv)�? ��19    ,28    ;�1    ;�1    ;("ON "�hwi)+("OFF"��hwi)�? ��20    ,28    ;�1    ;�1    ;("ON "�hwu)+("OFF"��hwu)�? ��21    ,28    ;�1    ;�1    ;("ON "�hwp)+("OFF"��hwp)� �#0     �k� �k=�"m"�k=�"M"��hwm=�hwm:�%830� �k=�"a"�k=�"A"��hwa=�hwa:�%830� �k=�"t"�k=�"T"��hwt=�hwt:�%830� �k=�"1"��hw1=�hw1:�%830 �k=�"2"��hw2=�hw2:�%830 �k=�"f"�k=�"F"��hwf=�hwf:�%830 �k=�"x"�k=�"X"��hwx=�hwx:�%830$ �k=�"o"�k=�"O"��hwo=�hwo:�%830. �k=�"g"�k=�"G"��hwg=�hwg:�%8308 �k=�"s"�k=�"S"��hws=�hws:�%830B �k=�"v"�k=�"V"��hwv=�hwv:�%830L �k=�"i"�k=�"I"��hwi=�hwi:�%830V �k=�"u"�k=�"U"��hwu=�hwu:�%830` �k=�"p"�k=�"P"��hwp=�hwp:�%830j �k=�"k"�k=�"K"��hwk=�hwk:�%830t �k�32     ��%980~ �' �"c:\nextzxos\tzxload.bas"