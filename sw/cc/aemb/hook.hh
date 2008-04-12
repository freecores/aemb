/* $Id: hook.hh,v 1.3 2008-04-12 13:46:02 sybreon Exp $
** 
** AEMB2 HI-PERFORMANCE CPU 
** Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
**  
** This file is part of AEMB.
**
** AEMB is free software: you can redistribute it and/or modify it
** under the terms of the GNU Lesser General Public License as
** published by the Free Software Foundation, either version 3 of the
** License, or (at your option) any later version.
**
** AEMB is distributed in the hope that it will be useful, but WITHOUT
** ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public
** License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
*/

/**
   Basic begin/end hooks
   @file hook.hh  

   These routines hook themselves onto parts of the main programme to
   enable the hardware threads to work properly. 
 */

#include "aemb/stack.hh"
#include "aemb/heap.hh"
#include "aemb/thread.hh"

#ifndef AEMB_HOOK_HH
#define AEMB_HOOK_HH

namespace aemb {

  extern "C" void _program_init();
  extern "C" void _program_clean();
  extern "C" void __malloc_lock();
  extern "C" void __malloc_unlock();
  extern "C" void __env_lock();
  extern "C" void __env_unlock();

  /**
     Finalisation hook
     
     This function executes during the shutdown phase after the
     finalisation routine is called. It will merge the changes made
     during initialisation.
  */
  
  void _program_clean()
  {     
    // unify the stack backwards for thread 1
    if (aemb::isThread1()) 
      {
	aemb::setStack(aemb::getStack() + (aemb::getStackSize() >> 1));        
      }
  }
  
  /**
     Initialisation hook
  
     This function executes during the startup phase before the
     initialisation routine is called. It splits the stack between the
     threads.
  */
  
  void _program_init()
  {
    // split and shift the stack for thread 1
    if (aemb::isThread1()) 
      {
	aemb::setStack(aemb::getStack() - (aemb::getStackSize() >> 1));   
      }
    else
      {
	for(int i=0; i<10; ++i) 
	  {
	    asm volatile ("nop"); // delay loop to offset thread 0
	  }
      }
  }

  // FIXME: Implement with a single hardware mutex

  semaphore __malloc_mutex(1); ///< private mutex

  /**
     Heap Lock

     This function is called during malloc() to lock out the shared
     heap to avoid data corruption.
   */

  void __malloc_lock()
  {
    __malloc_mutex.wait();
  }

  /**
     Heap Unlock

     This function is called during malloc() to indicate that the
     shared heap is now available for another thread.
  */

  void __malloc_unlock()
  {
    __malloc_mutex.signal();
  }
  
}

#endif

#ifndef __OPTIMIZE__
// The main programme needs to be compiled with optimisations turned
// on (at least -O1).
OPTIMISATION_REQUIRED XXX
#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.2  2008/04/11 15:20:31  sybreon
  added static assert hack

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
