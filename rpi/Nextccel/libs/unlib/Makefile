#
# Makefile
#


CIRCLEHOME = ../../../../../circle



OBJS	= string.o

libunlib.a: $(OBJS)
	@echo "  AR    $@"
	@rm -f $@
	@$(AR) cr $@ $(OBJS)

include $(CIRCLEHOME)/Rules.mk

-include $(DEPS)
