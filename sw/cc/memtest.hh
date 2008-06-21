/* $Id: memtest.hh,v 1.2 2008-06-21 10:01:35 sybreon Exp $
** 
** MEMORY TEST FUNCTIONS
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

#ifndef MEMTEST_HH
#define MEMTEST_HH

/**
   WALKING ONES TEST
   Checks individual bit lines in O(1)
   http://www.embedded.com/2000/0007/0007feat1list1.htm
*/

inline int memtestDataBus(volatile int *ram)
{
  for (int i=1; i!=0; i<<=1)
    {
      *ram = i; // write test value
      if (*ram != i) // read back test
	return i;      
    }
  return 0; // 0 if success  
}

/**
   POWERS OF TWO TEST
   Checks the address lines
   http://www.embedded.com/2000/0007/0007feat1list2.htm
 */

inline int memtestAddressBus(volatile int *ram, int len)
{  
  const int p = 0xAAAAAAAA;
  const int q = 0x55555555;
  
  // prefill memory
  for (int i=1; (i & (len-1))!=0 ; i<<=1)
    {
      ram[i] = p;
    }

  // check 1 - stuck high
  ram[0] = q;
  for (int i=1; (i & (len-1))!=0 ; i<<=1)
    {
      if (ram[i] != p)
	return ram[i];
    }
  ram[0] = p;

  // check 2 - stuck low
  for (int j=1; (j & (len-1))!=0 ; j<<=1)
    {
      ram[j] = q;
      for (int i=1; (i & (len-1))!=0 ; i<<=1)
	{
	  if ((ram[i] != p) && (i != j))
	    return ram[i];
	}
      ram[j] = p;
    }

  return 0;
}

/**
   INCREMENT TEST
   Checks the entire memory device
   http://www.embedded.com/2000/0007/0007feat1list1.htm
 */

inline int memtestDeviceMem(volatile int *ram, int len)
{
  // prefill the memory
  for (int p=1, i=0; i<len; ++p, ++i)
    {
      ram[i] = p;      
    }  

  // pass 1 - check and invert
  for (int p=1, i=0; i<len; ++p, ++i)
    {
      if (ram[i] != p)
	return ram[i];      
      ram[i] = ~p;      
    }
  
  // pass 2 - check and zero
  for (int p=1, i=0; i<len; ++p, ++i)
    {
      if (ram[i] != ~p)
	return ram[i];      
      ram[i] = 0;      
    }  

  return 0;  
}

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.1  2008/06/20 17:51:23  sybreon
  initial import

 */
