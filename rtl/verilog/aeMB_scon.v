// $Id: aeMB_scon.v,v 1.3 2007-11-04 05:24:59 sybreon Exp $
//
// AEMB SYSTEM CONTROL UNIT
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
// Revision 1.2  2007/11/02 19:20:58  sybreon
// Added better (beta) interrupt support.
// Changed MSR_IE to disabled at reset as per MB docs.
//
// Revision 1.1  2007/11/02 03:25:41  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aeMB_scon (/*AUTOARG*/
   // Outputs
   rXCE, grst, gclk, gena,
   // Inputs
   rOPC, rATOM, rDWBSTB, dwb_ack_i, iwb_ack_i, rMSR_IE, rMSR_BIP,
   rBRA, rDLY, sys_clk_i, sys_rst_i, sys_int_i
   );

   // INTERNAL
   output [1:0] rXCE;
   input [5:0] 	rOPC;
   input [1:0] 	rATOM;   
   
   input 	rDWBSTB;
   input 	dwb_ack_i;
   input 	iwb_ack_i; 
   input 	rMSR_IE;
   input 	rMSR_BIP;
   
   input 	rBRA, rDLY;   
   
   // SYSTEM
   output 	grst, gclk, gena;
   input 	sys_clk_i, sys_rst_i;
   input 	sys_int_i;   

      
   assign 	gclk = sys_clk_i;
   
   assign 	gena = !((rDWBSTB ^ dwb_ack_i) | !iwb_ack_i);

   // --- INTERRUPT LATCH --------------------------------------
   // Debounce and latch onto the positive edge. This is independent
   // of the pipeline so that stalls do not affect it.
   
   reg 		rFINT;
   reg [1:0] 	rDINT;
   wire 	wSHOT = rDINT[0] & !rDINT[1] & sys_int_i;

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDINT <= 2'h0;
	rFINT <= 1'h0;
	// End of automatics
     end else if (rMSR_IE) begin
	rDINT <= #1 {rDINT[0], sys_int_i};	
	rFINT <= (rXCE == 2'o2) ? 1'b0 : (rFINT | wSHOT);
     end
   

   // --- EXCEPTION PROCESSING ---------------------------------
   // Process the independent priority flags to determine which
   // interrupt/exception/break to handle.

   reg [1:0] rXCE;
   reg 	     rENA;   
   wire      fINT = rENA & ^rATOM & !rMSR_BIP & rMSR_IE & rFINT;   

   always @(/*AUTOSENSE*/fINT)
     rXCE <= (fINT) ? 2'o2 : 2'o0;

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rENA <= 1'h0;
	// End of automatics
     end else begin
	rENA <= #1 gena;	
     end
   
   // --- RESET SYNCHRONISER -----------------------------------
   // Synchronise the reset signal to a clock edge.
   
   reg [1:0] 	rRST;   
   assign 	grst = sys_rst_i;

   always @(posedge sys_clk_i)
     if (!sys_rst_i) begin
	rRST <= 2'o3;	
	/*AUTORESET*/
     end else begin
	rRST <= #1 {rRST[0], !sys_rst_i};	
     end

   
endmodule // aeMB_scon
