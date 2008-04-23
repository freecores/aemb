/* $Id: hook.hh,v 1.5 2008-04-23 14:19:39 sybreon Exp $
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
    void _program_init();
    void _program_clean();
    void __malloc_lock();
    void __malloc_unlock();
    void __env_lock();
    void __env_unlock();

  }  
#else
  void _program_init();
  void _program_clean();
  void __malloc_lock();
  void __malloc_unlock();
  void __env_lock();
  void __env_unlock();  
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
    if (isThread1())       
      {	
	setStack(getStack() + (getStackSize() >> 1));        
      }   
    
    signalMutex(); // exit critical section
  }
  
  /**
     Initialisation hook
  
     This function executes during the startup phase before the
     initialisation routine is called. It splits the stack between the
     threads.
  */  
  void _program_init()
  {
    waitMutex(); // enter critical section

    // split and shift the stack for thread 1
    if (isThread1()) 
      {
	setStack(getStack() - (getStackSize() >> 1));        
      }

    signalMutex(); // exit critical section
  }

  semaphore __malloc_mutex = 1;  

  /**
     Heap Lock

     This function is called during malloc() to lock out the shared
     heap to avoid data corruption.
   */
  void __malloc_lock()
  {
    waitMutex();   
  }

  /**
     Heap Unlock

     This function is called during malloc() to indicate that the
     shared heap is now available for another thread.
  */
  void __malloc_unlock()
  {
    signalMutex();
  }

#ifdef __cplusplus  
}
#endif

#endif

#ifndef __OPTIMIZE__
// The main programme needs to be compiled with optimisations turned
// on (at least -O1).
OPTIMISATION_REQUIRED XXX
#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.4  2008/04/20 16:35:53  sybreon
  Added C/C++ compatible #ifdef statements

  Revision 1.3  2008/04/12 13:46:02  sybreon
  Added malloc() lock and unlock routines

  Revision 1.2  2008/04/11 15:20:31  sybreon
  added static assert hack

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
