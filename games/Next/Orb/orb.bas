PLUS3DOS -   �8��                                                                                                         � 
	 �setup()  �menu()  �game() (
 �20     b ��:��0      c �� �game()�> �:�0     :��:��18    ,0     ,16    ,16    :��17    �, �i=0     �185  �  :�18    �i,6    :�i3 �16    ,11    �0     ,0     �0     ,1    ( ��0     ,0     ;��11000011  �  ," ",P �%x=7    :�%y=5    :�fr=0     :�face=1    :�delay=0     :�power=0     , �char(%x�4,%y�4,face,fr,10  
  ):��1    K �*** MAIN LOOP ***L) ��<0.02{#�
=��fr=1    :�delay=5    Q( �9275  ;$ ,7    :�9531  ;% ,2    Vb �char(%x�4,%y�4,face,fr,10  
  ):�delay >0     ��delay=delay-1    :�delay=0     ��fr=0     [< ��0     ,0     ;��11000011  �  ;�%$ff;" Power: ";power,,` �k$=�j� �k$="q"˓up():��k$="a"˓down():��k$="o"˓left():��k$="p"˓right():��(k$="m"�k$=" ")�power�4    ˓zap(6    ):�power=power-4    t. �fr=0     :�char(%x�4,%y�4,face,fr,10  
  )~ �getTile(%x,%y)�%t� �%t=5˓dead():�1    �  �%t=7˓zap(8    ):�1110  V � �%t=8˓power():�1110  V � �1110  V � �dead()� �%i=1    �5    �4 �char(%x�4,%y�4,-1    ,1    ,10  
  ):�1    �4 �char(%x�4,%y�4,-1    ,3    ,10  
  ):�1    �3 �char(%x�4,%y�4,1    ,1    ,10  
  ):�1    �3 �char(%x�4,%y�4,1    ,2    ,10  
  ):�1    � �%i ���	 �0     � �� �left()�2 �face=-1    :�s=-1    :�t=0     :�fr=9  	  � �%x>0˓walk()3 �4	 �right()>0 �face=1    :�s=1    :�t=0     :�fr=9  	  H �%x<15˓walk()� �� �up()�$ �s=0     :�t=-1    :�fr=27    � �%y>0˓walk()� �� �down()	# �s=0     :�t=1    :�fr=18    	 �%y<10˓walk()	_ �� �walk()� �start=fr:�end=start+6    � �dropOrb()� �a=%x�4:�b=%y�4� �x=%x:�%x=x+s� �y=%y:�%y=y+t�6 �choosePit():�%m=%f:�%n=%g:�choosePit():�%o=%f:�%p=%g� �%i=0     �7    �( �9275  ;$ ,7    :�9531  ;% ,2    � �a=a+2    *s:�b=b+2    *t� �char(a,b,face,fr,10  
  )�! �fr=fr+1    :�fr=end��fr=start� �%f=%m:�%g=%n:�lowerPit()� �%f=%o:�%g=%p:�lowerPit() �%i � �dropOrb()0 �drawTile(%x,%y,7    ) �� �choosePit()� �%f=%x:�%g=%y:�%d=�(�*4    )�? �%d=0��%f=%x-1:��%d=1��%f=%x+1:��%d=2��%g=%y-1:��%d=3��%g=%y+1� �� �lowerPit(), �%(f=$ffff) | (f=16) | (g=$ffff) | (g=11)˒ �getTile(%f,%g)�%t �%t=5˒  �%t=%t+9:�%t>34��%t=5    % �%t=17��%t=16    * �drawTile(%f,%g,%t)G �H �raisePit()R, �%(f=$ffff) | (f=16) | (g=$ffff) | (g=11)˒\ �getTile(%f,%g)�%tf �%(t>5) & (t<9)˒p �%t=5��%t=33  !  :��%t=%t-9z �drawTile(%f,%g,%t)� �� �zap(t)� �%i=1    �3    �5 �%x>0˓bolt(%(x-1)�4+8,%y�4,�00000001    ,1    )�6 �%x<15˓bolt(%(x+1)�4-8,%y�4,�00001001  	  ,2    )�5 �%y>0˓bolt(%x�4,%(y-1)�4+8,�00000011    ,3    )�6 �%y<10˓bolt(%x�4,%(y+1)�4-8,�00000011    ,4    )�5 �%x>0˓bolt(%(x-1)�4+8,%y�4,�00000101    ,1    )�6 �%x<15˓bolt(%(x+1)�4-8,%y�4,�00001101    ,2    )�5 �%y>0˓bolt(%x�4,%(y-1)�4+8,�00000111    ,3    )�6 �%y<10˓bolt(%x�4,%(y+1)�4-8,�00000111    ,4    )� �%f=%x-1:�%g=%y:�raisePit()� �%f=%x+1:�%g=%y:�raisePit()� �%f=%x:�%g=%y-1:�raisePit()� �%f=%x:�%g=%y+1:�raisePit()� �%i�' �bolt(0     ,0     ,0     ,1    )�' �bolt(0     ,0     ,0     ,2    )�' �bolt(0     ,0     ,0     ,3    )�' �bolt(0     ,0     ,0     ,4    )� �%x>0˓drawTile(%x-1,%y,t)� �%x<15˓drawTile(%x+1,%y,t)� �%y>0˓drawTile(%x,%y-1,t)� �%y<10˓drawTile(%x,%y+1,t)� �drawTile(%x,%y,6    )� ��	 �power()� �power=power+1    � �drawTile(%x,%y,6    )� �X �char(x,y,face,frame,spr)b �f=�00000001    l# �face=1    ��f=f+�00001000    v# �spr,x+32     ,y+44  ,  ,frame,f� �� �bolt(x,y,f,spr)�& �spr,x+32     ,y+48  0  ,17    ,f �  �drawTile(%x,%y,index)* �18    �%x+(y*16),index4 �1    ,1    �%x,%y�%x,%y+1>( �9275  ;$ ,7    :�9531  ;% ,2    � �� �getTile(%x,%y)� �%a=%�18�(x+(y*16))� �=%a @ �menu()A �:�0     :��:��1     E ��16    F% ��18    ,0     ,16    ,16    J �%i=0     �7    �2    T �18    �%i*8,%i U �18    �%i*8+1,%i+1^ �%ih1 �2    ,4    �0     ,0     �0     ,0     r1 �text(5    ,1    ,"TOJAM PRESENTS:",0     )|: �text(5    ,3    ,"A MATT DAVIES PRODUCTION",0     )�: �text(5    ,5    ,"ROTOX(S FIRST ADVENTURE:",0     )�) �text(5    ,8    ,"ORB RUN",1    )�@ �text(0     ,12    ,"HIT FIRE TO SPEND 4 POWER AND",0     )�> �text(0     ,13    ,"DESTROY THE SURROUND VOIDS!",0     )�C �text(0     ,21    ,"QAOP TO MOVE, M OR SPACE TO FIRE",0     )�: �text(0     ,23    ,"PRESS ANY KEY TO START!",1    )�D �x=0     :�y=128  �  :�face=1    :�frame=9  	  :�delay=3    � �char(x,y,face,frame,10  
  )� �i=0     �delay:�i�) �x=x+(2    *face):�frame=frame+1    � �frame=14    ��frame=9  	  � �x�224  �  ��face=-1    � �x�0     ��face=1      ��=""��8120  � !2	 �0     !3 �!4 �text(x,y,a$,i)!> ��20    +i!H$ ��18    ,0     ,58  :  ,8    !R �l=0     ̱a$-1    !\5 �li=�a$(l+1    )-34  "  :�li�0     ��li=30    !f �18    �l,li!p �l!z! ��a$,1    �0     ,0     �x,y#' �#(	 �setup()#2I ��:��:�:�2    ,0     :�0     :�0     :�:�2    ,1    :�255  �  #<' �"orb.spr"�16    ,0     ,2048    #=) �"font7.spr"�20    ,0     ,4096    #>) �"font8.spr"�21    ,0     ,4096    #?( �"game.spr"�17    ,0     ,9216   $ #F% ��18    ,0     ,16    ,16    #P ��16    #Z( �9275  ;$ ,7    :�9531  ;% ,2    #d ��17    #n
 ��1    ' �'0 �7    :��:�7    :�0     :�:��:�"saving..."' �:�"dev/orb":�"orb.bas"