/* $Id: aeMB2_mult.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
**
** AEMB2 EDK 6.2 COMPATIBLE CORE
** Copyright (C) 2004-2008 Shawn Tan <shawn.tan@aeste.net>
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

/**
 * Two Cycle Multiplier Unit
 * @file aeMB2_mult.v
 
 * This implements a 2 cycle multipler to increase clock speed. The
   multiplier architecture is left to the synthesis tool. Modify this
   to instantiate specific multipliers.
 
 */

module aeMB2_mult (/*AUTOARG*/
   // Outputs
   mul_mx,
   // Inputs
   opa_of, opb_of, opc_of, gclk, grst, dena, gpha
   );      
   parameter AEMB_MUL = 1; ///< implement multiplier  
   
   output [31:0] mul_mx;   
   
   input [31:0]  opa_of;
   input [31:0]  opb_of;
   input [5:0] 	 opc_of;   

   // SYS signals
   input 	 gclk,
		 grst,
		 dena,
		 gpha;      

   /*AUTOREG*/
   
   reg [31:0] 	 rMULA, 
		 rMULB;

   assign 	 mul_mx = (AEMB_MUL[0]) ? rMULB : 32'hX;   
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMULA <= 32'h0;
	rMULB <= 32'h0;
	// End of automatics
     end else if (dena) begin
	rMULB <= #1 rMULA;
	rMULA <= #1 (opa_of * opb_of);
     end
   
endmodule // aeMB2_mult

// $Log: not supported by cvs2svn $