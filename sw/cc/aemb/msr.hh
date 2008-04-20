/* $Id: msr.hh,v 1.5 2008-04-20 16:35:53 sybreon Exp $
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
   Basic MSR functions
   @file msr.hh  
   
   These functions provide read/write access to the Machine Status
   Register. It also contains the bit definitions of the register.
 */

#ifndef AEMB_MSR_HH
#define AEMB_MSR_HH

#ifdef __cplusplus
namespace aemb {
#endif

  const int MSR_BE  = 0x00000001; ///< Buslock Enable
  const int MSR_IE  = 0x00000002; ///< Interrupt Enable
  const int MSR_C   = 0x00000004; ///< Arithmetic Carry
  const int MSR_BIP = 0x00000008; ///< Break in Progress
    
  const int MSR_MTX = 0x00000010; ///< Hardware Mutex
  const int MSR_ICE = 0x00000020; ///< Instruction Cache Enable
  const int MSR_DZ  = 0x00000040; ///< Division by Zero
  const int MSR_DCE = 0x00000080; ///< Data Cache Enable
  
  //const int MSR_HTE = 0x10000000; ///< Hardware Threads Enable
  const int MSR_PHA = 0x20000000; ///< Hardware Thread Phase
  const int MSR_HTX = 0x40000000; ///< Hardware Threads Extension
  const int MSR_CC  = 0x80000004; ///< Carry Copy

  /**
     Read the value of the MSR register
     @return register contents
  */
  
  inline int getMSR()
  {
    int rmsr;
    asm volatile ("mfs %0, rmsr":"=r"(rmsr));
    return rmsr;
  }
  
  /**
     Write a value to the MSR register
     @param rmsr value to write
  */  

  inline void putMSR(int rmsr) 
  { 
    asm volatile ("mts rmsr, %0"::"r"(rmsr)); 
  }


  /**
     Read and clear the MSR
     @param rmsk clear mask
     @return msr value
   */
  inline int clrMSR(const short rmsk)
  {
    int tmp;
    asm volatile ("msrclr %0, %1":"=r"(tmp):"K"(rmsk));
    return tmp;
  }

  /**
     Read and set the MSR
     @param rmsk set mask
     @return msr value
   */
  inline int setMSR(const short rmsk)
  {
    int tmp;
    asm volatile ("msrset %0, %1":"=r"(tmp):"K"(rmsk));
    return tmp;
  }

  /** Enable global interrupts */
  inline void enableInterrupts() 
  { 
    putMSR(getMSR() | MSR_IE);
  }

  /** Disable global interrupts */
  inline void disableInterrupts() 
  { 
    putMSR(getMSR() & ~MSR_IE); 
  }

  /** Enable data caches */
  inline void enableDataCache() 
  { 
    putMSR(getMSR() | MSR_DCE); 
  }

  /** Disable data caches */  
  inline void disableDataCache()  
  { 
    putMSR(getMSR() & ~MSR_DCE); 
  }

  /** Enable inst caches */
  inline void enableInstCache() 
  { 
    putMSR(getMSR() | MSR_ICE); 
  }

  /** Disable inst caches */  
  inline void disableInstCache()  
  { 
    putMSR(getMSR() & ~MSR_ICE); 
  }

#ifdef __cplusplus
}
#endif

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.4  2008/04/11 15:53:03  sybreon
  changed MSR bits

  Revision 1.3  2008/04/11 12:24:12  sybreon
  added cache controls

  Revision 1.2  2008/04/11 11:48:37  sybreon
  added interrupt controls (may need to be factorised out)

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
