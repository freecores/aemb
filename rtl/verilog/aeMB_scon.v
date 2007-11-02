// $Id: aeMB_scon.v,v 1.2 2007-11-02 19:20:58 sybreon Exp $
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

   // --- INTERRUPT LATCH ---------------------------------

   reg 		rFINT;
   reg [1:0] 	rDINT;
   wire 	wSHOT = rDINT[0] & !rDINT[1] & sys_int_i; // +Edge   

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDINT <= 2'h0;
	// End of automatics
     end else if (rMSR_IE) begin
	rDINT <= #1 {rDINT[0], sys_int_i};	
     end
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFINT <= 1'h0;
	// End of automatics
     end else if (gena) begin
	rFINT <= (rXCE == 2'o2) ? 1'b0 : (rFINT | wSHOT);
     end

   // --- EXCEPTION PROCESSING ----------------------------

   reg [1:0] rXCE;

   always @(/*AUTOSENSE*/rATOM or rFINT or rMSR_BIP or rMSR_IE)
     case (rATOM)
       default: rXCE <= (!rMSR_BIP & rMSR_IE & rFINT) ? 2'o2 :
			2'o0;      
       2'o0, 2'o3: rXCE <= 0;       
     endcase // case (rATOM)
   
   
   // --- RESET SYNCHRONISER ------------------------------
   
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
