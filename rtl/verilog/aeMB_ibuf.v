// $Id: aeMB_ibuf.v,v 1.2 2007-11-02 19:20:58 sybreon Exp $
//
// AEMB INSTRUCTION BUFFER
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
// Revision 1.1  2007/11/02 03:25:40  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aeMB_ibuf (/*AUTOARG*/
   // Outputs
   rIMM, rRA, rRD, rRB, rALT, rOPC, rSIMM, iwb_stb_o,
   // Inputs
   rBRA, rXCE, iwb_dat_i, iwb_ack_i, gclk, grst, gena
   );
   // INTERNAL
   output [15:0] rIMM;
   output [4:0]  rRA, rRD, rRB;
   output [10:0] rALT;
   output [5:0]  rOPC;
   output [31:0] rSIMM;
   input 	 rBRA;
   input [1:0] 	 rXCE;   
   
   // INST WISHBONE
   output 	 iwb_stb_o;
   input [31:0]  iwb_dat_i;
   input 	 iwb_ack_i;

   // SYSTEM
   input 	 gclk, grst, gena;

   reg [15:0] 	 rIMM;
   reg [4:0] 	 rRA, rRD;
   reg [5:0] 	 rOPC;

   // FIXME: Endian
   wire [31:0] 	 wIDAT = iwb_dat_i;
   assign 	 {rRB, rALT} = rIMM;   
   
   // TODO: Assign to FIFO not full.
   assign 	iwb_stb_o = 1'b1;

   reg [31:0] 	rSIMM, xSIMM;
   wire 	fIMM = (rOPC == 6'o54);
   
   reg [31:0] 	xIREG;

   // DELAY SLOT
   always @(/*AUTOSENSE*/fIMM or rBRA or rIMM or rXCE or wIDAT) begin
      xIREG <= (rBRA | |rXCE) ? 32'h88000000 : wIDAT;
      xSIMM <= (fIMM) ? {rIMM, wIDAT[15:0]} : { {(16){wIDAT[15]}}, wIDAT[15:0]};
   end

   // Synchronous
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMM <= 16'h0;
	rOPC <= 6'h0;
	rRA <= 5'h0;
	rRD <= 5'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end else if (gena) begin
	{rOPC, rRD, rRA, rIMM} <= #1 xIREG;
	rSIMM <= #1 xSIMM;	
     end
   
   
endmodule // aeMB_ibuf
