/* $Id: libaemb.h,v 1.1 2007-12-11 00:44:04 sybreon Exp $
**
** AEMB2 CUSTOM LIBRARY
** 
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
** License along with AEMB. If not, see <http:**www.gnu.org/licenses/>.
*/

#ifndef LIBAEMB_H
#define LIBAEMB_H

#define AEMB_TXE 0x10000000
#define AEMB_TX0 0x20000000
#define AEMB_TX1 0x40000000
#define AEMB_BIP 0x00000008

void aemb_reboot () asm ("_program_init");
inline void aemb_enable_interrupt ();
inline void aemb_disable_interrupt ();
inline int aemb_isthread1();
inline int aemb_isthread0();

/*!
* Assembly macro to enable MSR_IE
*/
void aemb_enable_interrupt ()
{
  int msr, tmp;
  asm volatile ("mfs %0, rmsr;"
		"ori %1, %0, 0x02;"
		"mts rmsr, %1;"
		: "=r"(msr)
		: "r" (tmp)
		);
}

/*!
* Assembly macro to disable MSR_IE
*/
void aemb_disable_interrupt ()
{
  int msr, tmp;
  asm volatile ("mfs %0, rmsr;"
		"andi %1, %0, 0xFD;"
		"mts rmsr, %1;"
		: "=r"(msr)
		: "r" (tmp)
		);
}

/*!
* Bootstrap Hook Override

* It re-sizes the stack, allocates half to each thread and reboots.
*/

void aemb_reboot ()
{
  asm volatile (// Checks for TXE & BIP flags
		"mfs     r4, rmsr;"
		"andi    r3, r4, 0x10000008;"
		"andi    r6, r4, 0x40000000;"
		"xori    r18, r3, 0x10000000;"
		"beqi    r18, 20;"
		"andi    r4, r4, -9;"
		"mts     rmsr, r4;"

		// Returns when TXE=0 || BIP=1
		"rtsd    r15, 8;"
		"nop;"

		// Calculate new stack
		"addik   r3, r0, _STACK_SIZE;"  
		"addik   r5, r0, _stack;"
		"beqid   r6, 12;"        
		"sra     r3, r3;"
		"rsubk   r5, r3, r5;"
		"addik   r5, r5, -16;"

		// Re-allocate stack
		"or      r1, r0, r5;"
		"ori     r4, r4, 8;"
		"mts     rmsr, r4;"

		// Reboot
		"brlid   r15, _crtinit;" 
		"nop;"
		"brai    exit;" 
		);  
}

/*
void aemb_reboot () 
{ 
  int stk_end, stk_siz;
  int msr, tmp;
  
  asm volatile ("mfs %0, rmsr;":"=r"(msr));
 
  if ((msr & AEMB_BIP) || !(msr & AEMB_TXE)) 
    {
      msr &= ~AEMB_BIP;
      asm volatile ("mts rmsr, %0;"::"r"(msr));
    }
  else
    {
      asm ("la %0, r0, _stack;" : "=r"(stk_end));
      asm ("la %0, r0, _STACK_SIZE;" : "=r"(stk_siz));

      if (msr & AEMB_TX1) stk_end -= (stk_siz >> 1);	  

      stk_end -= 16;	  

      asm ("or r1, r0, %0;" :: "r"(stk_end));

      msr |= AEMB_BIP;
      asm volatile ("mts rmsr, %0;"::"r"(msr));

      asm ("brlid r15, _crtinit;"
	   "nop;"
	   "brai exit;"
	   );
    }    
}
*/

int aemb_isthread1 ()
{
  int msr;
  asm volatile ("mfs %0, rmsr;":"=r"(msr));
  return (msr & AEMB_TX1);  
}

int aemb_isthread0 ()
{
  int msr;
  asm volatile ("mfs %0, rmsr;":"=r"(msr));
  return (msr & AEMB_TX0);  
}

#endif

/* $Log: not supported by cvs2svn $ */
