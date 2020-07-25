//
// kernel.cpp
//
#include "kernel.h"
#include "Nextccel.h"
#include "../lib/unlib/string.h"

CKernel::CKernel (void)
:	m_Screen (640, 480),
    m_Serial (&m_Interrupt),
    m_Timer (&m_Interrupt),
    m_Logger (m_Options.GetLogLevel (), &m_Timer),
    m_EMMC (&m_Interrupt, &m_Timer, &m_ActLED),
	m_Nextccel ()
{
}

CKernel::~CKernel (void)
{
}

boolean CKernel::Initialize (void)
{
	boolean bOK = TRUE;

	if (bOK)
	{
		bOK = m_Screen.Initialize ();
	}

	if (bOK)
	{
		bOK = m_Logger.Initialize (&m_Screen);
	}

    m_Logger.Write (Nextccel::kernel_label, LogDebug, "Stage 3 started");

	if (bOK)
	{
		bOK = m_Interrupt.Initialize ();
	}

    if (bOK)
    {
        bOK = m_Timer.Initialize ();
    }

    if (bOK)
    {
        bOK = m_Serial.Initialize (115200);
    }

    if (bOK)
    {
        bOK = m_EMMC.Initialize ();
    }

    if (bOK)
    {
        // Pass all the dependancies in, so we ensure all modules use a shared instance - and we don't get out of sync
        bOK = m_Nextccel.Initialize (&m_Serial, &m_EMMC, &m_DeviceNameService, &m_Logger);
        // THis
    }

    // Add your modules here now, continue the bOK chain, and pass or inject your requirements like Nextccel.Initialize()


	return bOK;
}

TShutdownMode CKernel::Run (void)
{
    m_Nextccel.Run();

	while(m_Nextccel.running)
	{
		m_Nextccel.Process();
		//That's it, your main accelerator should be interrupt based..
		// But you would need to load them them in the kernel above, after m_Nextccel.
	}

	m_Logger.Write (Nextccel::kernel_label, LogDebug, "Nextccel Rebooting");
	m_Serial.Write ("Nextccel Rebooting", strlen("Nextccel Rebooting"));

    m_ActLED.Blink (2);

	return ShutdownReboot;
}
