PACKAGE_DIR=DOT
PACKAGE_SOURCE_DIR=PackagedSource
ESXDIR=/Applications/zesarux.app/Contents/MacOS/media/spectrum/esxdos_handler/0.8.6_TBBLUE

ifeq (1,0)
CLIB=new
CFLAGS=--opt-code-size
OPT=3
else
CLIB=sdcc_iy
CFLAGS=--opt-code-size
#CFLAGS=--max-allocs-per-node200000 --opt-code-size
OPT=3
endif

OPTIONS_PRE=+zxn -vn -m -startup=30 -clib=sdcc_iy -SO3 -pragma-include:dpragma.inc DotCommandShared.c
OPTIONS_POST=-Cz"--pages" -subtype=dot -create-app

#==============================================================================
#
#==============================================================================
.PHONY: depend clean
.SUFFIXES: .o .c
.SUFFIXES: .o .asm
SEGS =

#==============================================================================
#
#==============================================================================
default: dotcommand_cd dotcommand_mkdir dotcommand_rmdir dotcommand_rm dotcommand_chmod dotcommand_tapein dotcommand_tapeout dotcommand_lstap

dotcommand_cd: DotCommand_CD.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating CD ****"
	zcc $(OPTIONS_PRE) DotCommand_CD.c -o CD $(OPTIONS_POST)

dotcommand_mkdir: DotCommand_MKDIR.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating MKDIR ****"
	zcc $(OPTIONS_PRE) DotCommand_MKDIR.c -o MKDIR $(OPTIONS_POST)

dotcommand_rm: DotCommand_RM.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating RM ****"
	zcc $(OPTIONS_PRE) DotCommand_RM.c -o RM $(OPTIONS_POST)

dotcommand_rmdir: DotCommand_RMDIR.c DotCommandShared.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating RMDIR ****"
	zcc $(OPTIONS_PRE) DotCommand_RMDIR.c -o RMDIR $(OPTIONS_POST)

dotcommand_chmod: DotCommand_CHMOD.c DotCommandShared.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating CHMOD ****"
	zcc $(OPTIONS_PRE) DotCommand_CHMOD.c -o CHMOD $(OPTIONS_POST)

dotcommand_tapein: DotCommand_TAPEIN.c DotCommandShared.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating TAPEIN ****"
	zcc $(OPTIONS_PRE) DotCommand_TAPEIN.c -o TAPEIN $(OPTIONS_POST)

dotcommand_tapeout: DotCommand_TAPEOUT.c DotCommandShared.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating TAPEOUT ****"
	zcc $(OPTIONS_PRE) DotCommand_TAPEOUT.c -o TAPEOUT $(OPTIONS_POST)

dotcommand_lstap: DotCommand_LSTAP.c DotCommandShared.c mmap.inc dpragma.inc Makefile
	@echo "\n**** Creating LSTAP ****"
	zcc $(OPTIONS_PRE) DotCommand_LSTAP.c -o LSTAP $(OPTIONS_POST)


#copy_zesarux:
#	@echo "**** Copying to ZEsarUX ESXDos Folder ***"
#	\cp -rp $(PACKAGE_DIR)/CD2 ${ESXDIR}/BIN
#	@echo "Complete\n"

package-source:
	@mkdir -p $(PACKAGE_SOURCE_DIR)
	@\cp -f *.c ${PACKAGE_SOURCE_DIR}
	@\cp -f *.h ${PACKAGE_SOURCE_DIR}
	@\cp -f Makefile ${PACKAGE_SOURCE_DIR}
	@\cp -f dpragma.inc ${PACKAGE_SOURCE_DIR}
	@\cp -f mmap.inc ${PACKAGE_SOURCE_DIR}

package-dot:
	@echo "\n**** Packaging Dot Commands ****"
	@mkdir -p $(PACKAGE_DIR)
	@\cp -f CD ${PACKAGE_DIR}
	@\cp -f MKDIR ${PACKAGE_DIR}
	@\cp -f RMDIR ${PACKAGE_DIR}
	@\cp -f RM ${PACKAGE_DIR}
	@\cp -f TAPEIN ${PACKAGE_DIR}
	@\cp -f TAPEOUT ${PACKAGE_DIR}
	@\cp -f LSTAP ${PACKAGE_DIR}

copy-flashair:
	@echo "\n**** Copying to Flashair ****"
	curl -s -F file=@$(PACKAGE_DIR)/CD -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/MKDIR -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/RMDIR -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/RM -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/TAPEIN -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/TAPEOUT -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	curl -s -F file=@$(PACKAGE_DIR)/LSTAP -F submit=submit http://168.192.1.99/upload.cgi >/dev/null
	@echo "Complete\n"


#==============================================================================
#
#==============================================================================
.asm.o:
	zcc +zxn -m -vn -c -clib=$(CLIB) -SO$(OPT) $(CFLAGS) $(SEGS) $<
.c.o:
	zcc +zxn -m -vn -c -clib=$(CLIB) -SO$(OPT) $(CFLAGS) $(SEGS) $<

#==============================================================================
#
#==============================================================================
clean:
	-rm -f *.o *.bin *.font *.map *.sym zcc_proj.lst zcc_opt.def *.orig *.tap *.sna *.snx *.nex
	-rm -f CD RM RMDIR MKDIR CHMOD TAPEIN TAPEOUT LSTAP

depend: $(CSRC)
	makedepend $(INCL) $^

# DO NOT DELETE THIS LINE -- make depend needs it
