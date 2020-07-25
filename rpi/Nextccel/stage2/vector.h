//
// Created by D Rimron-Soutter on 11/07/2020.
//

#ifndef NEXTCCELERATOR_VECTOR_H
#define NEXTCCELERATOR_VECTOR_H

void PUT32 ( unsigned int, unsigned int );
void PUT16 ( unsigned int, unsigned int );
void PUT8 ( unsigned int, unsigned int );
unsigned int GET32 ( unsigned int );
unsigned int GETPC ( void );
void BRANCHTO ( unsigned int );
void dummy ( unsigned int );

// Our actual memory, indexed from our entrypoint - used for SMC
unsigned int _start[16777216];

#endif //NEXTCCELERATOR_VECTOR_H
