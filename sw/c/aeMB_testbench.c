/*
 * $Id: aeMB_testbench.c,v 1.2 2007-04-04 06:07:45 sybreon Exp $
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
 * Revision 1.1  2007/03/09 17:41:57  sybreon
 * initial import
 *
 */

/* Special Prototypes */
void int_call_func () __attribute__((save_volatiles));
void int_handler_func () __attribute__ ((interrupt_handler));

/* Interrupt Handler */
void int_handler_func () {
  int_call_func();
}

void int_call_func () {
  while (1) {}
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

/* Compare the Results */

int main() {
  unsigned int n;
  unsigned int fib_fast, fib_slow;  
  unsigned int fib_lut[] = {0,
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
			    233,
			    377,
			    610,
			    987,
			    1597,
			    2584,
			    4181,
			    6765,
			    10946,
			    17711,
			    28657,
			    46368,
			    75025,
			    121393,
			    196418,
			    317811,
			    514229,
			    832040,
			    1346269,
			    2178309,
			    3524578,
			    5702887};  
  
  for (n=0;n<35;n++) {
    fib_slow = slowfib(n);    
    fib_fast = fastfib(n);
    while ((fib_fast != fib_lut[n]) || (fib_slow != fib_fast)) {
      fib_lut[n] = 0x00ED17FA;
    }
  }    
  
  return fib_fast;
}
