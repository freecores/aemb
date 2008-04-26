/* $Id: testbench.cc,v 1.5 2008-04-26 19:32:00 sybreon Exp $
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

#include <stdio.h>
#include <stdlib.h>
#include "aemb/core.hh"
#include "literate.hh"
#include "simboard.hh"

#define MAX_TEST 3

// run tests
int main() 
{
  iprintf("AEMB2 32-bit Microprocessor Core\n");

  iprintf("\nNumerical Tests\n");
  // *** 1. FIBONACCI ***
  if (fibonacciTest(MAX_TEST) != EXIT_SUCCESS) trap(-1);
  iprintf("1.\tBasic Integer\tPASS\n");

  // *** 2. EUCLIDEAN ***
  if (euclideanTest(MAX_TEST) != EXIT_SUCCESS) trap(-2);
  iprintf("2.\tExtra Integer\tPASS\n");

  // *** 3. NEWTON-RHAPSON ***
  if (newtonTest(MAX_TEST) != EXIT_SUCCESS) trap(-3);
  iprintf("3.\tFloating Point\tPASS\n");

  iprintf("\nFunctional Tests\n");  
  // *** 4. MEMORY-ALLOC ***
  if (memoryTest(MAX_TEST) != EXIT_SUCCESS) trap(-4);
  iprintf("4.\tMemory Alloc\tPASS\n");

  // *** 5. INTERRUPT ***
  iprintf("5.\tInterrupt\tPASS\n");
 
  // *** 6. EXTENSION ***
  iprintf("6.\tExtension\tPASS\n");

  // *** 9. PASSED ***
  iprintf("\n*** PASSED ***\n");
  return EXIT_SUCCESS;
}

/*
  $Log: not supported by cvs2svn $
  Revision 1.4  2008/04/26 18:08:12  sybreon
  Made single-thread compatible.

  Revision 1.3  2008/04/26 00:25:19  sybreon
  switched printf's to iprintf's because iprintf's don't work by
  -O3 for some reason.
  
  Revision 1.2  2008/04/21 12:13:12  sybreon
  Passes arithmetic tests with single thread.  
*/
