/* $Id: bootstrap.c,v 1.1 2008-06-23 22:18:04 sybreon Exp $
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

#define SRAM_BASE (int *)0x80000000
#define SRAM_SIZE 0x10000

int memtest () 
{
  memTestDataBus(SRAM_BASE);
  memTestAddrBus(SRAM_BASE, SRAM_SIZE);  
  memTestFullDev(SRAM_BASE, SRAM_SIZE);  
}

/*
  $Log: not supported by cvs2svn $
 */
