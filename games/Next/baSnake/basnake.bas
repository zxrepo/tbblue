PLUS3DOS �+   b+ b+                                                                                                         �  �***********************  �*    baSnake 3.0.1    *  �*  ZX Spectrum Next   *  �* Marco Varesio 2019  *  �***********************  �TRB = 7     :��2      �5000  � :�2800  �
  	 �900  �  
 �*** MAIN MENU ***  �HI = 0       �1500  �   � . �M(22    , 32     ):�S(704  � , 2    )  �0     :�5    :�4    :�  �1600  @   �SC = 0      # �T = 1    :�H = 1     (? �S(1    , 1    ) = 11    :�S(1    , 2    ) = 8     <2 �Y = S(1    , 1    ):�X = S(1    , 2    ) F �D = 4    :�G = 4     P, �FX = -1    :�FY = -1    :�FD = 0      Q, �MX = -1    :�MY = -1    :�MR = 0      Z: �#1    ; �1    , 0     ; "Score: "; SC, "High: "; HI d �*** MAIN GAME LOOP *** n+ �F =�23672  x\ :�G = 0      ��1000  �  �+ �D = 1     ��Y = Y - 1     :�270    �+ �D = 2     ��Y = Y + 1     :�270   + �D = 3     ��X = X - 1     :�270   	+ �D = 4     ��X = X + 1     :�270   ( �Y < 0      ��Y = 21     :�290  " ( �Y > 21     ��Y = 0      :�290  " ( �X < 0      ��X = 31     :�290  " ( �X > 31     ��X = 0      :�290  " " �2500  �	 , �X�FX �Y�FY ��400  � 6Y �G = G + 3    :�0     , 0     , 0     , 0     , 0     :�FX = -1    :�HIDE APPLE@Y �FD > 16    ��SC = SC + 5    :��FD > 8    ��SC = SC + 10  
  :��SC = SC + 1    J: �#1    ; �1    , 0     ; "Score: "; SC, "High: "; HI�	 �0     � �*** Draw new snake head ***�+ ��S(H, 1    ), S(H, 2    ); �144  �  �. �H = H + 1    :�H = 705   � ��H = 1    �& �S(H, 1    ) = Y:�S(H, 2    ) = X�+ ��S(H, 1    ), S(H, 2    ); �145  �  � �G > 0      ��490   � � �*** Delete snake tail ***�( �TY = S(T, 1    ):�TX = S(T, 2    )� ��TY, TX; " "�) �M(TY + 1    , TX + 1    ) = 0     �. �T = T + 1    :�T = 705   � ��T = 1    � �BEEP .008, -20� �500  � � �G = G - 1    �% �G = 2     ��.04|#�
=, -10   
  �% �G = 1     ��.04|#�
