//
// Created by D Rimron-Soutter on 19/07/2020.
//


#include "Nextccel.h"
#include "kernel.h"

#include "../lib/unlib/string.h"

static const char SupPrompt[] = "SUP> ";

const char *Nextccel::kernel_label = { "Nextccel 0.99E-alpha1" };
const char *Nextccel::ready_label = { "SUPREADY!" };

Nextccel *Nextccel::s_pThis;

Nextccel::Nextccel ()
{
    s_pThis = 0;
    cmd_len = 0;
}

Nextccel::~Nextccel (void) {
    s_pThis = 0;
    cmd_len = 0;
}

boolean Nextccel::Initialize(CSerialDevice *uart, CEMMCDevice *sdcard,
                             CDeviceNameService	*dns, CLogger *logger) {
    p_Serial = uart;
    p_EMMC = sdcard;
    p_DeviceNameService = dns;
    p_Logger = logger;

    p_Logger->Write (Nextccel::kernel_label, LogDebug, "Compile time: " __DATE__ " " __TIME__);

    return TRUE;
}

void Nextccel::reconfig() {
    // Mount file system
    CDevice *pPartition = p_DeviceNameService->GetDevice (CONFIG_PARTITION, TRUE);
    if (pPartition == 0)
    {
        p_Logger->Write (kernel_label, LogPanic, "Partition not found: %s", CONFIG_PARTITION);
    }

    if (!m_FileSystem.Mount (pPartition))
    {
        p_Logger->Write (kernel_label, LogPanic, "Cannot mount partition: %s", CONFIG_PARTITION);
    }

    /*

    // Create file and write to it
//    unsigned srcFile;// = m_FileSystem.FileCreate (FILENAME);
//    if (hFile == 0)
//    {
//        m_Logger.Write (FromKernel, LogPanic, "Cannot create file: %s", FILENAME);
//    }
//
//    for (unsigned nLine = 1; nLine <= 5; nLine++)
//    {
//        CString Msg;
//        Msg.Format ("Hello File! (Line %u)\n", nLine);
//
//        if (m_FileSystem.FileWrite (hFile, (const char *) Msg, Msg.GetLength ()) != Msg.GetLength ())
//        {
//            m_Logger.Write (FromKernel, LogError, "Write error");
//            break;
//        }
//    }
//
//    if (!m_FileSystem.FileClose (hFile))
//    {
//        m_Logger.Write (FromKernel, LogPanic, "Cannot close file");
//    }
//
     */
    // Open the "dietpi" config, and overwrite the system one
    unsigned srcFile = m_FileSystem.FileOpen (CONFIG_DIETPI);
    if (srcFile == 0)
    {
        p_Logger->Write (kernel_label, LogPanic, "Cannot open source file for reading: %s", CONFIG_DIETPI);
    }

    unsigned cfgFile = m_FileSystem.FileCreate (CONFIG_FILENAME);
    if (cfgFile == 0)
    {
        p_Logger->Write (kernel_label, LogPanic, "Cannot open config file for writing: %s", CONFIG_DIETPI);
    }

    char Buffer[512];
    unsigned nResult;
    while ((nResult = m_FileSystem.FileRead (srcFile, Buffer, sizeof Buffer)) > 0)
    {
        if (nResult == FS_ERROR)
        {
            p_Logger->Write (kernel_label, LogError, "Read error");
            break;
        }

        if (m_FileSystem.FileWrite (cfgFile, (const char *) Buffer, nResult) != nResult)
        {
            p_Logger->Write (kernel_label, LogError, "Write error");
            break;
        }
    }

    if (!m_FileSystem.FileClose (cfgFile))
    {
        p_Logger->Write (kernel_label, LogPanic, "Cannot close cfgFile");
    }

    if (!m_FileSystem.FileClose (srcFile))
    {
        p_Logger->Write (kernel_label, LogPanic, "Cannot close srcFile");
    }
}

void Nextccel::Run (void)
{
    p_Serial->Write (ready_label, strlen(ready_label));
    p_Serial->Write ("\n\n", 2);

    Prompt();
}

void Nextccel::Exec (void)
{
    // It be much nicer if we had a STDLIB.
    // We don't - we have UNLIB.
    // I made UNLIB. Adjust your expectations accordingly.
    // Maybe I'll port STDLIB. One day. Not today.

    // STAGE 1: command parser, because you just hit ENTER, or the end of a (254char) long line...
    if(cmd_len == 7) {
        if( (toupper(cmd_buffer[0])=='R') &&
            (toupper(cmd_buffer[1])=='E') &&
            (toupper(cmd_buffer[2])=='B') &&
            (toupper(cmd_buffer[3])=='O') &&
            (toupper(cmd_buffer[4])=='O') &&
            (toupper(cmd_buffer[5])=='T')
        ){
            running = FALSE;
            return;
        } else
        if(((toupper(cmd_buffer[0])=='D') &&
            (toupper(cmd_buffer[1])=='I') &&
            (toupper(cmd_buffer[2])=='E') &&
            (toupper(cmd_buffer[3])=='T') &&
            (toupper(cmd_buffer[4])=='P') &&
            (toupper(cmd_buffer[5])=='I'))
        ||
           ((toupper(cmd_buffer[0])=='N') &&
            (toupper(cmd_buffer[1])=='E') &&
            (toupper(cmd_buffer[2])=='X') &&
            (toupper(cmd_buffer[3])=='T') &&
            (toupper(cmd_buffer[4])=='P') &&
            (toupper(cmd_buffer[5])=='I'))
        ){
            // MANGLE CONFIG FILE
            reconfig();
            running = FALSE;
            return;
        }
    }

    p_Serial->Write("\"", 1);
    u8 r = cmd_len + 48;
    p_Serial->Write(&r, 1);
    p_Serial->Write("\"\n", 2);

    cmd_len = 0;
    while(cmd_buffer[cmd_len]) {
        p_Serial->Write(&cmd_buffer[cmd_len++], 1);
    }
    p_Serial->Write(" not known\n", 11);

    Prompt();
    cmd_len = 0;
}

void Nextccel::Process (void)
{
    u8 Buffer[1];
    int nResult = p_Serial->Read (Buffer, 1);
    if(nResult>0) {
        if((cmd_len>254) || Buffer[0]==13) {
            p_Serial->Write("\n", 1);
            cmd_buffer[cmd_len++] = 0;

            // Process this command
            Exec();
        } else
        if(Buffer[0]>31) {
            p_Serial->Write(Buffer, 1);
            cmd_buffer[cmd_len++] = Buffer[0];
        }
    }
}

void Nextccel::Prompt (void)
{
    p_Serial->Write(SupPrompt,  strlen(SupPrompt));
}
