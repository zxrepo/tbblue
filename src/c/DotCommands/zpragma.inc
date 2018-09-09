// Set ORG of compile
//#pragma output CRT_ORG_CODE = 0x8184   // im2 table at 0x8000 filled with 0x81 bytes with jp to isr at 0x8181
//#pragma output REGISTER_SP = 0x8000

// im2 table at 0x8000 filled with 0x81 bytes with jp to isr at 0x8181
//#pragma output REGISTER_SP = 0x8181			// Stack inbetween IM2 table (257 bytes) and JP ISR code
//#pragma output CRT_ORG_CODE = 0x8184		// Code starts after JP ISR (3 bytes) located at 0x8181
#pragma output REGISTER_SP = 0x8240			// Stack inbetween IM2 table (257 bytes) and JP ISR code
#pragma output CRT_ORG_CODE = 0x8240		// Code starts after JP ISR (3 bytes) located at 0x8181

//#pragma output CRT_ORG_BSS = 0

// Disable interrupts at start and at exit
#pragma output CRT_ENABLE_EIDI = 0x11

// On exit, HALT (no more play nice with basic)
//#pragma output CRT_ON_EXIT = 0x10001
#pragma output CRT_ON_EXIT = 0

// do not create a heap (no malloc)
#pragma output CLIB_MALLOC_HEAP_SIZE = 0

// BAlloc tables
#pragma output CLIB_BALLOC_TABLE_SIZE = 16

// do not create a heap for stdio (cannot open files)
#pragma output CLIB_STDIO_HEAP_SIZE = 0

# Apped custom banks (defined in mmap.inc)
#pragma output CRT_APPEND_MMAP = 1
