#include <stdio.h>
#include <stdlib.h>
#include <arch/zxn/esxdos.h>

#include "load.h"
#include "run.h"

void load_tap(void)
{
   // currently mounted tap will be closed by open
   
   if (esx_m_tapein_open(dirent_sfn.name))
      return;

   puts("\nTo start - LOAD \"t:\": LOAD \"\"");
   exit(0);
}
