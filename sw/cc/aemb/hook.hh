/* $Id: hook.hh,v 1.1 2008-04-09 19:48:37 sybreon Exp $
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

   These routines hook themselves onto the startup and ending parts of
   the main programme. In order to use it, the main programme needs to
   be compiled with optimisations turned on (at least -O1).
 */

#include "aemb/msr.hh"
#include "aemb/stack.hh"
#include "aemb/heap.hh"
#include "aemb/thread.hh"

#ifndef AEMB_HOOK_HH
#define AEMB_HOOK_HH

namespace aemb {

  void hookProgramInit() asm ("_program_init"); // hook aliasing
  void hookProgramClean() asm ("_program_clean"); // hook aliasing

  /**
  Finalisation hook
  
  This function executes during the shutdown phase after the
  finalisation routine is called. It will merge the changes made
  during initialisation.
  */
  
  void hookProgramClean()
  {     
    if (aemb::isThread1()) {    
      // unify the stack backwards
      aemb::setStack(aemb::getStack() + 
			 (aemb::getStackSize() >> 1));
      
      // FIXME: unify the heap
      
    }
  }
  
  /**
  Initialisation hook
  
  This function executes during the startup phase before the
  initialisation routine is called. It splits the heap and stack
  between the threads.
  */
  
  void hookProgramInit() 
  {
    if (aemb::isThread1()) {  // check if PHASE 1    
      // split and shift the stack
      aemb::setStack(aemb::getStack() - 
			 (aemb::getStackSize() >> 1));
      
      // FIXME: split and shift the heap
      
    }      
  }
};

#endif

/*
  $Log: not supported by cvs2svn $
*/
