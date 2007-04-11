/*
 * $Id: aeMB_decode.v,v 1.4 2007-04-11 04:30:43 sybreon Exp $
 * 
 * AEMB Instruction Decoder
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
 * Revision 1.3  2007/04/04 06:12:27  sybreon
 * Fixed minor bugs
 *
 * Revision 1.2  2007/04/03 14:46:26  sybreon
 * Fixed endian correction issues on data bus.
 *
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

// 88@143
module aeMB_decode (/*AUTOARG*/
   // Outputs
   rSIMM, rMXALU, rMXSRC, rMXTGT, rRA, rRB, rRD, rRD_, rOPC, rIMM,
   rDWBSTB, rDWBWE, rIWBSTB, rDLY, rLNK, rBRA, rRWE, rMXLDST,
   iwb_stb_o, dwb_stb_o, dwb_we_o,
   // Inputs
   rREGA, rRESULT, iwb_dat_i, dwb_dat_i, nclk, nrst, drun, frun, nrun
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
   output [1:0]  rMXLDST;   
   input [31:0]  rREGA, rRESULT;
   
   // External I/F
   input [31:0]  iwb_dat_i, dwb_dat_i;
   output 	 iwb_stb_o;   
   output 	 dwb_stb_o, dwb_we_o;
   
   // System I/F
   input 	 nclk, nrst, drun, frun, nrun;

   // Endian Correction
   //wire [31:0] 	 wWBDAT = dwb_dat_i; 	 
   //wire [31:0] 	 wIREG = iwb_dat_i;	 
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
   reg [5:0] 	 xOPC;
   reg [4:0] 	 xRD, xRA, xRB, xRD_;
   reg [15:0] 	 xIMM;
   
   always @(/*AUTOSENSE*/frun or wIMM or wOPC or wRA or wRB or wRD)
     if (frun) begin
	xOPC <= wOPC;
	xRD <= wRD;
	xRA <= wRA;
	xRB <= wRB;
	xIMM <= wIMM;	
     end else begin
	xOPC <= 6'o40;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xIMM <= 16'h0;
	xRA <= 5'h0;
	xRB <= 5'h0;
	xRD <= 5'h0;
	// End of automatics
     end // else: !if(frun)
   
   always @(/*AUTOSENSE*/drun or rRD)
     if (drun) begin
	xRD_ <= rRD;
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xRD_ <= 5'h0;
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
   reg [1:0] 	 rMXALU, xMXALU;
   always @(/*AUTOSENSE*/fBRA or fLOGIC or fSHIFT or frun)
     if (frun) begin
	xMXALU <= //(!fNBR) ? 2'o0 :
		  (fSHIFT) ? 2'o2 :
		  (fLOGIC) ? 2'o1 :
		  (fBRA) ? 2'o3 :
		  2'o0;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXALU <= 2'h0;
	// End of automatics
     end // else: !if(frun)
   
   // BCC/BRA/RET
   reg 		 rMXDLY,rMXLNK,xMXDLY,xMXLNK;
   reg [1:0] 	 rMXBRA,xMXBRA;
   always @(/*AUTOSENSE*/fBCC or fBRU or fRET or frun or wRA or wRD)
     if (frun) begin
	xMXBRA <=  //(!fNBR) ? 2'o0 :
		  (fBCC) ? 2'o3 :
		  (fRET) ? 2'o1 :
		  (fBRU) ? 2'o2 :
		  2'o0;	
	xMXDLY <=  //(!fNBR) ? 1'b0 :
		  (fBCC) ? wRD[4] :
		  (fRET) ? 1'b1 :
		  (fBRU) ? wRA[4] :
		  1'b0;
	xMXLNK <=  //(!fNBR) ? 1'b0 :
		  (fBRU) ? wRA[2] : 1'b0;	
     end else begin // if (frun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXBRA <= 2'h0;
	xMXDLY <= 1'h0;
	xMXLNK <= 1'h0;
	// End of automatics
     end // else: !if(frun)
   
   // LD ST
   reg [1:0] 	  rMXLDST,xMXLDST;
   always @(/*AUTOSENSE*/fLD or fST or frun)
     if (frun) begin
	xMXLDST <= //(!fNBR) ? 2'o0 :
		   (fLD) ? 2'o2 :
		   (fST) ? 2'o3 :
		   2'o0;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXLDST <= 2'h0;
	// End of automatics
     end // else: !if(frun)
   
   // SRC/TGT - incorporates forwarding   
   reg [1:0] 	  rMXSRC, rMXTGT, rMXALT, xMXSRC,xMXTGT,xMXALT;
   wire 	  fRWE = (rRD != 5'd0) & (rMXBRA != 2'o3);
   //wire 	  fFWDBCC = (rMXBRA != 2'o3);
   
   always @(/*AUTOSENSE*/fBCC or fBRU or fRWE or frun or rMXLDST
	    or rRD or wOPC or wRA or wRB)
     if (frun) begin
	xMXSRC <= //(!fNBR) ? 2'o0 :
		  (fBRU|fBCC) ? 2'o1 : // PC
		  ((rRD == wRA) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRA) & fRWE) ? 2'o2 : // FWD
		  2'o0; // RA
	xMXTGT <= //(!fNBR) ? 2'o0 :
		  (wOPC[3]) ? 2'o1 : // IMM
		  ((rRD == wRB) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRB) & fRWE) ? 2'o2 : // FWD
		  2'o0;	// RB
	xMXALT <= //(!fNBR) ? 2'o0 :
		  //(fBRU|fBCC) ? 2'o1 : // PC
		  ((rRD == wRA) & (rMXLDST == 2'o2)) ? 2'o3 : // DWB
		  ((rRD == wRA) & fRWE) ? 2'o2 : // FWD
		  2'o0; // RA
     end else begin // if (frun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXALT <= 2'h0;
	xMXSRC <= 2'h0;
	xMXTGT <= 2'h0;
	// End of automatics
     end // else: !if(frun)
       
   // IMM processing
   reg [31:0] 	 rSIMM, xSIMM;
   reg [15:0] 	 rIMMHI, xIMMHI;   
   reg 		 rFIMM, xFIMM;
   
   always @(/*AUTOSENSE*/fIMM or frun or rFIMM or rIMMHI or wIMM)
     if (frun) begin
	xSIMM <= (rFIMM) ? {rIMMHI,wIMM} : {{(16){wIMM[15]}},wIMM};
	xFIMM <= fIMM;	
	xIMMHI <= (fIMM) ? wIMM : rIMMHI;	
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xFIMM <= 1'h0;
	xIMMHI <= 16'h0;
	xSIMM <= 32'h0;
	// End of automatics
     end // else: !if(frun)

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
       3'o0: rBCC <= wBEQ;
       3'o1: rBCC <= wBNE;
       3'o2: rBCC <= wBLT;
       3'o3: rBCC <= wBLE;
       3'o4: rBCC <= wBGT;
       3'o5: rBCC <= wBGE;
       default: rBCC <= 1'b0;
     endcase // case (rRD[2:0])

   // Branch Signal
   reg 	       rBRA, rDLY, rLNK, xBRA, xDLY, xLNK;
   always @(/*AUTOSENSE*/drun or rBCC or rMXBRA or rMXDLY or rMXLNK)
     if (drun) begin
	case (rMXBRA)
	  2'o0: xBRA <= 1'b0;
	  2'o3: xBRA <= rBCC;
	  default: xBRA <= 1'b1;	  
	endcase // case (rMXBRA)
	
	case (rMXBRA)
	  2'o0: xDLY <= 1'b0;	  
	  2'o3: xDLY <= rBCC & rMXDLY;
	  default: xDLY <= rMXDLY;
	endcase // case (rMXBRA)

	case (rMXBRA)
	  2'o2: xLNK <= rMXLNK;	  
	  default: xLNK <= 1'b0;
	endcase // case (rMXBRA)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xBRA <= 1'h0;
	xDLY <= 1'h0;
	xLNK <= 1'h0;
	// End of automatics
     end // else: !if(drun)
   
   // MXRWE
   reg 		 rRWE, xRWE;
   wire 	 wRWE = (rRD != 5'd0);   
   always @(/*AUTOSENSE*/drun or rMXBRA or rMXLDST or wRWE)
     if (drun) begin
	case (rMXBRA)
	  default: xRWE <= 1'b0;	 
	  2'o2: xRWE <= wRWE ^ rMXLDST[0];
	  2'o0: xRWE <= wRWE;	  
	endcase // case (rMXBRA)
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xRWE <= 1'h0;
	// End of automatics
     end // else: !if(drun)

   // DWB logic
   reg rDWBSTB, rDWBWE, xDWBSTB, xDWBWE;
   assign dwb_stb_o = rDWBSTB;
   assign dwb_we_o = rDWBWE;

   always @(/*AUTOSENSE*/drun or rMXLDST)
     if (drun) begin
	xDWBSTB <= rMXLDST[1];
	xDWBWE <= rMXLDST[0];
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xDWBSTB <= 1'h0;
	xDWBWE <= 1'h0;
	// End of automatics
     end
   
   // WB other signals
   assign iwb_stb_o = rIWBSTB;
   assign rIWBSTB = 1'b1;   

   // PIPELINE REGISTERS ///////////////////////////////////////////////

   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	rOPC <= 6'o40;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFIMM <= 1'h0;
	rIMM <= 16'h0;
	rIMMHI <= 16'h0;
	rMXALT <= 2'h0;
	rMXALU <= 2'h0;
	rMXBRA <= 2'h0;
	rMXDLY <= 1'h0;
	rMXLDST <= 2'h0;
	rMXLNK <= 1'h0;
	rMXSRC <= 2'h0;
	rMXTGT <= 2'h0;
	rRA <= 5'h0;
	rRB <= 5'h0;
	rRD <= 5'h0;
	rSIMM <= 32'h0;
	// End of automatics
     end else if (nrun) begin // if (!nrst)
	rIMM <= #1 xIMM;
	rOPC <= #1 xOPC;
	rRA <= #1 xRA;
	rRB <= #1 xRB;
	rRD <= #1 xRD;

	rMXALU <= #1 xMXALU;
	rMXBRA <= #1 xMXBRA;
	rMXDLY <= #1 xMXDLY;
	rMXLNK <= #1 xMXLNK;
	rMXLDST <= #1 xMXLDST;

	rMXSRC <= #1 xMXSRC;
	rMXTGT <= #1 xMXTGT;
	rMXALT <= #1 xMXALT;

	rSIMM <= #1 xSIMM;
	rFIMM <= #1 xFIMM;
	rIMMHI <= #1 xIMMHI;	
     end // else: !if(!nrst)

   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBRA <= 1'h0;
	rDLY <= 1'h0;
	rDWBSTB <= 1'h0;
	rDWBWE <= 1'h0;
	rLNK <= 1'h0;
	rRD_ <= 5'h0;
	rRWE <= 1'h0;
	// End of automatics
     end else if (nrun) begin // if (!nrst)
	rRD_ <= #1 xRD_;
	rBRA <= #1 xBRA;
	rDLY <= #1 xDLY;
	rLNK <= #1 xLNK;
	rRWE <= #1 xRWE;
	rDWBSTB <= #1 xDWBSTB;
	rDWBWE <= #1 xDWBWE;	
     end // else: !if(!nrst)
   
endmodule // aeMB_decode

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// End: