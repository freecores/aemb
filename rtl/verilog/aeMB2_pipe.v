/* $Id: aeMB2_pipe.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * System signal controller
 * @file aeMB2_pipe.v

 * Generates clock, reset, and enable signals. Hardware clock/reset
   managers can be instantiated here.
 
 */

module aeMB2_pipe (/*AUTOARG*/
   // Outputs
   gpha, gclk, grst, dena, iena,
   // Inputs
   bra_ex, dwb_fb, xwb_fb, ich_fb, fet_fb, sys_clk_i, sys_rst_i,
   sys_ena_i
   );
   parameter AEMB_HTX = 1;   

   input [1:0] bra_ex;
   input       dwb_fb;
   input       xwb_fb;   
   input       ich_fb;
   input       fet_fb;   
   output      gpha,
	       gclk,
	       grst,
	       dena,
	       iena;   
     
   input       sys_clk_i,
	       sys_rst_i,
	       sys_ena_i;
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			gpha;
   // End of automatics
   reg [1:0] 		rst;   

   // Instantiate clock/reset managers
   assign 		gclk = sys_clk_i;
   assign 		grst = !rst[1];

   // run instruction side pipeline
   assign 		iena = fet_fb & xwb_fb & dwb_fb & sys_ena_i;
   // run data side pipeline
   //assign 		dena = ((dwb_fb & xwb_fb & ich_fb) | bra_ex[1]) & sys_ena_i; 
   assign 		dena = dwb_fb & xwb_fb & ich_fb & sys_ena_i; 
   
   // RESET DELAY
   always @(posedge sys_clk_i)
     if (sys_rst_i) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rst <= 2'h0;
	// End of automatics
     end else begin
	rst <= #1 {rst[0], !sys_rst_i};
     end

   // PHASE TOGGLE
   always @(posedge sys_clk_i)
     if (sys_rst_i) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	gpha <= 1'h0;
	// End of automatics
     end else if (dena | grst) begin
	gpha <= #1 !gpha;	
     end
   
endmodule // aeMB2_pipe

// $Log: not supported by cvs2svn $