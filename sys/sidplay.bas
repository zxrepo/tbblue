PLUS3DOS �   v�W                                                                                                         � +  ; encodes and sends a sid to the pi uart  	  ; emk20   .pisend -q:    � (  .$ pisend f$ ) � + �%s =%�$7f , �%s=0��"Pi error":�80   P   - �c$="-c csidl """+f$+"""" 2  .$ pisend c$: 7	 �5     8> �:��12    ,0     ;"Playing..."+f$:�"(takes a few seconds)" <% ��20    ,0     ;"Any key to exit" ? ��=""��63  ?   @  .pisend -c q:  A �999  �  F �"c:\sys\sidplay.bas":� P3 ��9  	  ,1    ;"If Pi audio is playing press S" V$ ��10  
  ,1    ;"Or R to retry " Z �#0     �k d$ �k=�"s"�k=�"S"�.pisend -q:�10  
   n$ �k=�"r"�k=�"R"�.pisend -q:�10  
  F 809.SIDC -c csidl "809.SID"