/* $Id: heap.hh,v 1.1 2008-04-09 19:48:37 sybreon Exp $
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
   Basic heap related functions
   @file heap.hh  
 */

#ifndef AEMB_HEAP_HH
#define AEMB_HEAP_HH

namespace aemb {

  /**
  Extracts the heap size from the linker
  @return heap size
  */
  
  inline int getHeapSize()
  {
    int tmp;
    asm ("la %0, r0, _HEAP_SIZE":"=r"(tmp));
    return tmp;
  }
  
  /**
  Extracts the heap end from the linker
  @return heap end
  */
  
  inline int getHeapEnd()
  {
    int tmp;
    asm ("la %0, r0, _heap_end":"=r"(tmp));
    return tmp;
  }
  
  /**
  Extracts the heap top from the linker
  @return heap top
  */
  
  inline int getHeapTop()
  {
    int tmp;
    asm ("la %0, r0, _heap":"=r"(tmp));
    return tmp;
  }
}
#endif
  
/*
  $Log: not supported by cvs2svn $
*/
