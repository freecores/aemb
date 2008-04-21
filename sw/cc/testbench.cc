/* $Id: testbench.cc,v 1.2 2008-04-21 12:13:12 sybreon Exp $
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

#include <cstdio>
#include <cstdlib>
#include "aemb/core.hh"
#include "literate.hh"
#include "simboard.hh"
#include <vector>

#define MAX_TEST 5

int thread1() // runs math tests
{
  // *** 1. FIBONACCI *** //
  outword (0xF1B07357);
  if (fibonacciTest(MAX_TEST) != EXIT_SUCCESS) trap(-1);

  // *** 2. EUCLIDEAN *** //
  outword (0xEC1D7357);
  if (euclideanTest(MAX_TEST) != EXIT_SUCCESS) trap(-2);

  // *** 3. NEWTON-RHAPSON *** //
  outword (0xF10A7357);
  if (newtonTest(MAX_TEST) != EXIT_SUCCESS) trap(-3);

  outword (0xAAAAAAAA);
  aemb::rendezvous(); // Wait for other thread
  return 0;
}


int thread0() // runs core tests
{
  // *** 1. MALLOC TEST ***/
  //if (memoryTest(100) != EXIT_SUCCESS) trap(1);

  // *** 2. INTERRUPT TEST *** //
  //if (interruptTest(10000) != EXIT_SUCCESS) trap(2);

  // *** 3. XSL *** //
  //if (xslTest(0xBADCAB1E) != EXIT_SUCCESS) trap(3);

  outword (0xBBBBBBBB);
  aemb::rendezvous(); // Wait for other thread
  return 0;
}

int threads()
{
  if (aemb::isThread1())  
    return thread1(); 
  else
    return thread0();
}

// run tests
int main() 
{
  threads();  
  return EXIT_SUCCESS;
}

/*
$Log: not supported by cvs2svn $
*/
