/* $Id: hook.hh,v 1.7 2008-04-26 19:31:35 sybreon Exp $
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

#ifdef __cplusplus
namespace aemb {
  extern "C" {
#endif

    void _program_init();
    void _program_clean();
    
    // newlib locks
    void __malloc_lock(struct _reent *reent);
    void __malloc_unlock(struct _reent *reent);
    //void __env_lock(struct _reent *reent);
    //void __env_unlock(struct _reent *reent);
    
#ifdef __cplusplus
  }
#endif
  
  /**
     Finalisation hook
     
     This function executes during the shutdown phase after the
     finalisation routine is called. It will merge the changes made
     during initialisation.
  */  

  void _program_clean()
  {     
    waitMutex(); // enter critical section

    // unify the stack backwards for thread 1
    if (isThread0())       
      {	
	// TODO: Unify the stack
	setStack(getStack() + (getStackSize() >> 1));        
      }   
    
    signalMutex(); // exit critical section
  }
  
  /**
     Initialisation hook
  
     This function executes during the startup phase before the
     initialisation routine is called. It splits the stack between the
     threads. For now, it will lock up T0 for compatibility purposes.
  */  

  void _program_init()
  {
    waitMutex(); // enter critical section

    // split and shift the stack for thread 1
    if (isThread0()) // main thread
      {
	// NOTE: Dupe the stack otherwise it will FAIL!	
	dupStack((int *)setStack(getStack() - (getStackSize() >> 1)), 
		  (int *)getStack(), 
		  (int *)getStackTop);	
	signalMutex(); // exit critical section
	while (1) asm volatile ("nop"); // lock thread
      }

    signalMutex(); // exit critical section
  }

  semaphore __malloc_mutex = 1;  

  /**
     Heap Lock

     This function is called during malloc() to lock out the shared
     heap to avoid data corruption.
   */

  void __malloc_lock(struct _reent *reent)
  {
    waitMutex();   
  }

  /**
     Heap Unlock

     This function is called during malloc() to indicate that the
     shared heap is now available for another thread.
  */

  void __malloc_unlock(struct _reent *reent)
  {
    signalMutex();
  }

#ifdef __cplusplus
}
#endif

#endif

#ifndef __OPTIMIZE__
// The main programme needs to be compiled with optimisations turned
// on (at least -O1). If not, the MUTEX value will be written to the
// same RAM location, giving both threads the same value.
OPTIMISATION_REQUIRED XXX
#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.6  2008/04/26 18:04:31  sybreon
  Updated software to freeze T0 and run T1.

  Revision 1.5  2008/04/23 14:19:39  sybreon
  Fixed minor bugs.
  Initial use of hardware mutex.

  Revision 1.4  2008/04/20 16:35:53  sybreon
  Added C/C++ compatible #ifdef statements

  Revision 1.3  2008/04/12 13:46:02  sybreon
  Added malloc() lock and unlock routines

  Revision 1.2  2008/04/11 15:20:31  sybreon
  added static assert hack

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
