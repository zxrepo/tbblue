#
# Makefile for dot commands
#

PASMO = pasmo --nocase
RM = rm

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

clean:
	$(RM) $$ ASSOCIATE CPM DEFRAG LFN MEM MKDATA MKSWAP INSTALL UNINSTALL BROWSE NEXTVER *.sym
