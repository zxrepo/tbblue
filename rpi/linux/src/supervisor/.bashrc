#!/bin/bash

. /root/.profile

function UpdatePS1 {
	count=`grep "/dev/root" /proc/mounts | grep -P "\srw[\s,]" | wc -l `
	case "$count" in
		0)	fs=">";;
		1)	fs="#";;
	esac
	export PS1="SUP$fs "
}

alias apt="echo \"APT is DISABLED. Please use manual DPGK instead. Absolute path overrides\""
alias apt-get="echo \"APT is DISABLED. Please use manual DPGK instead. Absolute path overrides\""

export PROMPT_COMMAND=UpdatePS1

