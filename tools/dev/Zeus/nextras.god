PLUS3DOS :  � ��d                                                                                                         7��; NEXT Z80n extensions ��; Use after �237 e.g. ��; �237,MUL for MUL �,� ��;  �SWAPNIB �35 
�MIRROR
�36 �TEST
�39;+data byte �BSLA
�40 (�BSRA
�41 2�BSRL
�42 <�BSRF
�43 F�BRLC
�44 P�MUL
�48 Z�ADDHL_A �49 d�ADDDE_A �50 n�ADDBC_A �51 x�ADDHL_W �52 ;Suffix W ��ADDDE_W �53 ;after DEFB ��ADDBC_W �54 ;e.g.�W ��PUSH_W
�138;+HIGH,LOW ��OUTINB
�144 ��NEXTREG �145;Suffix �,N ��NEXTREGA �146;Suffix N ��PIXELDN �147 ��PIXELAD �148 ��SETAE
�149 ��JP_BC
�151 ��LDIX
�164 ��LDWS
�165 ��LDDX
�172 �LDIRX
�180 �LDPIRX
�183 �LDDRX
�188 "�NEXTX
�237 ;Prefix ED ,�; 6�; EXAMPLES @�; J�
� 44444 T�
�NEXTX,NEXTREG ^�
�18,32 h�
�NEXTX,NEXTREGA r�
�19 |�
� ��TEST1 �
�,516;�=2 �=4 ��
�NEXTX,MUL;�=8 ��
�NEXTX,ADDDE_W ��
�0-8 ��
ɔ ;Return 8-8 ��
�
RETBC ��; ��;PUSH_W expects high byte ��;first: to �#ABCD use ��
�NEXTX,PUSH_W ��
�#CDAB ; or ��TEST2 �NEXTX,PUSH_W ��
�#AB,#CD �RETBC � �
;=43981 �
� �;THANKS Anthony Ball & Ped ��