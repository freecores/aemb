/* $Id: simboard.hh,v 1.4 2008-04-26 19:32:00 sybreon Exp $
** 
** AEMB Function Verification C++ Testbench
** Copyright (C) 2004-2008 Shawn Tan <shawn.tan@aeste.net>
**
** This file is part of AEMB.
**
** AEMB is free software: you can redistribute it and/or modify it
** under the terms of the GNU General Public License as published by
** the Free Software Foundation, either version 3 of the License, or
** (at your option) any later version.
**
** AEMB is distributed in the hope that it will be useful, but WITHOUT
** ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
** License for more details.
**
** You should have received a copy of the GNU General Public License
** along with AEMB.  If not, see <http://www.gnu.org/licenses/>.
*/

#include "aemb/msr.hh"
#include <stdlib.h>
#include <stdio.h>

#ifndef SIMBOARD_HH
#define SIMBOARD_HH

#define CODE_FAIL 0xDEADBEEF
#define CODE_PASS 0xCAFEF00D


/*
INTERRUPT TESTS
*/

#ifdef __cplusplus
using namespace aemb;
#endif

volatile int intr = -1;

void __attribute__ ((interrupt_handler)) interruptHandler() 
{
  intr = 0; // flag the interrupt service routine
}

int interruptTest(int timeout)
{
  enableInterrupts();
  int timer;
  for (timer=0; (timer < timeout) && (intr == -1); ++timer); // delay loop
  disableInterrupts();
  return (intr == 0) ? EXIT_SUCCESS : EXIT_FAILURE;
}


/**
   FSL TEST ROUTINE
*/

int xslTest (int code)
{
  // TEST FSL1 ONLY
  int FSL = code;

  asm ("PUT %0, RFSL1" :: "r"(FSL));
  asm ("GET %0, RFSL1" : "=r"(FSL));
  
  if (FSL != code) return EXIT_FAILURE;
  
  asm ("PUT %0, RFSL31" :: "r"(FSL));
  asm ("GET %0, RFSL31" : "=r"(FSL));
  
  if (FSL != code) return EXIT_FAILURE;
  
  return EXIT_SUCCESS;  
}

/**
   MALLOC TEST
   Works well with newlib malloc routine. Do some patterned tests.
*/

int memoryTest(int size)
{
  void *alloc;
  alloc = malloc(size * sizeof(int)); // allocate 32 byte
  return (alloc == NULL) ? EXIT_FAILURE : EXIT_SUCCESS;
}

/*
I/O FUNCTIONS
*/
void outbyte(char c) 
{
  volatile char *COUT = (char *) 0xFFFFFFC0;
  *COUT = c;
}

char inbyte() 
{
  return 0;
}

void outfloat(float f) 
{
  volatile float *FOUT = (float *) 0xFFFFFFD0;
  *FOUT = f;
}

void outword(long l) 
{
  volatile long *DOUT = (long *) 0xFFFFFFD0;
  *DOUT = l;
}

void trap(long e)
{  
  outword(e);
  outword(CODE_FAIL);
  // hang the machine
  exit(e);  
}

#endif

/*
$Log: not supported by cvs2svn $
Revision 1.3  2008/04/26 18:07:19  sybreon
Minor cosmetic changes.

Revision 1.2  2008/04/21 12:13:12  sybreon
Passes arithmetic tests with single thread.

Revision 1.1  2008/04/11 15:32:28  sybreon
initial checkin

*/
