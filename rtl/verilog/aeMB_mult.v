// $Id: aeMB_mult.v,v 1.2 2007-11-03 08:34:55 sybreon Exp $
//
// AEMB SINGLE CYCLE 32'BIT MULTIPLIER
//
// Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
//  
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2.1 of
// the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//  
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//
// $Log: not supported by cvs2svn $

module aeMB_mult (/*AUTOARG*/
   // Outputs
   rRES_MUL,
   // Inputs
   rOPA, rOPB
   );

   // INTERNAL
   output [31:0] rRES_MUL;

   input [31:0]  rOPA, rOPB;

   assign 	 rRES_MUL = (rOPA * rOPB);   
   
endmodule // aeMB_mult
