//
// Created by D Rimron-Soutter on 19/07/2020.
//

#ifndef NEXTCCEL_NEXTCCEL_H
#define NEXTCCEL_NEXTCCEL_H


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
#include <circle/fs/fat/fatfs.h>
#include <circle/types.h>

#define CONFIG_PARTITION	"emmc1-1"
#define CONFIG_FILENAME     "config.txt"
#define CONFIG_DIETPI       "dietpi.cfg"
#define CONFIG_NEXTCCEL     "nextccel.cfg"

class Nextccel
{
public:
    Nextccel (void);
    ~Nextccel (void);

    boolean Initialize (CSerialDevice *uart, CEMMCDevice *sdcard,
                        CDeviceNameService	*p_DeviceNameService,
                        CLogger *logger);

    void Run (void);
    void Process (void);

    boolean running = TRUE;

private:
    void Exec (void);
    void Prompt (void);
    void reconfig (void);

private:
    CSerialDevice       *p_Serial;
    CDeviceNameService	*p_DeviceNameService;
    CLogger             *p_Logger;

    CEMMCDevice		    *p_EMMC;
    CFATFileSystem		m_FileSystem;

    static Nextccel     *s_pThis;

    char cmd_buffer[255]  = {0};
    u8 cmd_len = 0;

public:
    static const char *ready_label;
    static const char *kernel_label;
};

#endif //NEXTCCEL_NEXTCCEL_H