#include "periph.h"
#include "uart.h"
#include "vector.h"

void  timer_init ( void )
{
    //0xF9+1 = 250
    //250MHz/250 = 1MHz
    PUT32(ARM_TIMER_CTL,0x00F90000);
    PUT32(ARM_TIMER_CTL,0x00F90200);
}
unsigned int timer_tick ( void )
{
    return(GET32(ARM_TIMER_CNT));
}
unsigned mbox_writeread (unsigned nData)
{
	while (GET32 (MAILBOX1_STATUS) & MAILBOX_STATUS_FULL)
	{
		// do nothing
	}

	PUT32 (MAILBOX1_WRITE, BCM_MAILBOX_PROP_OUT | nData);

	unsigned nResult;
	do
	{
		while (GET32 (MAILBOX0_STATUS) & MAILBOX_STATUS_EMPTY)
		{
			// do nothing
		}

		nResult = GET32 (MAILBOX0_READ);
	}
	while ((nResult & 0xF) != BCM_MAILBOX_PROP_OUT);

	return nResult & ~0xF;
}
unsigned get_core_clock (void)
{
	// does not work without a short delay with newer firmware on RPi 1
	for (volatile unsigned i = 0; i < 10000; i++);

	unsigned proptag[] __attribute__ ((aligned (16))) =
	{
		8*4,
		CODE_REQUEST,
		PROPTAG_GET_CLOCK_RATE,
		4*4,
		1*4,
		CLOCK_ID_CORE,
		0,
		PROPTAG_END
	};

	mbox_writeread ((unsigned) (unsigned long) &proptag);

	return proptag[6];
}
unsigned div (unsigned nDividend, unsigned nDivisor)
{
	if (nDivisor == 0)
	{
		return 0;
	}

	unsigned long long ullDivisor = nDivisor;

	unsigned nCount = 1;
	while (nDividend > ullDivisor)
	{
		ullDivisor <<= 1;
		nCount++;
	}

	unsigned nQuotient = 0;
	while (nCount--)
	{
		nQuotient <<= 1;

		if (nDividend >= ullDivisor)
		{
			nQuotient |= 1;
			nDividend -= ullDivisor;
		}

		ullDivisor >>= 1;
	}

	return nQuotient;
}
