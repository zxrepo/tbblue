
unsigned int uart_lcr ( void );
unsigned int uart_recv ( void );
unsigned int uart_check ( void );
void uart_send ( unsigned int c );
void uart_send_string ( char *s  );
void uart_flush ( void );
void hexstrings ( unsigned int d );
void hexstring ( unsigned int d );
void uart_init ( void );