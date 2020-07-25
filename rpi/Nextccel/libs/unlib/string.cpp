//
// Created by D Rimron-Soutter on 19/07/2020.
//

#include "string.h"

u8 toupper(u8 c) {
    if(c&96) c=c-32;
    return c;
}

unsigned int strlen(const char *str) {
    unsigned int len = 0;
    while(str[len]) {
        len++;
    };

    return len;
}