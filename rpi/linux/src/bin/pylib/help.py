#!/usr/bin/env python

import os
import sys

def help(scriptname = None):
	if scriptname == None:
		scriptname = os.path.basename(sys.argv[0])
	print
	print scriptname+": ERROR"
	print
	print "    Please visit http://specnext.dev/wiki/Pi:"+scriptname.split("-")[1].replace("_","-")
	print

def main():
	help(sys.argv[1])


if __name__ == "__main__":
	main()
