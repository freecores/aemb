/* $Id: stack.hh,v 1.3 2008-04-23 14:19:39 sybreon Exp $
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
   Basic stack related functions
   @file stack.hh  
 */

#ifndef AEMB_STACK_HH
#define AEMB_STACK_HH

#ifdef __cplusplus
namespace aemb {
#endif

  /**
  Reads the size of the memory space allocated for the stack in bytes.
  @return size of stack
  */
  
  inline int getStackSize()
  {
    int tmp;
    asm ("la %0, r0, _STACK_SIZE":"=r"(tmp));
    return tmp;
  }
  
  /**
  Reads the end of the memory space allocated for the stack.
  @return end of stack
  */
  
  inline int getStackEnd()
  {
    int tmp;
    asm ("la %0, r0, _stack_end":"=r"(tmp));
    return tmp;
  }
  
  /**
  Reads the top of the memory space allocated for the stack.
  @return top of stack
  */
  
  inline int getStackTop()
  {
    int tmp;
    asm ("la %0, r0, _stack":"=r"(tmp));
    return tmp;
  }
  
  /**
  Reads register R1 which is the designated stack pointer.  
  @return stack pointer
  */
  
  inline int getStack()
  {
    int tmp;
    asm ("addk %0, r0, r1":"=r"(tmp));
    return tmp;
  }
  
  /**
  Sets register R1 to the new stack pointer.
  @param stk new stack pointer
  */
  
  inline void setStack(int stk)
  {
    asm ("addk r1, r0, %0"::"r"(stk));
  }

#ifdef __cplusplus
}
#endif

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.2  2008/04/20 16:35:53  sybreon
  Added C/C++ compatible #ifdef statements

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
