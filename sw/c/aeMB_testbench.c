/*
 * $Id: aeMB_testbench.c,v 1.1 2007-03-09 17:41:57 sybreon Exp $
 * 
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
 * Controls the state of the processor.
 * 
 * HISTORY
 * $Log: not supported by cvs2svn $
 */

#include <stdlib.h>

int main () {

  int a;
  int b;
  int c[10];
  register int i;

  a = rand();
  b = rand();

  c[0] = add_test(a,b);
  c[1] = sub_test(a,b);
  c[2] = mul_test(a,b);
  c[3] = div_test(a,b);

  for (i=0;i<5;i++) {
	c[i+5] = c[i];
  }

  return c[3];
}

// RES = B - A
int sub_test(int a, int b) { return (b-a); }

// RES = A + B
int add_test(int a, int b) { return (a+b); }

// RES = A * B
int mul_test(int a, int b) { return (a*b); }

// RES = B / A
int div_test(int a, int b) { return (b/a); }
