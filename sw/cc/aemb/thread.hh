/* $Id: thread.hh,v 1.1 2008-04-09 19:48:37 sybreon Exp $
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

namespace aemb {

  /**
  Checks to see if currently executing Thread 1
  @return true if is Thread 1
  */
  
  inline bool isThread1() 
  {
    int rmsr = aemb::getMSR();
    return ((rmsr & aemb::MSR_HTE) and (rmsr & aemb::MSR_PHA));
  }
  
  /**
  Checks to see if currently executing Thread 0
  @return true if is Thread 0
  */
  
  inline bool isThread0()
  {
    int rmsr = aemb::getMSR();
    return ((rmsr & aemb::MSR_HTE) and (not (rmsr & aemb::MSR_PHA)));
  }
  
  /**
  Checks to see if it is multi-threaded or not
  @return true if thread capable
  */
  inline bool isThreaded()
  {
    int rmsr = aemb::getMSR();
    return (rmsr & aemb::MSR_HTE);
  }
  
  // TODO: Extend this library to include threading mechanisms such as
  // semaphores, mutexes and such.
  
  
  /**
  Semaphore class
  
  Based on: Little Book of Semaphores, The - Downey, Allen B.

  Presently implemented as software solution but a hardware one may be
  required as the threads are hardware. This can be implemented using
  a specialised add/sub/load register.
  */
  
  class Semaphore {
    volatile int _sem; ///< Semaphore in Memory
  public:
    /**
    Preload the semaphore
    @param pval preload value
    */
    Semaphore(int pval) { _sem = pval; } 
    
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
  
}

#endif

/*
  $Log: not supported by cvs2svn $
*/
