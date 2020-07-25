#include "periph.h"
#include "uart.h"
#include "vector.h"


//------------------------------------------------------------------------
int stage2 ( void )
{
    unsigned int countdown;

    unsigned int state;
    unsigned int byte_count;
    unsigned int digits_read = 0;
    unsigned int address;
    unsigned int record_type;
    unsigned int segment;
    unsigned int data;
    unsigned int sum;
    unsigned int ra = 0;



    uart_init();
    uart_send_string("\x0A\x0D Nextload: Stage 2 Chainloader\x0A\x0D");

    countdown = 10000000;

    uart_send_string("BOOT> ");

    while(countdown)
    {
        // IF char in UART
        if(GET32(AUX_MU_LSR_REG)&0x01) {
            ra = GET32(AUX_MU_IO_REG)&0xFF;
            uart_send(ra);
            break;
        }
        countdown--;
    }

    if ((ra == 'h') || (ra == 'H')) {
        uart_send_string("\x0A\x0D Starting Stage 3 Uploader: \x0A\x0D");
        uart_send_string("IHEX\x0A\x0D");

        state = 0;
        segment = 0;
        sum = 0;
        data = 0;
        record_type = 0;
        address = 0;
        byte_count = 0;

        while (1) {
            // This is the serial uploader
            ra = uart_recv();
            if (ra == ':') {
                state = 1;
                continue;
            }
            if (ra == 0x0D) {
                state = 0;
                continue;
            }
            if (ra == 0x0A) {
                state = 0;
                continue;
            }
            if ((ra == 'g') || (ra == 'G')) {
                uart_send(0x0D);
                uart_send('-');
                uart_send('-');
                uart_send(0x0D);
                uart_send(0x0A);
                uart_send(0x0A);
                BRANCHTO(0x8000);

                state = 0;
                break;
            }
            switch (state) {
                case 0: {
                    break;
                }
                case 1:
                case 2: {
                    byte_count <<= 4;
                    if (ra > 0x39) ra -= 7;
                    byte_count |= (ra & 0xF);
                    byte_count &= 0xFF;
                    digits_read = 0;
                    state++;
                    break;
                }
                case 3:
                case 4:
                case 5:
                case 6: {
                    address <<= 4;
                    if (ra > 0x39) ra -= 7;
                    address |= (ra & 0xF);
                    address &= 0xFFFF;
                    address |= segment;
                    state++;
                    break;
                }
                case 7: {
                    record_type <<= 4;
                    if (ra > 0x39) ra -= 7;
                    record_type |= (ra & 0xF);
                    record_type &= 0xFF;
                    state++;
                    break;
                }
                case 8: {
                    record_type <<= 4;
                    if (ra > 0x39) ra -= 7;
                    record_type |= (ra & 0xF);
                    record_type &= 0xFF;
                    switch (record_type) {
                        case 0x00: {
                            state = 14;
                            break;
                        }
                        case 0x01: {
                            hexstring(sum);
                            state = 0;
                            break;
                        }
                        case 0x02:
                        case 0x04: {
                            state = 9;
                            break;
                        }
                        default: {
                            state = 0;
                            break;
                        }
                    }
                    break;
                }
                case 9:
                case 10:
                case 11:
                case 12: {
                    segment <<= 4;
                    if (ra > 0x39) ra -= 7;
                    segment |= (ra & 0xF);
                    segment &= 0xFFFF;
                    state++;
                    break;
                }
                case 13: {
                    segment <<= 4;
                    if (record_type == 0x04) {
                        segment <<= 12;
                    }
                    state = 0;
                    break;
                }
                case 14: {
                    data <<= 4;
                    if (ra > 0x39) ra -= 7;
                    data |= (ra & 0xF);
                    if (++digits_read % 8 == 0 || digits_read == byte_count * 2) {
                        ra = (data >> 24) | (data << 24);
                        ra |= (data >> 8) & 0x0000FF00;
                        ra |= (data << 8) & 0x00FF0000;
                        if (digits_read % 8 != 0) {
                            ra >>= (8 - digits_read % 8) * 4;
                        }
                        data = ra;
                        PUT32(address, data);
                        sum += address;
                        sum += data;
                        address += 4;
                        if (digits_read == byte_count * 2) {
                            state = 0;
                        }
                    }
                    break;
                }
            }
        }
    } else {
        uart_send_string("\x0A\x0D Starting (integrated) Stage 3: Nextccel\x0A\x0D");
        // Modify our vector stable, so that when we next branch we get "stage3.bin"
        _start[0] = 0x00;
        _start[1] = 0x00;
        _start[2] = 0x0f;
        _start[3] = 0xe1;
    }

    uart_send_string("\x0A\x0D Executing Stage 3\x0A\x0D\x0A\x0D");
    BRANCHTO(0x8000);

    return(0);
}
