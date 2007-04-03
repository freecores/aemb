//                              -*- Mode: Verilog -*-
// Filename        : aeMB_decode.v
// Description     : AEMB Instruction Decoder
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Sat Dec 30 06:19:55 2006
// Last Modified By: Shawn Tan
// Last Modified On: 2006-12-31
// Update Count    : 0
// Status          : Unknown, Use with caution!

/*
 * $Id: aeMB_decode.v,v 1.2 2007-04-03 14:46:26 sybreon Exp $
 * 
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
 * Instruction decoder
 *
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 * 
 */

module aeMB_decode (/*AUTOARG*/
   // Outputs
   rSIMM, rMXALU, rMXSRC, rMXTGT, rRA, rRB, rRD, rRD_, rOPC, rIMM,
   rDWBSTB, rDWBWE, rIWBSTB, rDLY, rLNK, rBRA, rRWE, iwb_sel_o,
   iwb_stb_o, iwb_we_o, dwb_stb_o, dwb_we_o,
   // Inputs
   rREGA, rRESULT, iwb_dat_i, dwb_dat_i, nclk, nrst, drun, frun, frst,
   drst
   );
   // Internal I/F
   output [31:0] rSIMM;
   output [1:0]  rMXALU;
   output [1:0]  rMXSRC, rMXTGT;
   output [4:0]  rRA, rRB, rRD, rRD_;
   output [5:0]  rOPC;   
   output [15:0] rIMM;
   output 	 rDWBSTB, rDWBWE, rIWBSTB;
   output 	 rDLY, rLNK, rBRA, rRWE;   
   input [31:0]  rREGA, rRESULT;
   
   // External I/F
   input [31:0]  iwb_dat_i, dwb_dat_i;
   output [3:0]  iwb_sel_o;
   output 	 iwb_stb_o, iwb_we_o;
   output 	 dwb_stb_o, dwb_we_o;
   
   // System I/F
   input 	 nclk, nrst, drun, frun, frst, drst;

   // Endian Correction
   //wire [31:0] 	 wWBDAT = dwb_dat_i; 	 
   wire [31:0] 	 wWBDAT = {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]}; 	 
   wire [31:0] 	 wIREG = {iwb_dat_i[7:0],iwb_dat_i[15:8],iwb_dat_i[23:16],iwb_dat_i[31:24]};

   // Decode
   wire [5:0] 	 wOPC = wIREG[31:26];
   wire [4:0] 	 wRD = wIREG[25:21];
   wire [4:0] 	 wRA = wIREG[20:16];
   wire [4:0] 	 wRB = wIREG[15:11];   
   wire [15:0] 	 wIMM = wIREG[15:0];
      
   // rOPC, rRD, rRA, rRB, rIMM;
   reg [5:0] 	 rOPC;
   reg [4:0] 	 rRD, rRA, rRB, rRD_;
   reg [15:0] 	 rIMM;
   
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	//rOPC <= 6'o40;
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMM <= 16'h0;
	rOPC <= 6'h0;
	rRA <= 5'h0;
	rRB <= 5'h0;
	rRD <= 5'h0;
	// End of automatics
     end else if (frun) begin
	rOPC <= #1 wOPC;
	rRD <= #1 wRD;
	rRA <= #1 wRA;
	rRB <= #1 wRB;
	rIMM <= #1 wIMM;	
     end else begin
	rOPC <= 6'o40;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMM <= 16'h0;
	rRA <= 5'h0;
	rRB <= 5'h0;
	rRD <= 5'h0;
	// End of automatics
     end
   
   always @(negedge nclk or negedge drst)
     if (!drst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRD_ <= 5'h0;
	// End of automatics
     end else if (drun) begin
	rRD_ <= #1 rRD;
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRD_ <= 5'h0;
	// End of automatics
     end
   
   // Groups
   wire 	 fGH0 = (wOPC[5:3] == 3'o0);
   wire 	 fGH1 = (wOPC[5:3] == 3'o1);
   wire 	 fGH2 = (wOPC[5:3] == 3'o2);
   wire 	 fGH3 = (wOPC[5:3] == 3'o3);
   wire 	 fGH4 = (wOPC[5:3] == 3'o4);
   wire 	 fGH5 = (wOPC[5:3] == 3'o5);
   wire 	 fGH6 = (wOPC[5:3] == 3'o6);
   wire 	 fGH7 = (wOPC[5:3] == 3'o7);
   wire 	 fGL0 = (wOPC[2:0] == 3'o0);
   wire 	 fGL1 = (wOPC[2:0] == 3'o1);
   wire 	 fGL2 = (wOPC[2:0] == 3'o2);
   wire 	 fGL3 = (wOPC[2:0] == 3'o3);
   wire 	 fGL4 = (wOPC[2:0] == 3'o4);
   wire 	 fGL5 = (wOPC[2:0] == 3'o5);
   wire 	 fGL6 = (wOPC[2:0] == 3'o6);
   wire 	 fGL7 = (wOPC[2:0] == 3'o7);
   
   // Decode Logic
   wire 	 fADD = ({wOPC[5:4],wOPC[0]} == 3'o0);
   wire 	 fSUB = ({wOPC[5:4],wOPC[0]} == 3'o1);   
   wire 	 fLOGIC = ({wOPC[5:4],wOPC[2]} == 3'o4);
   wire 	 fMUL = ({wOPC[5:4]} == 3'o1);
   
   wire 	 fLD = ({wOPC[5:4],wOPC[2]} == 3'o6);
   wire 	 fST = ({wOPC[5:4],wOPC[2]} == 3'o7);
   
   wire 	 fBCC = (wOPC[5:4] == 2'b10) & fGL7;
   wire 	 fBRU = (wOPC[5:4] == 2'b10) & fGL6;
   wire 	 fBRA = fBRU & wRA[3];   
   
   wire 	 fSHIFT = fGH4 & fGL4;
   wire 	 fIMM = fGH5 & fGL4;
   wire 	 fRET = fGH5 & fGL5;
   wire 	 fMISC = fGH4 & fGL5;

   // MXALU
   reg [1:0] 	 rMXALU;
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXALU <= 2'h0;
	// End of automatics
     end else if (frun) begin
	rMXALU <= #1
		  //(!fNBR) ? 2'o0 :
		  (fSHIFT) ? 2'o2 :
		  (fLOGIC) ? 2'o1 :
		  (fBRA) ? 2'o3 :
		  2'o0;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXALU <= 2'h0;
	// End of automatics
     end
   
   // BCC/BRA/RET
   reg 		 rMXDLY,rMXLNK;
   reg [1:0] 	 rMXBRA;
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXBRA <= 2'h0;
	rMXDLY <= 1'h0;
	rMXLNK <= 1'h0;
	// End of automatics
     end else if (frun) begin
	rMXBRA <= #1
		  //(!fNBR) ? 2'o0 :
		  (fBCC) ? 2'o3 :
		  (fRET) ? 2'o1 :
		  (fBRU) ? 2'o2 :
		  2'o0;	
	rMXDLY <= #1
		  //(!fNBR) ? 1'b0 :
		  (fBCC) ? wRD[4] :
		  (fRET) ? 1'b1 :
		  (fBRU) ? wRA[4] :
		  1'b0;
	rMXLNK <= #1
		  //(!fNBR) ? 1'b0 :
		  (fBRU) ? wRA[2] : 1'b0;	
     end else begin // if (frun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXBRA <= 2'h0;
	rMXDLY <= 1'h0;
	rMXLNK <= 1'h0;
	// End of automatics
     end
   
   // LD ST
   reg [1:0] 	  rMXLDST;
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXLDST <= 2'h0;
	// End of automatics
     end else if (frun) begin
	rMXLDST <= #1
		   //(!fNBR) ? 2'o0 :
		   (fLD) ? 2'o2 :
		   (fST) ? 2'o3 :
		   2'o0;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXLDST <= 2'h0;
	// End of automatics
     end
   
   // SRC/TGT - incorporates forwarding   
   reg [1:0] 	  rMXSRC, rMXTGT, rMXALT;
   wire 	  fRWE = (rRD != 5'd0) & (rMXBRA != 2'o3);
   //wire 	  fFWDBCC = (rMXBRA != 2'o3);
   
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXALT <= 2'h0;
	rMXSRC <= 2'h0;
	rMXTGT <= 2'h0;
	// End of automatics
     end else if (frun) begin
	rMXSRC <= #1
		  //(!fNBR) ? 2'o0 :
		  (fBRU|fBCC) ? 2'o1 : // PC
		  ((rRD == wRA) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRA) & fRWE) ? 2'o2 : // FWD
		  2'o0; // RA
	rMXTGT <= #1
		  //(!fNBR) ? 2'o0 :
		  (wOPC[3]) ? 2'o1 : // IMM
		  ((rRD == wRB) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRB) & fRWE) ? 2'o2 : // FWD
		  2'o0;	// RB
	rMXALT <= #1
		  //(!fNBR) ? 2'o0 :
		  //(fBRU|fBCC) ? 2'o1 : // PC
		  ((rRD == wRA) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRA) & fRWE) ? 2'o2 : // FWD
		  2'o0; // RA
     end else begin // if (frun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXALT <= 2'h0;
	rMXSRC <= 2'h0;
	rMXTGT <= 2'h0;
	// End of automatics
     end
       
   // IMM processing
   reg [31:0] 	 rSIMM;
   reg [15:0] 	 rIMMHI;   
   reg 		 rFIMM;
   
   always @(negedge nclk or negedge frst)
     if (!frst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFIMM <= 1'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end else if (frun) begin
	rSIMM <= #1 (rFIMM) ? {rIMMHI,wIMM} : {{(16){wIMM[15]}},wIMM};
	rFIMM <= #1 fIMM;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFIMM <= 1'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end

   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMMHI <= 16'h0;
	// End of automatics
     end else if (frun) begin
	rIMMHI <= #1 (fIMM) ? wIMM : rIMMHI;	
     end

   // CC
   // COMPARATOR
   //wire [31:0] wREGA = rREGA;
   wire [31:0] wREGA =
	       (rMXALT == 2'o3) ? wWBDAT :
	       (rMXALT == 2'o2) ? rRESULT :
	       rREGA;   
   
   wire        wBEQ = (wREGA == 32'd0);
   wire        wBNE = ~wBEQ;
   wire        wBLT = wREGA[31];
   wire        wBLE = wBLT | wBEQ;   
   wire        wBGE = ~wBLT;
   wire        wBGT = ~wBLE;   
   
   reg 	       rBCC;   
   always @(/*AUTOSENSE*/rRD or wBEQ or wBGE or wBGT or wBLE or wBLT
	    or wBNE)
     case (rRD[2:0])
       3'o0: rBCC <= #1 wBEQ;
       3'o1: rBCC <= #1 wBNE;
       3'o2: rBCC <= #1 wBLT;
       3'o3: rBCC <= #1 wBLE;
       3'o4: rBCC <= #1 wBGT;
       3'o5: rBCC <= #1 wBGE;
       default: rBCC <= 1'b0;
     endcase // case(rRD[2:0])

   // Branch Signal
   reg 	       rBRA, rDLY, rLNK;
   always @(negedge nclk or negedge drst)
     if (!drst) begin
	//rBRA <= 1'h1;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBRA <= 1'h0;
	rDLY <= 1'h0;
	rLNK <= 1'h0;
	// End of automatics
     end else if (drun) begin
	case (rMXBRA)
	  2'o0: rBRA <= #1 1'b0;
	  2'o3: rBRA <= #1 rBCC;
	  default: rBRA <= #1 1'b1;	  
	endcase // case(rMXBRA)
	
	case (rMXBRA)
	  2'o0: rDLY <= #1 1'b0;	  
	  2'o3: rDLY <= #1 rBCC & rMXDLY;
	  default: rDLY <= #1 rMXDLY;
	endcase // case(rMXBRA)

	case (rMXBRA)
	  2'o2: rLNK <= #1 rMXLNK;	  
	  default: rLNK <= #1 1'b0;
	endcase // case(rMXBRA)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBRA <= 1'h0;
	rDLY <= 1'h0;
	rLNK <= 1'h0;
	// End of automatics
     end
   
   // MXRWE
   reg 		 rRWE;
   wire 	 wRWE = (rRD != 5'd0);   
   always @(negedge nclk or negedge drst)
     if (!drst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRWE <= 1'h0;
	// End of automatics
     end else if (drun) begin
	case (rMXBRA)
	  default: rRWE <= #1 1'b0;	 
	  2'o2: rRWE <= #1 wRWE ^ rMXLDST[0];
	  2'o0: rRWE <= #1 wRWE;	  
	endcase // case(rMXBRA)
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRWE <= 1'h0;
	// End of automatics
     end

   // DWB logic
   reg rDWBSTB, rDWBWE;
   assign dwb_stb_o = rDWBSTB;
   assign dwb_we_o = rDWBWE;

   always @(negedge nclk or negedge drst)
     if (!drst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSTB <= 1'h0;
	rDWBWE <= 1'h0;
	// End of automatics
     end else if (drun) begin
	rDWBSTB <= #1 rMXLDST[1];
	rDWBWE <= #1 rMXLDST[0];
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSTB <= 1'h0;
	rDWBWE <= 1'h0;
	// End of automatics
     end
   
   // WB STB signal
   reg               rIWBSTB;   
   assign 	     iwb_stb_o = rIWBSTB;
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIWBSTB <= 1'h0;
	// End of automatics
     end else begin
	rIWBSTB <= #1 1'b1;
     end
   
   // WB other signals
   assign 	     iwb_sel_o = 4'hF;
   assign 	     iwb_we_o = 1'b0;
   
   
endmodule // aeMB_decode

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// End: