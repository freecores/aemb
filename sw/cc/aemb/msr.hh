/* $Id: msr.hh,v 1.7 2008-04-26 19:31:35 sybreon Exp $
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

#define MSR_BE   (1 << 0) ///< Buslock Enable
#define MSR_IE   (1 << 1) ///< Interrupt Enable
#define MSR_C    (1 << 2) ///< Arithmetic Carry
#define MSR_BIP  (1 << 3) ///< Break in Progress
    
#define MSR_MTX  (1 << 4) ///< Hardware Mutex
#define MSR_ICE  (1 << 5) ///< Instruction Cache Enable
#define MSR_DZ   (1 << 6) ///< Division by Zero
#define MSR_DCE  (1 << 7) ///< Data Cache Enable
  
#define MSR_PHA  (1 << 29) ///< Hardware Thread Phase
#define MSR_HTX  (1 << 30) ///< Hardware Threads Extension
#define MSR_CC   (1 << 31) ///< Carry Copy

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
    //asm volatile ("msrclr %0, %1":"=r"(tmp):"K"(rmsk):"memory");
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
    //asm volatile ("msrset %0, %1":"=r"(tmp):"K"(rmsk):"memory");
    return tmp;
  }

  /** Enable global interrupts */
  inline void enableInterrupts() 
  { 
    asm volatile ("msrset r0, %0"::"K"(MSR_IE):"memory");
  }

  /** Disable global interrupts */
  inline void disableInterrupts() 
  { 
    asm volatile ("msrclr r0, %0"::"K"(MSR_IE));
  }

  /** Enable data caches */
  inline void enableDataCache() 
  { 
    asm volatile ("msrset r0, %0"::"K"(MSR_DCE));
  }

  /** Disable data caches */  
  inline void disableDataCache()  
  { 
    asm volatile ("msrclr r0, %0"::"K"(MSR_DCE));
  }

  /** Enable inst caches */
  inline void enableInstCache() 
  { 
    asm volatile ("msrset r0, %0"::"K"(MSR_ICE));
  }

  /** Disable inst caches */  
  inline void disableInstCache()  
  { 
    asm volatile ("msrclr r0, %0"::"K"(MSR_ICE));
  }

#ifdef __cplusplus
}
#endif

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.6  2008/04/26 18:05:22  sybreon
  Minor cosmetic changes.

  Revision 1.5  2008/04/20 16:35:53  sybreon
  Added C/C++ compatible #ifdef statements

  Revision 1.4  2008/04/11 15:53:03  sybreon
  changed MSR bits

  Revision 1.3  2008/04/11 12:24:12  sybreon
  added cache controls

  Revision 1.2  2008/04/11 11:48:37  sybreon
  added interrupt controls (may need to be factorised out)

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
