default:
	z88dk-zx7 -f find-help.txt
	zcc +zxn -v -startup=30 -clib=sdcc_iy -SO3 --max-allocs-per-node200000 --opt-code-size @zproject.lst -o find -pragma-include:zpragma.inc -subtype=dotn -Cz"--clean" -create-app
	rm -f find_UNASSIGNED.bin zcc_opt.def find-help.txt.zx7
