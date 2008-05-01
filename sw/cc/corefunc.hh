/* $Id: corefunc.hh,v 1.3 2008-05-01 08:37:37 sybreon Exp $
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
/**
AEMB Software Verification
@file corefunc.hh

These are custom functions written to test certain hardware functions
that cannot be tested through numerical algorithms.
*/

#ifndef COREFUNC_HH
#define COREFUNC_HH

#define MAGIC 0xAE62AE62 // magic number

volatile int intr = 0;

void __attribute__ ((interrupt_handler)) interruptHandler() 
{
  int *toggle = (int *)0xFFFFFFE0;
  intr++; // flag the interrupt service routine
  *toggle = -1; // disable interrupts
}

/**
INTERRUPT TEST ROUTINE
*/

int interruptTest(int timeout)
{
  aembEnableInterrupts();
  int timer;
  for (timer=0; (timer < timeout * 100) && (intr == -1); ++timer); // delay loop
  aembDisableInterrupts();
  return (intr == 0) ? EXIT_FAILURE : EXIT_SUCCESS;
}


/**
   FSL TEST ROUTINE
*/

int xslTest (int code)
{
  // TEST FSL1 ONLY
  int FSL = code;

  asm ("PUT %0, RFSL0" :: "r"(FSL));
  asm ("GET %0, RFSL0" : "=r"(FSL));
  
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
  volatile void *alloc;
  int magic;

  alloc = malloc(size * sizeof(int)); // allocate 32 byte
  if (alloc == NULL) 
    return EXIT_FAILURE;

  *(int *)alloc = MAGIC; // write to memory
  magic = *(int *)alloc; // read from memory

  return (magic == MAGIC) ? EXIT_SUCCESS : EXIT_FAILURE;
}

#endif

/*
$Log: not supported by cvs2svn $
Revision 1.2  2008/04/28 20:30:24  sybreon
Changed to new headers.

Revision 1.1  2008/04/27 16:04:42  sybreon
Minor cosmetic changes.

*/
