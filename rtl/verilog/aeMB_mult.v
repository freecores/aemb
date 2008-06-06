/* $Id: aeMB_mult.v,v 1.4 2008-06-06 09:36:02 sybreon Exp $
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
/*
 * 2-STAGE MULTIPLIER
 */

module aeMB_mult (/*AUTOARG*/
   // Outputs
   m_mul,
   // Inputs
   x_opa, x_opb, x_opc, gclk, grst, gena
   );      
   parameter MUL = 1; ///< implement multiplier  
   
   output [31:0] m_mul;   
   
   input [31:0]  x_opa;
   input [31:0]  x_opb;
   input [5:0] 	 x_opc;   

   // SYS signals
   input 	 gclk,
		 grst,
		 gena;      

   /*AUTOREG*/

   reg [31:0] 	 rOPA, rOPB;   
   reg [31:0] 	 rMUL0, 
		 rMUL1;

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMUL0 <= 32'h0;
	rMUL1 <= 32'h0;
	rOPA <= 32'h0;
	rOPB <= 32'h0;
	// End of automatics
     end else if (gena) begin
	//rMUL1 <= #1 rMUL0;
	rMUL1 <= #1 rMUL0; //rOPA * rOPB;	
	rMUL0 <= #1 (x_opa * x_opb);
	rOPA <= #1 x_opa;
	rOPB <= #1 x_opb;	
     end

   assign 	 m_mul = (MUL[0]) ? rMUL1 : 32'hX;
      
endmodule // aeMB2_mult

