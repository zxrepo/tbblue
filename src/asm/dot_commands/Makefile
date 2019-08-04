#
# Makefile for dot commands
#

PASMO = pasmo --nocase
RM = rm -f

all:
	$(PASMO) $$.asm $$ $$.sym
	$(PASMO) cpm.asm CPM cpm.sym
	$(PASMO) defrag.asm DEFRAG defrag.sym
	$(PASMO) lfn.asm LFN lfn.sym
	$(PASMO) mem.asm MEM mem.sym
	$(PASMO) -E MKDATA=1 mkp3d.asm MKDATA mkdata.sym
	$(PASMO) -E MKDATA=0 mkp3d.asm MKSWAP mkswap.sym
	$(PASMO) install.asm INSTALL install.sym
	$(PASMO) uninstall.asm UNINSTALL uninstall.sym
	$(PASMO) browse.asm BROWSE browse.sym
	$(PASMO) nextver.asm NEXTVER nextver.sym
	$(PASMO) associate.asm ASSOCIATE associate.sym
	$(PASMO) bas2txt.asm BAS2TXT bas2txt.sym
	$(PASMO) txt2bas.asm TXT2BAS txt2bas.sym

clean:
	$(RM) $$ ASSOCIATE CPM DEFRAG LFN MEM MKDATA MKSWAP INSTALL UNINSTALL BROWSE NEXTVER BAS2TXT TXT2BAS *.sym
