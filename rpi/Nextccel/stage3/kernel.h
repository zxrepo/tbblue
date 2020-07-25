//
// kernel.h
//
#ifndef _kernel_h
#define _kernel_h

#include <circle/memory.h>
#include <circle/actled.h>
#include <circle/koptions.h>
#include <circle/devicenameservice.h>
#include <circle/screen.h>
#include <circle/serial.h>
#include <circle/exceptionhandler.h>
#include <circle/interrupt.h>
#include <circle/timer.h>
#include <circle/logger.h>
#include <SDCard/emmc.h>
#include <circle/types.h>

#include "Nextccel.h"

enum TShutdownMode
{
	ShutdownNone,
	ShutdownHalt,
	ShutdownReboot
};

class CKernel
{
public:
	CKernel (void);
	~CKernel (void);
	boolean Initialize (void);

	TShutdownMode Run (void);

private:
    // do not change this order - the system depends on load order (Circle 42)
	CMemorySystem		m_Memory;
	CActLED			    m_ActLED;
	CKernelOptions		m_Options;
	CDeviceNameService	m_DeviceNameService;
	CScreenDevice		m_Screen;
	CSerialDevice		m_Serial;
	CExceptionHandler	m_ExceptionHandler;
	CInterruptSystem	m_Interrupt;
	CTimer			    m_Timer;
	CLogger			    m_Logger;

	//  for persistence
    CEMMCDevice		    m_EMMC;
    CFATFileSystem		m_FileSystem;
	// our base SUPervisor
    Nextccel			m_Nextccel;
};

#endif
