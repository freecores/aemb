/* $Id: stdio.hh,v 1.3 2008-04-26 19:31:35 sybreon Exp $
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
   Basic standard I/O functions
   @file stdio.hh  

   These functions provide function prototypes for outbyte/inbyte
   which are required by the linker during compile time. These
   functions can be defined anywhere else in code but should not be
   inlined.
 */

#ifndef AEMB_STDIO_HH
#define AEMB_STDIO_HH

#ifdef __cplusplus
extern "C" {
#endif
  
  /**
     Default stdout prototype.
     @param c char

     This is used to output characters to LCD or UART.
   */
  void outbyte(char c);

  /**
     Default stdin prototype.
     @return char

     This is used to read characters in from UART or keyboard.
   */
  char inbyte();

#ifdef __cplusplus
}
#endif

#endif

/*
  $Log: not supported by cvs2svn $
  Revision 1.2  2008/04/26 18:05:22  sybreon
  Minor cosmetic changes.

  Revision 1.1  2008/04/09 19:48:37  sybreon
  Added new C++ files

*/
