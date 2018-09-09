/*
*/

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <unistd.h>
#include <time.h>
#include <sys/types.h>
#include <sys/stat.h>
#include <sys/time.h>
#include <fcntl.h>

#include "pigpio.h"

/*
This software reads pigpio notification reports monitoring the I2C signals.

Notifications are pipe based so this software must be run on the Pi
being monitored.

It should be able to handle a 100kHz bus.  You are unlikely to get any
usable results if the bus is running at 400kHz.

gcc -o pig2i2c pig2i2c.c

Do something like

sudo pigpiod -s 2

# get a notification handle, assume handle 0 was returned

pigs no

# start notifications for SCL/SDA

e.g. pigs nb 0 0x3   # Rev. 1 select gpios 0/1
e.g. pigs nb 0 0xC   # Rev. 2 select gpios 2/3
e.g. pigs nb 0 0xA00 # select gpios 9/11 (1<<9|1<<11)

# run the program, specifying SCL/SDA and notification pipe

./pig2i2c SCL SDA </dev/pigpioN # specify gpios for SCL/SDA and pipe N

e.g. ./pig2i2c 1  0 </dev/pigpio0 # Rev.1 I2C gpios
was this but thing SCL 1st param is PIN 2 and SDA 2nd is pin 3 ./pig2i2c 3  2 </dev/pigpio0 # Rev.2 I2C gpios
e.g. ./pig2i2c 2 3 </dev/pigpio0 # Rev.2 I2C gpios
e.g. ./pig2i2c 9 11 </dev/pigpio0 # monitor external bus 

Modified by Tim Gilberts to test the ZX Spectrum Next i2c connection to the PI  

*/

#define RS (sizeof(gpioReport_t))

#define SCL_FALLING 0
#define SCL_RISING  1
#define SCL_STEADY  2

#define SDA_FALLING 0
#define SDA_RISING  4
#define SDA_STEADY  8

static char * timeStamp()
{
   static char buf[32];

   struct timeval now;
   struct tm tmp;

   gettimeofday(&now, NULL);

   localtime_r(&now.tv_sec, &tmp);
   strftime(buf, sizeof(buf), "%F %T", &tmp);

   return buf;
}

void parse_I2C(int SCL, int SDA)
{
   static int in_data=0, byte=0, bit=0;
   static int in_address=0, address=0, rw=0;
   static int wait_ack=0;
   static int oldSCL=1, oldSDA=1;
   static int packet = 0;

   int xSCL, xSDA;

   if (SCL != oldSCL)
   {
      oldSCL = SCL;
      if (SCL) xSCL = SCL_RISING;
      else     xSCL = SCL_FALLING;
   }
   else        xSCL = SCL_STEADY;

   if (SDA != oldSDA)
   {
      oldSDA = SDA;
      if (SDA) xSDA = SDA_RISING;
      else     xSDA = SDA_FALLING;
   }
   else        xSDA = SDA_STEADY;

   switch (xSCL+xSDA)
   {
      case SCL_RISING + SDA_RISING:

      case SCL_RISING + SDA_FALLING:
         printf("/");
         break;

      case SCL_RISING + SDA_STEADY:
         if (in_data)
         {
            if (in_address)
            {
               if (bit++ < 7)
               {
                  address <<= 1;
                  address |= SDA;
                  //if (SDA) printf("1"); else printf("0");
               }
               else
               {
                  rw |= SDA;

                  printf("%02X(%c)", address, rw?'W':'R');
                  // if (SDA) printf("-"); else printf("+");
                  in_address = 0;
		  wait_ack = 1;
               }
            }
	    else
            {
               if (bit++ < 7)
               {
                  byte |= SDA;
                  byte <<= 1;
                  //if (SDA) printf("1"); else printf("0");
               }
               else
               {
                  if (wait_ack)
                  {
                     //Waiting for an ack likely
                     wait_ack=0;
                     bit = 0;
                     byte = 0;
                     address = 0;
                     printf("%c ",SDA?'n':'a');
                  } 
                  else
                  {
                     byte |= SDA;
		     wait_ack=1;
                     rw = 0;
                     printf("%02X", byte);
                     // if (SDA) printf("-"); else printf("+");
	          }
               }
            }
         }
         break;

      case SCL_FALLING + SDA_RISING:

      case SCL_FALLING + SDA_FALLING:
         printf("\\");
         break;

      case SCL_FALLING + SDA_STEADY:
         // printf("-");
         break;

      case SCL_STEADY + SDA_RISING:
         if (SCL)
         {
            packet = 0;
            in_data = 0;
            in_address = 1;
            byte = 0;
            bit = 0;
            address=0;
            rw=0;
            wait_ack = 0;

            printf("]\n"); // stop
            fflush(NULL);
         }
         break;

      case SCL_STEADY + SDA_FALLING:
         if (SCL)
         {
            packet = 1;
            in_data = 1;
            in_address = 1;
	    address = 0;
            rw = 0;
            byte = 0;
            bit = 0;
            wait_ack = 0;

            printf("["); // start
         }
         break;

      case SCL_STEADY + SDA_STEADY:
         //if (!packet)
            printf(".");
         break;

   }
}

int main(int argc, char * argv[])
{
   int gSCL, gSDA, SCL, SDA, xSCL;
   int r;
   uint32_t level, changed, bI2C, bSCL, bSDA;

   gpioReport_t report;

   if (argc > 2)
   {
      gSCL = atoi(argv[1]);
      gSDA = atoi(argv[2]);

      bSCL = 1<<gSCL;
      bSDA = 1<<gSDA;

      bI2C = bSCL | bSDA;
   }
   else
   {
      exit(-1);
   }

   /* default to SCL/SDA high */

   SCL = 1;
   SDA = 1;
   level = bI2C;

   while ((r=read(STDIN_FILENO, &report, RS)) == RS)
   {
      report.level &= bI2C;

      if (report.level != level)
      {
         changed = report.level ^ level;

         level = report.level;

         if (level & bSCL) SCL = 1; else SCL = 0;
         if (level & bSDA) SDA = 1; else SDA = 0;

         parse_I2C(SCL, SDA);
      }
   }
   return 0;
}

