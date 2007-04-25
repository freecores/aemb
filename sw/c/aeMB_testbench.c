/*
 * $Id: aeMB_testbench.c,v 1.4 2007-04-25 22:15:05 sybreon Exp $
 * 
 * AEMB Function Verification C Testbench
 * Copyright (C) 2006 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
 *  
 * This library is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation; either version 2.1 of the License, 
 * or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public 
 * License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
 *
 * DESCRIPTION
 * Runs a simple test programme that calculates fibonnaci numbers using two
 * different methods. It tests a whole gamut of operations and is tightly
 * linked to the ae68_testbench.v testbench module for verification.
 *
 * The fibonnaci code is from 
 * http://en.literateprograms.org/Fibonacci_numbers_(C)
 * 
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.3  2007/04/04 14:09:04  sybreon
 * Added initial interrupt/exception support.
 *
 * Revision 1.2  2007/04/04 06:07:45  sybreon
 * Fixed C code bug which passes the test
 *
 * Revision 1.1  2007/03/09 17:41:57  sybreon
 * initial import
 *
 */

/* Special Prototypes */
void int_call_func (); // __attribute__((save_volatiles));
void int_handler_func () __attribute__ ((interrupt_handler));

/* Interrupt Handler */
void int_handler_func () {
  int_call_func();
}

void int_call_func () {
  int *p;
  p = 0x88888888;
  *p = 0x52544E49; // "INTR"
}

/* Recursive Version */

unsigned int slowfib(unsigned int n)
{
  return n < 2 ? n : slowfib(n-1) + slowfib(n-2);
}

/* Iterative Version */

unsigned int fastfib(unsigned int n)
{
  unsigned int a[3];
  unsigned int *p=a;
  unsigned int i;
  
  for(i=0; i<=n; ++i) {
    if(i<2) *p=i;
    else {
      if(p==a) *p=*(a+1)+*(a+2);
      else if(p==a+1) *p=*a+*(a+2);
      else *p=*a+*(a+1);
    }
    if(++p>a+2) p=a;
  }
  
  return p==a?*(p+2):*(p-1);
}

/* Various Test */

int main() {
  unsigned int n;
  unsigned int fib_fast, fib_slow;  
  unsigned int fib_lut32[] = {0,
			      1,
			      1,
			      2,
			      3,
			      5,
			      8,
			      13,
			      21,
			      34,
			      55,
			      89,
			      144,
			      233};  

  unsigned short fib_lut16[] = {0,
				1,
				1,
				2,
				3,
				5,
				8,
				13,
				21,
				34,
				55,
				89,
				144,
				233};
  
  unsigned char fib_lut8[] = {0,
			      1,
			      1,
			      2,
			      3,
			      5,
			      8,
			      13,
			      21,
			      34,
			      55,
			      89,
			      144,
			      233};
  
  for (n=0;n<14;n++) {
    fib_slow = slowfib(n);    
    fib_fast = fastfib(n);
    while ((fib_slow != fib_fast) || 
	   (fib_fast != fib_lut32[n]) || 
	   (fib_fast != fib_lut16[n]) || 
	   (fib_fast != fib_lut8[n])) {
      // "FAIL" 
      fib_lut32[n] = 0x4C494146;
    }
    // "PASS"
    fib_lut32[n] = 0x53534150;
  }      

  return 0;  
}

