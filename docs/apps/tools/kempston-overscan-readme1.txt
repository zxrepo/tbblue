 ---
 14th September 2018



 KEMPSTON.SNA


 Kempston port test 0.2beta

 Use this tool to test the Kempston ports. It displays the raw values for
 port 31 (0x1F) and port 55 (0x37). The value 11111111 is displayed when
 the ports are not configured for Kempston or Mega-Drive type input.

 Mouse input moves the pointer sprite. The mouse buttons and scroll wheel
 can be used to move the bar left and right and change the color.


 Compatible with core v.1.10.51 and above.


 ---------------------------------------------------------------------------


 OVERSCAN.SNA


 Overscan test 0.2beta

 This helpful tool provides video display information and copper compare 
 values. It works across all machines and video mode types. It can be used
 to find ideal copper overscan compare values.

 Kempston input is auto configured.

 Controls are as follows:

    Kempston mouse:

 Move pointer sprite to display co-ordinates.


 Kempston joystick:

    UP/DOWN, adjust top bar. Hold FIRE to adjust bottom bar.
 LEFT/RIGHT, adjust left position.
 LEFT/RIGHT, hold FIRE to adjust right position.


          Keyboard:

         F3: Toggle 50/60Hz refresh and reset defaults. Pentagon 50Hz ONLY!
 

           Display:

 Clocks is number of 14Mhz copper clocks and 3.5Mhz Z80 clocks (Ts) per line.

 Lines is number of actual lines for the current display mode.

 Visible is pixel resolution of the red box.

 The left and right integer display is the copper H compare. The fractional
 part is number of copper clocks. 52.7 would wait for H=52 with 7 NOPs to
 pad out the timing. (More details can be found in my copper documentation).


 Compatible with core v.2.00.00 and above.


 KevB (aka 9bitcolor)

