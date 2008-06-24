/* $Id: bootstrap.c,v 1.2 2008-06-24 00:45:36 sybreon Exp $
** 
** BOOTSTRAP
** Copyright (C) 2008 Shawn Tan <shawn.tan@aeste.net>
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

#include "memtest.hh"

#define SRAM_BASE 0x00008000
#define SRAM_SIZE 0x8000
#define BOOT_BASE 0x00004000

/**
   MEMORY TEST
 */

static inline int memtest (int base, int len) 
{
  return ( 
#ifdef TEST_LONG
	  (memTestDataBus(base) != 0) ||
	  (memTestAddrBus(base, len) != 0) ||
	  (memTestFullDev(base, len) != 0) // takes long time
#else
	  (memTestDataBus(base) != 0) ||
	  (memTestAddrBus(base, len) != 0)
#endif
	   ) ? 0 : -1;
}

static inline void runboot(int base)
{
  asm volatile ("brai %0"::"i"(base));
}

int main ()
{
  if (memtest(SRAM_BASE, SRAM_SIZE) == 0)
    runboot(BOOT_BASE);
  else
    while (1) asm volatile ("");  
}

/*
  $Log: not supported by cvs2svn $
  Revision 1.1  2008/06/23 22:18:04  sybreon
  initial import

 */
