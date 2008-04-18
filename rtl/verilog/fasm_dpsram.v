/* $Id: fasm_dpsram.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
** 
** Dual-Port Synchronous RAM
** Copyright (C) 2007 Shawn Tan <shawn.tan@cantab.net>
** 
** This program is free software: you can redistribute it and/or
** modify it under the terms of the GNU General Public License as
** published by the Free Software Foundation, either version 3 of the
** license, or (at your option) any later version.
**
** This program is distributed in the hope that it will be useful, but
** WITHOUT ANY WARRANTY; without even the implied warranty of
** MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
** General Public License for more details.
**
** You should have received a copy of the GNU General Public License
** along with this program.  If not, see http://www.gnu.org/licenses
*/

/** 
 * @file fasm_dpsram.v
 * @brief On-chip dual-port synchronous SRAM. 

 */

module fasm_dpsram (/*AUTOARG*/
   // Outputs
   dat_o, xdat_o,
   // Inputs
   adr_i, dat_i, wre_i, xadr_i, xdat_i, xwre_i, clk_i, ena_i, xclk_i,
   xena_i
   ) ;
   parameter AW = 8;
   parameter DW = 32;

   // PORT A
   output [DW-1:0] dat_o;  
   input [AW-1:0]  adr_i;
   input [DW-1:0]  dat_i;
   input 	   wre_i;

   // PORT B
   output [DW-1:0] xdat_o;  
   input [AW-1:0]  xadr_i;
   input [DW-1:0]  xdat_i;
   input 	   xwre_i;
   
   // SYSTEM
   input 	   clk_i, ena_i;
   input 	   xclk_i, xena_i;   

   reg [DW-1:0]    rBRAM [(1<<AW)-1:0];
   reg [AW-1:0]    rADDR, rXADR;
   
   assign 	   dat_o = rBRAM[rADDR];
   assign 	   xdat_o = rBRAM[rXADR];   
   
   always @(posedge clk_i)
     if (ena_i) begin
	rADDR <= #1 adr_i;	
	if (wre_i) 
	  rBRAM[adr_i] <= #1 dat_i;
     end

   always @(posedge xclk_i)
     if (xena_i) begin
	rXADR <= #1 xadr_i;	
	if (xwre_i) 
	  rBRAM[xadr_i] <= #1 xdat_i;	
     end
   
   // --- SIMULATION ONLY ------------------------------------
   // synopsys translate_off
   integer i;
   initial begin
      for (i=0; i<(1<<AW); i=i+1) begin
	 rBRAM[i] <= $random;	 
      end
   end
   // synopsys translate_on
   
endmodule // fasm_dpsram
