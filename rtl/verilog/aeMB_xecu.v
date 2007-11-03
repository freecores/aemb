// $Id: aeMB_xecu.v,v 1.3 2007-11-03 08:34:55 sybreon Exp $
//
// AEMB MAIN EXECUTION ALU
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

module aeMB_xecu (/*AUTOARG*/
   // Outputs
   dwb_adr_o, dwb_sel_o, rRESULT, rOPA, rOPB, rDWBSEL, rMSR_IE,
   rMSR_BIP,
   // Inputs
   rXCE, rREGA, rREGB, rMXSRC, rMXTGT, rRA, rMXALU, rBRA, rDLY, rSIMM,
   rIMM, rOPC, rRD, rDWBDI, rPC, rRES_MUL, rRES_BSF, gclk, grst, gena
   );
   parameter DW=32;
   
   // DATA WISHBONE
   output [DW-1:2] dwb_adr_o;
   output [3:0]    dwb_sel_o;
   
   // INTERNAL
   output [31:0]   rRESULT;
   output [31:0]   rOPA, rOPB;
   output [3:0]    rDWBSEL;   
   output 	   rMSR_IE;
   output 	   rMSR_BIP;
   input [1:0] 	   rXCE;   
   input [31:0]    rREGA, rREGB;
   input [1:0] 	   rMXSRC, rMXTGT;
   input [4:0] 	   rRA;
   input [2:0] 	   rMXALU;
   input 	   rBRA, rDLY;
   
   //input [1:0] 	   rXCE;   
   input [31:0]    rSIMM;
   input [15:0]    rIMM;
   input [5:0] 	   rOPC;
   input [4:0] 	   rRD;   
   input [31:0]    rDWBDI;
   input [31:2]    rPC;   
   input [31:0]    rRES_MUL; // External Multiplier
   input [31:0]    rRES_BSF; // External Barrel Shifter
   
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
   
   // --- LOGIC SELECTOR ---

   reg [31:0] 	    rRES_LOG;
   always @(/*AUTOSENSE*/rOPA or rOPB or rOPC)
     case (rOPC[1:0])
       2'o0: rRES_LOG <= #1 rOPA | rOPB;
       2'o1: rRES_LOG <= #1 rOPA & rOPB;
       2'o2: rRES_LOG <= #1 rOPA ^ rOPB;
       2'o3: rRES_LOG <= #1 rOPA & ~rOPB;       
     endcase // case (rOPC[1:0])

   // --- SHIFT SELECTOR ---
   
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

   // --- MOVE SELECTOR ---
   
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

   // --- RESULT SELECTOR
   
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
	 3'o4: xRESULT <= rRES_MUL;	 
	 3'o5: xRESULT <= rRES_BSF;	 
	 default: xRESULT <= 32'hX;       
       endcase // case (rMXALU)

   // --- DATA WISHBONE -----
   
   reg [3:0] 	    rDWBSEL, xDWBSEL;
   assign 	    dwb_adr_o = rRESULT[DW-1:2];
   assign 	    dwb_sel_o = rDWBSEL;

   always @(/*AUTOSENSE*/rOPC or wADD)
     case (rOPC[1:0])
       2'o0: case (wADD[1:0])
	       2'o0: xDWBSEL <= 4'h8;	       
	       2'o1: xDWBSEL <= 4'h4;	       
	       2'o2: xDWBSEL <= 4'h2;	       
	       2'o3: xDWBSEL <= 4'h1;	       
	     endcase // case (wADD[1:0])
       2'o1: xDWBSEL <= (wADD[1]) ? 4'h3 : 4'hC;       
       2'o2: xDWBSEL <= 4'hF;       
       default: xDWBSEL <= 4'hX;       
     endcase // case (rOPC[1:0])
   
   // --- SYNC ---

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSEL <= 4'h0;
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
     end

endmodule // aeMB_xecu
