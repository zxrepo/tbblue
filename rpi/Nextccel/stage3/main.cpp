//
// main.c
//
#include "kernel.h"
#include <circle/startup.h>

int main (void)
{
    // cannot return here because some destructors used in CKernel are not implemented (circa Circle 42)

    CKernel Kernel;
    if (!Kernel.Initialize ())
    {
        return EXIT_REBOOT;
    }

    TShutdownMode ShutdownMode = Kernel.Run ();

    switch (ShutdownMode)
    {
        case ShutdownReboot:
            reboot ();
            return EXIT_REBOOT;

        case ShutdownHalt:
        default:
            halt ();
            return EXIT_HALT;
    }
}
