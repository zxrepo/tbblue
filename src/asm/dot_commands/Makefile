#
# Makefile for dot commands
#

ASM = pasmo --nocase
RM = rm -f

all:
	$(ASM) $$.asm $$ $$.sym
	$(ASM) cpm.asm CPM cpm.sym
	$(ASM) defrag.asm DEFRAG defrag.sym
	$(ASM) lfn.asm LFN lfn.sym
	$(ASM) mem.asm MEM mem.sym
	$(ASM) -E MKDATA=1 mkp3d.asm MKDATA mkdata.sym
	$(ASM) -E MKDATA=0 mkp3d.asm MKSWAP mkswap.sym
	$(ASM) install.asm INSTALL install.sym
	$(ASM) uninstall.asm UNINSTALL uninstall.sym
	$(ASM) browse.asm BROWSE browse.sym
	$(ASM) nextver.asm NEXTVER nextver.sym
	$(ASM) associate.asm ASSOCIATE associate.sym
	$(ASM) bas2txt.asm BAS2TXT bas2txt.sym
	$(ASM) txt2bas.asm TXT2BAS txt2bas.sym

clean:
	$(RM) $$ ASSOCIATE CPM DEFRAG LFN MEM MKDATA MKSWAP INSTALL UNINSTALL BROWSE NEXTVER BAS2TXT TXT2BAS *.sym