=, -20     �# �G = 0      ��.04|#�
=, -5    � �MV = M(Y+1    , X+1    )�5 �MV = 1     ��M$ = " You bit yourself ":�700  � �5 �MV = 2     ��M$ = " You hit the wall ":�700  � �9 �MV = 3     ��M$ = " The mongoose bit you ":�700  � �# �M(Y+1    , X+1    ) = 1    N �4000  � X �100  d  � �*** GAME OVER ***�V �I=0     �1    :�I, 0     , 0     , 0     , 0     :�I:�HIDE APPLE AND MONGOOSE�	 �3    � �I=H� ��! �C=144  �  :�I = H��C=147  �  �a �I = H�S(I, 1    )�S(H, 1    )�S(I, 2    )�S(H, 2    )���S(I, 1    ), S(I, 2    );�C� �I�T� �I=I-1    � �I = 0     ��I = 704  � �	 �1    �
 ��0     *	 �1    + �I = 6     �15    ,1 ��I, 0     ; "                                "- �I. �6    :�2    :�7    /, ��9  	  , (32      - �(M$)) / 2    ; M$4 �6    :�1    5$ ��7    , 10  
  ; " GAME OVER! "9 �0     :�5    :�1    > �SC�HI ��850  R H	 �HI = SCI( �M$ = " New high score : "+ �(HI) + " "M, ��11    , �((32     -�(M$))/2    ); M$R �1    :�7    f# �I = 15     �-30     �-2    g �.05|L���, Ih �IkV ��13    , 1    ; "PRESS "; :�1     :�"M"; :�0      :�" TO RETURN TO MAIN MENU"l6 ��14    , 1    ; "OR ANY OTHER KEY TO PLAY AGAIN"p �K$ = �u �K$ = ""��880  p z �K$ = "M"�K$ = "m"��10  
  
 �15    � �*** UDGs ***� �903  � �/ �I = 0      �31    :�L:�65368  X� +I, L:�I�d �60  <  , 66  B  , 129  �  , 129  �  , 129  �  , 129  �  , 66  B  , 60  <  :�SNAKE BODY 144�d �60  <  , 66  B  , 165  �  , 129  �  , 165  �  , 153  �  , 66  B  , 60  <  :�SNAKE HEAD 145�Y �4    , 4    , 4    , 255  �  , 64  @  , 64  @  , 64  @  , 255  �  :�WALL 146�c �60  <  , 66  B  , 165  �  , 129  �  , 129  �  , 153  �  , 66  B  , 60  <  :�SNAKE SAD 147� �� �*** APPLE ROUTINE ***� �APPLE NOT YET FALLEN � �FX�-1     ��1100  L �E �FX = �(�*32     ):�FY = �(�*22    ):�FD = 40  (  +�(�*30    )�H �M(FY + 1    , FX + 1    )�0      ��FX = -1     :�FD = 0     :�P �0     , FX*8    +32     , FY*8    +32     , 0     , 1    :�RED APPLE �L �APPLE ALREADY FALLENQ �FD = FD - 1    Ve �FD = 8     ˞0     , FX*8    +32     , FY*8    +32     , 2    , 1     :�:�ROTTEN APPLEWf �FD = 16     ˞0     , FX*8    +32     , FY*8    +32     , 1    , 1     :�:�YELLOW APPLE[W �FD = 0      ˞0     , 0     , 0     , 0     , 0     :�FX = -1    :�HIDE APPLEj �� �0     :�0     :��Q �I=0     �3    :�I+2    ,120  x  +16    *I,32     ,I+4    ,1    :�I�/ �7    :��1    ,26    ; "v. 3.0":�5    �j �"Guide the snake "; :�4    :��145  �  ; �144  �  ; �144  �  ; �144  �  ; :�5    :�" through the"�P �"garden, eating the apples   that":�0     ,240  �  ,56  8  ,0     ,1    �$ �"fall from the tree,  before they"�q �"rot. Avoid the walls "; :�2    :�6    :��146  �  ; �146  �  ; �146  �  ; :�0     :�5    :�" and the"�@ �"mongoose   .":�1    , 104  h  , 80  P  , 3    , 1    � ��+ �7    :�"There are 8 different gardens:"�/ �6    :�"press key from "; :�1     :�"1"; �+ �0     :�" to "; :�1    :�"8";:�0     � �" to choose."� �� �3050  � �D �6    :�"Press "; :�1    :�"S"; :�0      :�" to change speed."�0 �7    :�:�"Snake controls:":�6    :�1    �) �"Q"; :�0     :�" OR "; :�1    :�"UP"�+ �"A"; :�0     :�" OR "; :�1    :�"DOWN"�+ �"O"; :�0     :�" OR "; :�1    :�"LEFT"�, �"P"; :�0     :�" OR "; :�1    :�"RIGHT"� �0     :��6 �5    :�"Check out my other retro stuff @":�7    �$ �"https://retrobits.altervista.org"�A �#1    ; �0     , 0     ; "   https://retrobits.itch.io    "�. �#1    ; "Enjoy!     Marco 'Pulce' Varesio" �L$ = � �L$�"1"�L$�"8"��1570   "  �L$ = "S"�L$ = "s"��3100    �1550   "; �I=0     �63  ?  :�I,0     ,0     ,0     ,0     :�I , �@ �*** DRAW SELECTED GARDEN ***A �L$ = "1"��1700  � B �L$ = "2"��2000  � C �L$ = "3"��2050   D �L$ = "4"��2010  � E �L$ = "5"��2020  � F �L$ = "6"��2030  � G �L$ = "7"��2080    H �L$ = "8"��2090  * J �2    :�6    T �B^ �K = 1     �Bh �MINY:�MINX:�MAXY:�MAXXr �I = MINY �MAXYs �J = MINX �MAXX| ��I, J; �146  �  �# �M(I+1    , J+1    ) = 2    � �J� �I� �K�" �I = -15     �15     �2    � �.05|L���, I� �I�	 �4    l ��	 �4    �% �0     , 0     , 0     , 31    �' �21    , 0     , 21    , 31    �% �0     , 0     , 21    , 0     �' �0     , 31    , 21    , 31    �	 �8    �$ �0     , 7    , 9  	  , 7    �& �5    , 21    , 5    , 31    �( �11    , 23    , 21    , 23    �& �16    , 0     , 16    , 9  	  �$ �0     , 8    , 9  	  , 8    �& �6    , 21    , 6    , 31    �( �11    , 22    , 21    , 22    �& �15    , 0     , 15    , 9  	  �	 �4    �% �6    , 7    , 7    , 24    �' �16    , 7    , 17    , 24    �% �9  	  , 6    , 14    , 7    �' �9  	  , 24    , 14    , 25    �	 �4    �% �0     , 4    , 2    , 27    �' �19    , 4    , 21    , 27    �% �0     , 0     , 21    , 3    �' �0     , 28    , 21    , 31    	 �8    % �0     , 0     , 0     , 31    ' �21    , 0     , 21    , 31    % �9  	  , 3    , 9  	  , 28    ' �13    , 3    , 13    , 28    $ �1    , 0     , 8    , 0     & �1    , 31    , 8    , 31    	& �14    , 0     , 20    , 0     
( �14    , 31    , 20    , 31     	 �8    !( �13    , 27    , 17    , 27    "( �17    , 16    , 17    , 26    #$ �4    , 4    , 8    , 4    $% �4    , 5    , 4    , 15    %( �13    , 25    , 15    , 25    &( �15    , 16    , 15    , 24    '$ �6    , 6    , 8    , 6    (% �6    , 7    , 6    , 15    *
 �11    +% �0     , 0     , 0     , 14    ,& �0     , 17    , 0     , 31    -' �21    , 0     , 21    , 14    .( �21    , 17    , 21    , 31    /% �5    , 3    , 5    , 28    0' �16    , 3    , 16    , 28    1$ �1    , 0     , 9  	  , 0     2& �12    , 0     , 20    , 0     3& �1    , 31    , 9  	  , 31    4( �12    , 31    , 20    , 31    5( �10  
  , 15    , 11    , 16    	� �*** MONGOOSE ROUTINE ***	�0 �F�0     �F�64  @  �F�128  �  �F�192  �  ��	� �MX = -1     ��2600  (
 	� �MR = �	� �MR > .6 ������	�< �1    , 0     , 0     , 0     , 0     :�HIDE MONGOOSE	�) �M(MY + 1    , MX + 1    ) = 0     	� �MX = -1    
 �
( �MR = �
- �MR > .7 �3333��
2( �MX = �(�*32     ):�MY = �(�*22    )
7: �MX = S(H, 2    ) �MY = S(H, 1    ) ��MX = -1    :�
<9 �M(MY + 1    , MX + 1    )�0      ��MX = -1    :�
AT �1    , MX*8    +32     , MY*8    +32     , 3    , 1    :�DRAW MONGOOSE
F) �M(MY + 1    , MX + 1    ) = 3    
� �
�0 �*** WELCOME (LOADING SCREEN & MUSIC INTRO) ***
�
 ��0     
�" �0     :�0     :�POKE 23739,244# �:�2    ,1    :�"basnake.nxi"�V �5    :�26    :��23    ,0     ;"  ";�127    ;"2017-2019 marco's retrobits  "	5 ��0     ,0     ;"baSnake 3.0 for ZX Spectrum NEXT"$ ��0     :�OUT 9275, 7: OUT 9531, 0 �a$="UX5000T60O5W3#FED#Cbab#C" �b$="UX5000T60O3W6Dab#fgdga" �c$="" �d$="" �e$="UX2500T60O3W3Dab#fgdga"& �f$="UX2500O4W6N3D#FAG#FD#FEDbDAGBAG" �g$="" �h$="" �i$="UX5000T60O5W3D#Cbag#fge" �a$,b$,c$,d$,e$,f$,g$,h$,i$"$ ��2    :�OUT 9275, 7: OUT 9531, 2,6 ��0     ,0     ; "   PRESS  ANY  KEY  TO  START   "6	 �0     @ �2    ,0     :�0     J �� �*** PRINT TURBO MODE ***�	 �7    �% ��11    , 0     ; "Turbo mode: ";�	 �5    �( �TRB = 11    ��"ANDANTE ":�3070  � �( �TRB = 9   	  ��"MODERATO":�3070  � �( �TRB = 7     ��"ALLEGRO ":�3070  � �( �TRB = 5     ��"VIVACE  ":�3070  � �( �TRB = 3     ��"PRESTO  ":�3070  � �	 �7     � �*** CHANGE TURBO MODE ***! �TRB = TRB - 2    &  �TRB = 1     ��TRB = 11    + �3050  � 0 �300  , : �� �*** INPUT ***� �DT = D
 �K =�(�) rU �(K = 11    �K = 81  Q  �K = 113  q  ) �(D = 3    �D = 4    ) ��DT = 1    |T �(K = 10  
  �K = 65  A  �K = 97  a  ) �(D = 3    �D = 4    ) ��DT = 2    �T �(K = 8    �K = 79  O  �K = 111  o  ) �(D = 1    �D = 2    ) ��DT = 3    �T �(K = 9  	  �K = 80  P  �K = 112  p  ) �(D = 1    �D = 2    ) ��DT = 4    �' ��(�23672   x\ - F) < TRB��4100   � �D = DT� ��' �*** SPRITES LOAD & INITIALIZATION ***� �"basnake.spr"�12    � ��12    � ���
 ��1    �
 ��0     � �