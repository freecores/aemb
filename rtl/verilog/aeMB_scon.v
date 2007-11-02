// $Id: aeMB_scon.v,v 1.1 2007-11-02 03:25:41 sybreon Exp $
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

module aeMB_scon (/*AUTOARG*/
   // Outputs
   grst, gclk, gena,
   // Inputs
   rOPC, rDWBSTB, dwb_ack_i, iwb_ack_i, rMSR_IE, rBRA, rDLY,
   sys_clk_i, sys_rst_i, sys_int_i
   );

   // INTERNAL
   //output [1:0] rXCE;
   input [5:0] 	rOPC;
   
   input 	rDWBSTB;
   input 	dwb_ack_i;
   input 	iwb_ack_i; 
   input 	rMSR_IE;
   input 	rBRA, rDLY;   
   
   // SYSTEM
   output 	grst, gclk, gena;
   input 	sys_clk_i, sys_rst_i;
   input 	sys_int_i;   
   
   assign 	grst = sys_rst_i;
   assign 	gclk = sys_clk_i;
   
   assign 	gena = !((rDWBSTB ^ dwb_ack_i) | !iwb_ack_i);
   
   // --- EXCEPTION CONTROL

   reg [1:0] 	rXCE, xXCE;
   
   reg [2:0] 	rINT;
   reg 		rNCLR;   
   wire 	fINT = sys_int_i & rMSR_IE;
   
   wire 	fNCLR;
   assign 	fNCLR = (rOPC == 6'o46) | (rOPC == 6'o56) | // BRU
			(rOPC == 6'o47) | (rOPC == 6'o57) | // BCC
			(rOPC == 6'o55) | // RTD
			(rOPC == 6'o54); // IMM

   wire [1:0] 	wATOM = {rNCLR, fNCLR};
   wire 	fATOM = (wATOM == 2'o0) | (wATOM == 2'o2);


   always @(/*AUTOSENSE*/fATOM or fINT or rXCE) begin
      case (rXCE)
	2'o0: xXCE <= (fATOM & fINT) ? 2'o1 : 2'o0;
	2'o1: xXCE <= 2'o0;
	default xXCE <= 2'oX;	
      endcase // case (rXCE)      
   end
   

   // --- SYNCHRONOUS ----------------------------------
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rINT <= 3'h0;
	rNCLR <= 1'h0;
	rXCE <= 2'h0;
	// End of automatics
     end else if (gena) begin
	rINT <= #1 {rINT[1:0], fINT};
	rNCLR <= #1 fNCLR;
	rXCE <= #1 xXCE;	
     end
   
   
endmodule // aeMB_scon
