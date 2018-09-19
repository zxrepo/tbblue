# Contributing to TBBlue #

You found your way here thanks to your interest in the ZX Spectrum Next project and/or retrocomputing in general! That's great but if you wish to contribute there are certain guidelines that need to be followed. Here are the specifics:


### 1. TBBlue is open but not necessarily fully open sourced.  ###

This means that you may find the source for **MANY**, but not **ALL** pieces of software here. This stems directly from SpecNext Ltd's license to use the Sinclair name.  
Remember this is a collection of software but not a software itself. It also contains documents, images and other media and therefore should not be considered in the same vain as one piece of software because it's not. This also allows contributors to choose their own license; you can contribute something that's GPL 3, MIT or be fully closed-source.  

### 2. All ROM images contained herewith with the exception of the NextZXOS MF and divMMC modules are copyrighted Amstrad / Sky plc or are jointly copyrighted by Amstrad and their author (ie NextZXOS, LG, GW ROMS)  ###

This means that if you wish to contribute a ROM image you either need to have permission by Amstrad / Sky plc to do so, own the work or have express permission to do so. In all cases other than the rom images provided by SpecNext Ltd you will need to include the license in the **/docs/licenses** folder with your **full name** and **redacted email** (which you will have to provide to SpecNext Ltd for idemnification)  

### 3. If you fork or want to distribute the project you need to abide by 1. and 2. above.  ###

This means that if you decide to fork, you can only fork the parts for which express permission has been given by their respective license or directly by their authors. For example in order to distribute the LG rom, you will need to contact its author first AND Amstrad/Sky plc. Also as a second example, you can fork/distribute almost all contents of the **/dot/** folder.  
  
### 4. No open sourced software contained herewith must be distributed without observing the terms of its license.  ###
  
This means that you're responsible to distribute all sources together with the executables in for example the cases of GPL-complying software. The general rule is: respect the rights of the other authors.

### 5. If you contribute software maintain the folder organization ###

This means: put your application where it should go; For a game put it under **games/&lt;platform>/&lt;nameofgame>** for a tool under **tools/&lt;type of tool>/&lt;name_of_tool>**, store the documents under **/docs/** (follow the structure; it's quite easy) and if you can put a small **readme.txt** file in the folder with your application. dot commands should go under **/dot/** and anything extra pertaining to them (or versions specifically made for esxDOS but carry the same name) should go under **/dot/extra/**  

### 6. Do not modify the System folders and files: /nextzxos, /tbblue, /tbblue/config.ini and /TBBLUE.FW ###
  
If you suggest a modification to any system file and/or folder add it as a *basename-&lt;name_of_file>.&lt;ext>* with clear instructions on how and where it should be merged by the user. The distribution **must be operable at all times** ergo the system folders and files must not be disturbed from their working state. End-users expect the distribution to be downloaded straight to their SD cards and booted directly from there. If in doubt confer with the rest of the contributors. Only authors of specific extensions/rom images/drivers that have been previously vetted as working can proceed to modify files in the system folder after they confer with the OS maintainer (Garry Lancaster) and the TBBlue main maintainer (Phoebus Dokos).

### 7. If you contribute software without a stated license, this is considered closed source without source code and open source if it includes sources under /src ###

This means that if you do not include a license file under **/docs/licenses/** but without source code under **/src/** your work will be automatically considered first as **further distribution denied** or in the second case as **open source/further distribution granted**  
  
### 8. All the software / documentation you contribute belongs to you unless you state otherwise ###  

This means that you retain the copyright of all the works you contribute herewith and you can at any given moment choose to remove it from the distribution without explanation or without any ramification except if you've given up on this right when you initially contribute (in which case you will have stated so in the accompanying license).

### 9. You cannot remove or modify software in the distribution belonging to others if its license does not allow so, if you lack permission ###  

This means, that if another author has contributed software to the distribution, you cannot remove it or modify it without his/her express permission (except in cases outlined in #10 below) if the software's license doesn't allow so.  
  
### 10. Software that was contributed illegally shall be removed without explanation ###  
  
Basically, what this means is that if you contribute anything that's not legal and could violate the Sinclair license from Amstrad / Sky plc will be removed immediately when found. If you are in the team of maintainers then you CAN remove someone else's contribution if it's in violation of a license or copyright law.
  
### 11. By contributing to the TBBlue distribution you're acknowledging that all the above are in-force and that you agree to them ###  

This is self-explanatory we believe and it's the easiest way to bypass all the otherwise-required legalese  




