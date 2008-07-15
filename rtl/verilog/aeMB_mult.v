/* $Id: aeMB_mult.v,v 1.5 2008-07-15 21:15:04 sybreon Exp $
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
 * The implementation is tool dependent. The code used is based on
 * examples from the tool vendors.   
 */

module aeMB_mult (/*AUTOARG*/
   // Outputs
   dat_mul,
   // Inputs
   reg_opa, reg_opb, sys_clk, sys_rst, sys_ena
   );      
   parameter MUL = 1; ///< implement multiplier  
    
   output [31:0] dat_mul;      
   input [31:0]  reg_opa;
   input [31:0]  reg_opb;

   // SYS signals
   input 	 sys_clk,
		 sys_rst,
		 sys_ena;      

   /*AUTOREG*/
   reg [31:0] 	 rALT0, rALT1, rALT2;   
   reg [31:0] 	 rXIL0, rXIL1;

`ifdef QUARTUS
   assign 	 dat_mul = (MUL[0]) ? wALT2 : 32'hX;
`else
   assign 	 dat_mul = (MUL[0]) ? rXIL1 : 32'hX;
`endif   
      
   always @(posedge sys_clk)
     if (sys_rst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rALT0 <= 32'h0;
	rALT1 <= 32'h0;
	rALT2 <= 32'h0;
	rXIL0 <= 32'h0;
	rXIL1 <= 32'h0;
	// End of automatics
     end else if (sys_ena) begin	       
	rXIL1 <= #1 rXIL0;
	rXIL0 <= #1 (reg_opa * reg_opb);
	
	rALT2 <= #1 (rALT0 * rALT1);	
	rALT0 <= #1 reg_opa;
	rALT1 <= #1 reg_opb;	
     end

endmodule // aeMB2_mult

/*
 $Log: not supported by cvs2svn $
 */