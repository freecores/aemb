// $Id: aeMB_xecu.v,v 1.6 2007-11-10 16:39:38 sybreon Exp $
//
// AEMB MAIN EXECUTION ALU
//
// Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
//  
// This file is part of AEMB.
//
// AEMB is free software: you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// AEMB is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
// or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
// Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public
// License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
//
// $Log: not supported by cvs2svn $
// Revision 1.5  2007/11/09 20:51:52  sybreon
// Added GET/PUT support through a FSL bus.
//
// Revision 1.4  2007/11/08 14:17:47  sybreon
// Parameterised optional components.
//
// Revision 1.3  2007/11/03 08:34:55  sybreon
// Minor code cleanup.
//
// Revision 1.2  2007/11/02 19:20:58  sybreon
// Added better (beta) interrupt support.
// Changed MSR_IE to disabled at reset as per MB docs.
//
// Revision 1.1  2007/11/02 03:25:41  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aeMB_xecu (/*AUTOARG*/
   // Outputs
   dwb_adr_o, dwb_sel_o, fsl_adr_o, rRESULT, rDWBSEL, rMSR_IE,
   rMSR_BIP,
   // Inputs
   rXCE, rREGA, rREGB, rMXSRC, rMXTGT, rRA, rRB, rMXALU, rBRA, rDLY,
   rALT, rSIMM, rIMM, rOPC, rRD, rDWBDI, rPC, gclk, grst, gena
   );
   parameter DW=32;

   parameter MUL=0;
   parameter BSF=0;   
   
   // DATA WISHBONE
   output [DW-1:2] dwb_adr_o;
   output [3:0]    dwb_sel_o;

   // FSL WISHBONE
   output [14:2]   fsl_adr_o;
   
   // INTERNAL
   output [31:0]   rRESULT;
   output [3:0]    rDWBSEL;   
   output 	   rMSR_IE;
   output 	   rMSR_BIP;
   input [1:0] 	   rXCE;   
   input [31:0]    rREGA, rREGB;
   input [1:0] 	   rMXSRC, rMXTGT;
   input [4:0] 	   rRA, rRB;
   input [2:0] 	   rMXALU;
   input 	   rBRA, rDLY;
   input [10:0]    rALT;   
   
   input [31:0]    rSIMM;
   input [15:0]    rIMM;
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD;   
   input [31:0]    rDWBDI;
   input [31:2]    rPC;   
   //input [31:0]    rRES_MUL; // External Multiplier
   //input [31:0]    rRES_BSF; // External Barrel Shifter
   
   // SYSTEM
   input 	   gclk, grst, gena;

   reg 		   rMSR_C, xMSR_C;
   reg 		   rMSR_IE, xMSR_IE;
   reg 		   rMSR_BE, xMSR_BE;
   reg 		   rMSR_BIP, xMSR_BIP;
   
   wire 	   fSKIP = rBRA & !rDLY;

   // --- OPERAND SELECT

   reg [31:0] 	   rOPA, rOPB;
   always @(/*AUTOSENSE*/rDWBDI or rMXSRC or rPC or rREGA or rRESULT)
     case (rMXSRC)
       2'o0: rOPA <= rREGA;
       2'o1: rOPA <= rRESULT;
       2'o2: rOPA <= rDWBDI;
       2'o3: rOPA <= {rPC, 2'o0};       
     endcase // case (rMXSRC)
   
   always @(/*AUTOSENSE*/rDWBDI or rMXTGT or rREGB or rRESULT or rSIMM)
     case (rMXTGT)
       2'o0: rOPB <= rREGB;
       2'o1: rOPB <= rRESULT;
       2'o2: rOPB <= rDWBDI;
       2'o3: rOPB <= rSIMM;       
     endcase // case (rMXTGT)

   // --- ADD/SUB SELECTOR ----
   // FIXME: Redesign
   // TODO: Refactor
   // TODO: Verify signed compare
 
   wire 	    wADDC, wSUBC, wRES_AC, wCMPC, wOPC;
   wire [31:0] 	    wADD, wSUB, wRES_A, wCMP, wOPX;
   
   wire 	    wCMPU = (rOPA > rOPB);         
   wire 	    wCMPF = (rIMM[1]) ? wCMPU :
			    ((wCMPU & ~(rOPB[31] ^ rOPA[31])) | (rOPB[31] & ~rOPA[31]));
   
   assign 	    {wCMPC,wCMP} = {wSUBC,wCMPF,wSUB[30:0]};  
   assign 	    wOPX = (rOPC[0] & !rOPC[5]) ? ~rOPA : rOPA ;
   assign 	    wOPC = ((rMSR_C & rOPC[1]) | (rOPC[0] & !rOPC[1])) & (!rOPC[5] & ~&rOPC[5:4]);
   
   assign 	    {wSUBC,wSUB} = {wADDC,wADD}; 
   assign 	    {wADDC,wADD} = (rOPB + wOPX) + wOPC; 
      
   reg 		    rRES_ADDC;
   reg [31:0] 	    rRES_ADD;
   always @(rIMM or rOPC or wADD or wADDC or wCMP
	    or wCMPC or wSUB or wSUBC)
     case ({rOPC[3],rOPC[0],rIMM[0]})
       4'h2, 4'h6, 4'h7: {rRES_ADDC,rRES_ADD} <= #1 {~wSUBC,wSUB}; // SUB
       4'h3: {rRES_ADDC,rRES_ADD} <= #1 {~wCMPC,wCMP}; // CMP
       default: {rRES_ADDC,rRES_ADD} <= #1 {wADDC,wADD};       
     endcase // case ({rOPC[3],rOPC[0],rIMM[0]})
   
   // --- LOGIC SELECTOR --------------------------------------

   reg [31:0] 	    rRES_LOG;
   always @(/*AUTOSENSE*/rOPA or rOPB or rOPC)
     case (rOPC[1:0])
       2'o0: rRES_LOG <= #1 rOPA | rOPB;
       2'o1: rRES_LOG <= #1 rOPA & rOPB;
       2'o2: rRES_LOG <= #1 rOPA ^ rOPB;
       2'o3: rRES_LOG <= #1 rOPA & ~rOPB;       
     endcase // case (rOPC[1:0])

   // --- SHIFTER SELECTOR ------------------------------------
   
   reg [31:0] 	    rRES_SFT;
   reg 		    rRES_SFTC;
   
   always @(/*AUTOSENSE*/rIMM or rMSR_C or rOPA)
     case (rIMM[6:5])
       2'o0: {rRES_SFT, rRES_SFTC} <= #1 {rOPA[31],rOPA[31:0]};
       2'o1: {rRES_SFT, rRES_SFTC} <= #1 {rMSR_C,rOPA[31:0]};
       2'o2: {rRES_SFT, rRES_SFTC} <= #1 {1'b0,rOPA[31:0]};
       2'o3: {rRES_SFT, rRES_SFTC} <= #1 (rIMM[0]) ? { {(16){rOPA[15]}}, rOPA[15:0], rMSR_C} :
				      { {(24){rOPA[7]}}, rOPA[7:0], rMSR_C};
     endcase // case (rIMM[6:5])

   // --- MOVE SELECTOR ---------------------------------------
   
   wire [31:0] 	    wMSR = {rMSR_C, 3'o0, 
			    20'h0ED32, 
			    4'h0, rMSR_BIP, rMSR_C, rMSR_IE, rMSR_BE};      
   wire 	    fMFSR = (rOPC == 6'o45) & !rIMM[14] & rIMM[0];
   wire 	    fMFPC = (rOPC == 6'o45) & !rIMM[14] & !rIMM[0];
   reg [31:0] 	    rRES_MOV;
   always @(/*AUTOSENSE*/fMFPC or fMFSR or rOPA or rOPB or rPC or rRA
	    or wMSR)
     rRES_MOV <= (fMFSR) ? wMSR :
		 (fMFPC) ? rPC :
		 (rRA[3]) ? rOPB : 
		 rOPA;   
   
   // --- MULTIPLIER ------------------------------------------

   reg [31:0] 	    rRES_MUL;
   always @(/*AUTOSENSE*/rOPA or rOPB) begin
      rRES_MUL <= (rOPA * rOPB);
   end

   // --- BARREL SHIFTER --------------------------------------

   reg [31:0] 	 rRES_BSF;
   reg [31:0] 	 xBSRL, xBSRA, xBSLL;
   
   // Infer a logical left barrel shifter.   
   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSLL <= rOPA << rOPB[4:0];
   
   // Infer a logical right barrel shifter.
   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSRL <= rOPA >> rOPB[4:0];

   // Infer a arithmetic right barrel shifter.
   always @(/*AUTOSENSE*/rOPA or rOPB)
     case (rOPB[4:0])
       5'd00: xBSRA <= rOPA;
       5'd01: xBSRA <= {{(1){rOPA[31]}}, rOPA[31:1]};
       5'd02: xBSRA <= {{(2){rOPA[31]}}, rOPA[31:2]};
       5'd03: xBSRA <= {{(3){rOPA[31]}}, rOPA[31:3]};
       5'd04: xBSRA <= {{(4){rOPA[31]}}, rOPA[31:4]};
       5'd05: xBSRA <= {{(5){rOPA[31]}}, rOPA[31:5]};
       5'd06: xBSRA <= {{(6){rOPA[31]}}, rOPA[31:6]};
       5'd07: xBSRA <= {{(7){rOPA[31]}}, rOPA[31:7]};
       5'd08: xBSRA <= {{(8){rOPA[31]}}, rOPA[31:8]};
       5'd09: xBSRA <= {{(9){rOPA[31]}}, rOPA[31:9]};
       5'd10: xBSRA <= {{(10){rOPA[31]}}, rOPA[31:10]};
       5'd11: xBSRA <= {{(11){rOPA[31]}}, rOPA[31:11]};
       5'd12: xBSRA <= {{(12){rOPA[31]}}, rOPA[31:12]};
       5'd13: xBSRA <= {{(13){rOPA[31]}}, rOPA[31:13]};
       5'd14: xBSRA <= {{(14){rOPA[31]}}, rOPA[31:14]};
       5'd15: xBSRA <= {{(15){rOPA[31]}}, rOPA[31:15]};
       5'd16: xBSRA <= {{(16){rOPA[31]}}, rOPA[31:16]};
       5'd17: xBSRA <= {{(17){rOPA[31]}}, rOPA[31:17]};
       5'd18: xBSRA <= {{(18){rOPA[31]}}, rOPA[31:18]};
       5'd19: xBSRA <= {{(19){rOPA[31]}}, rOPA[31:19]};
       5'd20: xBSRA <= {{(20){rOPA[31]}}, rOPA[31:20]};
       5'd21: xBSRA <= {{(21){rOPA[31]}}, rOPA[31:21]};
       5'd22: xBSRA <= {{(22){rOPA[31]}}, rOPA[31:22]};
       5'd23: xBSRA <= {{(23){rOPA[31]}}, rOPA[31:23]};
       5'd24: xBSRA <= {{(24){rOPA[31]}}, rOPA[31:24]};
       5'd25: xBSRA <= {{(25){rOPA[31]}}, rOPA[31:25]};
       5'd26: xBSRA <= {{(26){rOPA[31]}}, rOPA[31:26]};
       5'd27: xBSRA <= {{(27){rOPA[31]}}, rOPA[31:27]};
       5'd28: xBSRA <= {{(28){rOPA[31]}}, rOPA[31:28]};
       5'd29: xBSRA <= {{(29){rOPA[31]}}, rOPA[31:29]};
       5'd30: xBSRA <= {{(30){rOPA[31]}}, rOPA[31:30]};
       5'd31: xBSRA <= {{(31){rOPA[31]}}, rOPA[31]};
     endcase // case (rOPB[4:0])

   always @(/*AUTOSENSE*/rALT or xBSLL or xBSRA or xBSRL)
     case (rALT[10:9])
       2'd0: rRES_BSF <= xBSRL;
       2'd1: rRES_BSF <= xBSRA;       
       2'd2: rRES_BSF <= xBSLL;
       default: rRES_BSF <= 32'hX;       
     endcase // case (rALT[10:9])
   
   
   // --- MSR REGISTER -----------------
   
   // C
   wire 	   fMTS = (rOPC == 6'o45) & rIMM[14];
   wire 	   fADDC = ({rOPC[5:4], rOPC[2]} == 3'o0);
   
   always @(/*AUTOSENSE*/fADDC or fMTS or fSKIP or rMSR_C or rMXALU
	    or rOPA or rRES_ADDC or rRES_SFTC or rXCE)
     if (fSKIP | |rXCE) begin
	xMSR_C <= rMSR_C;
     end else
       case (rMXALU)
	 3'o0: xMSR_C <= (fADDC) ? rRES_ADDC : rMSR_C;	 
	 3'o1: xMSR_C <= rMSR_C; // LOGIC       
	 3'o2: xMSR_C <= rRES_SFTC; // SHIFT
	 3'o3: xMSR_C <= (fMTS) ? rOPA[2] : rMSR_C;
	 3'o4: xMSR_C <= rMSR_C;	 
	 3'o5: xMSR_C <= rMSR_C;	 
	 default: xMSR_C <= 1'hX;       
       endcase

   // IE/BIP/BE
   wire 	    fRTID = (rOPC == 6'o55) & rRD[0];   
   wire 	    fRTBD = (rOPC == 6'o55) & rRD[1];
   wire 	    fBRK = ((rOPC == 6'o56) | (rOPC == 6'o66)) & (rRA[4:2] == 3'o3);
   
   always @(/*AUTOSENSE*/fMTS or fRTID or rMSR_IE or rOPA or rXCE)
     xMSR_IE <= (rXCE == 2'o2) ? 1'b0 :
		(fRTID) ? 1'b1 : 
		(fMTS) ? rOPA[1] :
		rMSR_IE;      
   
   always @(/*AUTOSENSE*/fBRK or fMTS or fRTBD or rMSR_BIP or rOPA)
     xMSR_BIP <= (fBRK) ? 1'b1 :
		 (fRTBD) ? 1'b0 : 
		 (fMTS) ? rOPA[3] :
		 rMSR_BIP;      
   
   always @(/*AUTOSENSE*/fMTS or rMSR_BE or rOPA)
     xMSR_BE <= (fMTS) ? rOPA[0] : rMSR_BE;      

   // --- RESULT SELECTOR -------------------------------------------
   // Selects results from functional units. 
   reg [31:0] 	   rRESULT, xRESULT;

   // RESULT
   always @(/*AUTOSENSE*/fSKIP or rMXALU or rRES_ADD or rRES_BSF
	    or rRES_LOG or rRES_MOV or rRES_MUL or rRES_SFT)
     if (fSKIP) 
       /*AUTORESET*/
       // Beginning of autoreset for uninitialized flops
       xRESULT <= 32'h0;
       // End of automatics
     else
       case (rMXALU)
	 3'o0: xRESULT <= rRES_ADD;
	 3'o1: xRESULT <= rRES_LOG;
	 3'o2: xRESULT <= rRES_SFT;
	 3'o3: xRESULT <= rRES_MOV;
	 3'o4: xRESULT <= (MUL) ? rRES_MUL : 32'hX;	 
	 3'o5: xRESULT <= (BSF) ? rRES_BSF : 32'hX;	 
	 default: xRESULT <= 32'hX;       
       endcase // case (rMXALU)

   // --- DATA WISHBONE -----
   
   reg [3:0] 	    rDWBSEL, xDWBSEL;
   assign 	    dwb_adr_o = rRESULT[DW-1:2];
   assign 	    dwb_sel_o = rDWBSEL;

   always @(/*AUTOSENSE*/rOPC or wADD)
     case (rOPC[1:0])
       2'o0: case (wADD[1:0]) // 8'bit
	       2'o0: xDWBSEL <= 4'h8;	       
	       2'o1: xDWBSEL <= 4'h4;	       
	       2'o2: xDWBSEL <= 4'h2;	       
	       2'o3: xDWBSEL <= 4'h1;	       
	     endcase // case (wADD[1:0])
       2'o1: xDWBSEL <= (wADD[1]) ? 4'h3 : 4'hC; // 16'bit
       2'o2: xDWBSEL <= 4'hF; // 32'bit
       2'o3: xDWBSEL <= 4'h0; // FSL
     endcase // case (rOPC[1:0])

   // --- FSL WISHBONE --------------------

   reg [14:2] 	    rFSLADR, xFSLADR;   
   
   assign 	    fsl_adr_o = rFSLADR[14:2];

   always @(/*AUTOSENSE*/rALT or rRB) begin
      xFSLADR <= {rALT, rRB[3:2]};      
   end
   
   // --- SYNC ---

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSEL <= 4'h0;
	rFSLADR <= 13'h0;
	rMSR_BE <= 1'h0;
	rMSR_BIP <= 1'h0;
	rMSR_C <= 1'h0;
	rMSR_IE <= 1'h0;
	rRESULT <= 32'h0;
	// End of automatics
     end else if (gena) begin
	rRESULT <= #1 xRESULT;
	rDWBSEL <= #1 xDWBSEL;
	rMSR_C <= #1 xMSR_C;
	rMSR_IE <= #1 xMSR_IE;	
	rMSR_BE <= #1 xMSR_BE;	
	rMSR_BIP <= #1 xMSR_BIP;
	rFSLADR <= #1 xFSLADR;	
     end

endmodule // aeMB_xecu
