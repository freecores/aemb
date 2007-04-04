//                              -*- Mode: Verilog -*-
// Filename        : aeMB_fetch.v
// Description     : AEMB Programme Counter
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Sat Dec 30 04:34:44 2006
// Last Modified By: $Author: sybreon $
// Last Modified On: $Date: 2007-04-04 14:08:34 $
// Update Count    : $Revision: 1.2 $
// Status          : $State: Exp $

/*
 * $Id: aeMB_fetch.v,v 1.2 2007-04-04 14:08:34 sybreon Exp $
 * 
 * AEMB Instruction Fetch
 * Copyright (C) 2006 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
 *  
 * This library is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation; either version 2.1 of the License, 
 * or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public 
 * License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
 *
 * DESCRIPTION
 * Controls the instruction side of AEMB.
 *
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

module aeMB_fetch (/*AUTOARG*/
   // Outputs
   iwb_adr_o, rPC, rPCNXT,
   // Inputs
   iwb_dat_i, nclk, nrst, frun, rFSM, rBRA, rRESULT
   );
   parameter ISIZ = 32;

   // Instruction WB I/F
   output [ISIZ-1:0] iwb_adr_o;
   input [31:0]      iwb_dat_i;

   // System
   input 	     nclk, nrst, frun;   
   
   // Internal
   output [31:0]     rPC;
   output [31:0]     rPCNXT;   
   input [1:0] 	     rFSM;   
   input 	     rBRA;
   input [31:0]      rRESULT;
      
   // WB ADR signal
   reg [31:0] 	     rIWBADR, rPC;
   assign 	     rPCNXT = rIWBADR + 4;   
   assign 	     iwb_adr_o = {rIWBADR[ISIZ-1:2],2'b00}; // Word Aligned

   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIWBADR <= 32'h0;
	rPC <= 32'h0;
	// End of automatics
     end else begin	
	// PC Sources - ALU, Direct, Next
	case (rFSM)
	  2'b01: rIWBADR <= #1 32'h00000010; // HWINT
	  2'b10: rIWBADR <= #1 32'h00000020; // HWEXC
	  //2'b11: rIWBADR <= #1 32'h00000008; // SWEXC
	  default: rIWBADR <= #1 (rBRA) ? rRESULT : rPCNXT;
	endcase // case(rFSM)
	
	rPC <= #1 {rIWBADR[31:2],2'd0};	
     end // if (frun)

   
endmodule // aeMB_fetch
		 