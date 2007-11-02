// $Id: aeMB_bpcu.v,v 1.1 2007-11-02 03:25:39 sybreon Exp $
//
// AEMB BRANCH PROGRAMME COUNTER UNIT
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

module aeMB_bpcu (/*AUTOARG*/
   // Outputs
   iwb_adr_o, rPC, rPCLNK, rBRA, rDLY,
   // Inputs
   rMXALT, rOPC, rRD, rRA, rRESULT, rDWBDI, rREGA, rXCE, gclk, grst,
   gena
   );
   parameter IW = 24;

   // INST WISHBONE
   output [IW-1:2] iwb_adr_o;

   // INTERNAL
   output [31:2]   rPC, rPCLNK;
   output 	   rBRA;
   output 	   rDLY;
   input [1:0] 	   rMXALT;   
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD, rRA;  
   input [31:0]    rRESULT; // ALU
   input [31:0]    rDWBDI; // RAM
   input [31:0]    rREGA;    
   input [1:0] 	   rXCE;   
   
   // SYSTEM
   input 	   gclk, grst, gena;

   // BRANCH
   wire 	   fRTD = (rOPC == 6'o55);
   wire 	   fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 	   fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);

   wire [31:0] 	   wREGA;
   assign 	   wREGA = (rMXALT == 2'o2) ? rDWBDI :
			   (rMXALT == 2'o1) ? rRESULT :
			   rREGA;   
   
   wire 	   wBEQ = (wREGA == 32'd0);
   wire 	   wBNE = ~wBEQ;
   wire 	   wBLT = wREGA[31];
   wire 	   wBLE = wBLT | wBEQ;   
   wire 	   wBGE = ~wBLT;
   wire 	   wBGT = ~wBLE;   

   reg 		   xXCC;
   always @(/*AUTOSENSE*/rRD or wBEQ or wBGE or wBGT or wBLE or wBLT
	    or wBNE)
     case (rRD[2:0])
       3'o0: xXCC <= wBEQ;
       3'o1: xXCC <= wBNE;
       3'o2: xXCC <= wBLT;
       3'o3: xXCC <= wBLE;
       3'o4: xXCC <= wBGT;
       3'o5: xXCC <= wBGE;
       default: xXCC <= 1'bX;
     endcase // case (rRD[2:0])

   // DELAY SLOT
   reg 		   rBRA, xBRA;
   reg 		   rDLY, xDLY;
   wire 	   fSKIP = rBRA & !rDLY;   
   
   always @(/*AUTOSENSE*/fBCC or fBRU or fRTD or rBRA or rRA or rRD
	    or xXCC)
     if (rBRA) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xBRA <= 1'h0;
	xDLY <= 1'h0;
	// End of automatics
     end else begin
	xDLY <= (fBRU & rRA[4]) | (fBCC & rRD[4]) | fRTD;      
	xBRA <= (fRTD | fBRU) ? 1'b1 :
		(fBCC) ? xXCC :
		1'b0;
	/*
	case (rXCE)
	  2'o1: xBRA <= 1'b0;
	  default: xBRA <= (fRTD | fBRU) ? 1'b1 :
			   (fBCC) ? xXCC :
			   1'b0;
	endcase // case (rXCE)	
	 */
     end

   reg [31:2] rPCLNK, xPCLNK;
   always @(/*AUTOSENSE*/fSKIP or rBRA or rPC or rRESULT)
     if (fSKIP) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xPCLNK <= 30'h0;
	// End of automatics
     end else begin
	xPCLNK <= (rBRA) ? rRESULT[31:2] : rPC;	
     end
   
   // PC Changes - (NXT, BRA, INT)
   reg [31:2] 	   rIPC, xIPC;
   reg [31:2] 	   rPC, xPC;
   
   assign 	   iwb_adr_o = rIPC[IW-1:2];
   always @(/*AUTOSENSE*/rBRA or rIPC or rRESULT) begin
      xIPC <= (rBRA) ? rRESULT[31:2] : (rIPC + 1);
      /*
      case (rXCE)
	2'o1: xIPC <= 32'h04;	
	default: xIPC <= (rBRA) ? rRESULT[31:2] : (rIPC + 1);
      endcase // case (rXCE)
       */
      xPC <= rIPC;	
   end
   

   // SYNC
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBRA <= 1'h0;
	rDLY <= 1'h0;
	rIPC <= 30'h0;
	rPC <= 30'h0;
	rPCLNK <= 30'h0;
	// End of automatics
     end else if (gena) begin
	rIPC <= #1 xIPC;
	rBRA <= #1 xBRA;
	rPC <= #1 xPC;
	rPCLNK <= #1 xPCLNK;
	rDLY <= #1 xDLY;	
     end
   
   // synopsys translate_off

   
   // synopsys translate_on
   
endmodule // aeMB_bpcu
