/* $Id: thread.hh,v 1.5 2008-04-20 16:35:53 sybreon Exp $
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
   Basic thread functions
   @file thread.hh  

   These functions deal with the various hardware threads. It also
   provides simple mechanisms for toggling semaphores.
 */

#include "aemb/msr.hh"

#ifndef AEMB_THREAD_HH
#define AEMB_THREAD_HH

#ifdef __cplusplus
namespace aemb {
#endif

  /**
     Checks to see if currently executing Thread 1
     @return true if is Thread 1
  */
  
  inline bool isThread1() 
  {
    int rmsr = getMSR();
    return ((rmsr & MSR_HTX) && (rmsr & MSR_PHA));
  }
  
  /**
     Checks to see if currently executing Thread 0
     @return true if is Thread 0
  */
  
  inline bool isThread0()
  {
    int rmsr = getMSR();
    return ((rmsr & MSR_HTX) && (!(rmsr & MSR_PHA)));
  }
  
  /**
     Checks to see if it is multi-threaded or not.
     @return true if thread capable
  */
  inline bool isThreaded()
  {
    int rmsr = getMSR();
    return (rmsr & MSR_HTX);
  }

  /**
     Hardware Mutex Signal.  
     Unlock the hardware mutex, which is unlocked on reset.
   */
  inline void signalMutex()
  {
    int tmp;
    asm volatile ("msrclr %0, 0x0010":"=r"(tmp));
  }

  /**
     Hardware Mutex Wait.
     Waits until the hardware mutex is unlocked.
   */
  inline void waitMutex()
  {
    int rmsr;
    do 
      {
	asm volatile ("msrset %0, 0x0010":"=r"(rmsr));	
      }
    while (rmsr & MSR_MTX);    
  }
    
  // TODO: Extend this library to include threading mechanisms such as
  // semaphores, mutexes and such.

  /**
     Semaphore class.     
     Presently implemented as software solution but a hardware one may be
     required as the threads are hardware.
  */
  
  class semaphore {
  private:
    volatile int _sem; ///< Semaphore in Memory
  public:
    /**
       Preload the semaphore
       @param pval preload value
    */
    semaphore(int pval) { _sem = pval; } 
    
    /**
       Increment the semaphore
    */
    inline void signal() { _sem++; }
    
    /**
       Decrement the semaphore and block if < 0
    */
    inline void wait() { _sem--; while (_sem < 0); } // block while
						     // semaphore is
						     // negative
  };

  semaphore __mutex_rendezvous0(0); ///< internal rendezvous mutex
  semaphore __mutex_rendezvous1(1); ///< internal rendezvous mutex

  /**
     Implements a simple rendezvous mechanism
   */

  void rendezvous()
  {
    if (isThread1())
      {
	__mutex_rendezvous0.wait();
	__mutex_rendezvous1.signal();
      }
    else
      {
	__mutex_rendezvous0.signal();
	__mutex_rendezvous1.wait();
      }
  }

#ifdef __cplusplus  
}
#endif

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.4  2008/04/12 14:07:26  sybreon
  added a rendezvous function

  Revision 1.3  2008/04/11 15:53:24  sybreon
  changed MSR bits

  Revision 1.2  2008/04/11 11:34:30  sybreon
  changed semaphore case

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
