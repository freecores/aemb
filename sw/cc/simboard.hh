/* $Id: simboard.hh,v 1.1 2008-04-11 15:32:28 sybreon Exp $
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
#include <cstdlib>

#ifndef SIMBOARD_HH
#define SIMBOARD_HH

#define CODE_FAIL 0xDEADBEEF
#define CODE_PASS 0xCAFEF00D


/*
INTERRUPT TESTS
*/

volatile int intr = -1;

void __attribute__ ((interrupt_handler)) interruptHandler() 
{
  intr = 0; // flag the interrupt
}

int interruptTest(int timeout)
{
  aemb::enableInterrupts();
  for (int timer=0; (timer < timeout) && (intr == -1); ++timer); // delay loop
  aemb::disableInterrupts();
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
  while(true)
    {
      asm volatile("nop");
    }
}

void pass()
{
  outword(CODE_PASS);
}

char inbyte() 
{
  return 0;
}

#endif

/*
$Log: not supported by cvs2svn $
*/
