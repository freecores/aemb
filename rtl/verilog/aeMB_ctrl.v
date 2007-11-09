// $Id: aeMB_ctrl.v,v 1.5 2007-11-09 20:51:52 sybreon Exp $
//
// AEMB CONTROL UNIT
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
// Revision 1.4  2007/11/08 17:48:14  sybreon
// Fixed data WISHBONE arbitration problem (reported by J Lee).
//
// Revision 1.3  2007/11/08 14:17:47  sybreon
// Parameterised optional components.
//
// Revision 1.2  2007/11/02 19:20:58  sybreon
// Added better (beta) interrupt support.
// Changed MSR_IE to disabled at reset as per MB docs.
//
// Revision 1.1  2007/11/02 03:25:40  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aeMB_ctrl (/*AUTOARG*/
   // Outputs
   rMXDST, rMXSRC, rMXTGT, rMXALT, rMXALU, rRW, rDWBSTB, rFSLSTB,
   dwb_stb_o, dwb_wre_o, fsl_stb_o, fsl_wre_o,
   // Inputs
   rXCE, rDLY, rIMM, rALT, rOPC, rRD, rRA, rRB, rPC, rBRA, rMSR_IE,
   dwb_ack_i, iwb_ack_i, fsl_ack_i, gclk, grst, gena
   );
   // INTERNAL   
   //output [31:2] rPCLNK;
   output [1:0]  rMXDST;
   output [1:0]  rMXSRC, rMXTGT, rMXALT;
   output [2:0]  rMXALU;   
   output [4:0]  rRW;
   output 	 rDWBSTB;
   output 	 rFSLSTB;
   
   input [1:0] 	 rXCE;
   input 	 rDLY;
   input [15:0]  rIMM;
   input [10:0]  rALT;
   input [5:0] 	 rOPC;
   input [4:0] 	 rRD, rRA, rRB;
   input [31:2]  rPC;
   input 	 rBRA;
   input 	 rMSR_IE;
   
   // DATA WISHBONE
   output 	 dwb_stb_o;
   output 	 dwb_wre_o;
   input 	 dwb_ack_i;

   // INST WISHBONE
   input 	 iwb_ack_i;   
   
   // FSL WISHBONE
   output 	 fsl_stb_o;
   output 	 fsl_wre_o;
   input 	 fsl_ack_i;   
   
   // SYSTEM
   input 	 gclk, grst, gena;

   // --- DECODE INSTRUCTIONS
   // TODO: Simplify

   wire 	 fSFT = (rOPC == 6'o44);
   wire 	 fLOG = ({rOPC[5:4],rOPC[2]} == 3'o4);   

   wire 	 fMUL = (rOPC == 6'o20) | (rOPC == 6'o30);
   wire 	 fBSF = (rOPC == 6'o21) | (rOPC == 6'o31);
   wire 	 fDIV = (rOPC == 6'o22);   
   
   wire 	 fRTD = (rOPC == 6'o55);
   wire 	 fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 	 fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);
   wire 	 fBRA = fBRU & rRA[3];   

   wire 	 fIMM = (rOPC == 6'o54);
   wire 	 fMOV = (rOPC == 6'o45);   
   
   wire 	 fLOD = ({rOPC[5:4],rOPC[2]} == 3'o6);
   wire 	 fSTR = ({rOPC[5:4],rOPC[2]} == 3'o7);
   wire 	 fLDST = (&rOPC[5:4]);   

   wire          fPUT = (rOPC == 6'o33) & rRB[4];
   wire 	 fGET = (rOPC == 6'o33) & !rRB[4];   
   
   // --- OPERAND SELECTOR ---------------------------------

   wire 	 fRDWE = |rRW;   
   wire 	 fAFWD_M = (rRW == rRA) & (rMXDST == 2'o2) & fRDWE;   
   wire 	 fBFWD_M = (rRW == rRB) & (rMXDST == 2'o2) & fRDWE;   
   wire 	 fAFWD_R = (rRW == rRA) & (rMXDST == 2'o0) & fRDWE;   
   wire 	 fBFWD_R = (rRW == rRB) & (rMXDST == 2'o0) & fRDWE;   

   assign 	 rMXSRC = (fBRU | fBCC) ? 2'o3 : // PC
			  (fAFWD_M) ? 2'o2: // RAM
			  (fAFWD_R) ? 2'o1: // FWD
			  2'o0; // REG

   assign 	 rMXTGT = (rOPC[3]) ? 2'o3 : // IMM
			  (fBFWD_M) ? 2'o2 : // RAM
			  (fBFWD_R) ? 2'o1 : // FWD
			  2'o0; // REG

   assign 	 rMXALT = (fAFWD_M) ? 2'o2 : // RAM
			  (fAFWD_R) ? 2'o1 : // FWD
			  2'o0; // REG
   

   // --- ALU CONTROL ---------------------------------------

   reg [2:0] 	 rMXALU;
   always @(/*AUTOSENSE*/fBRA or fBSF or fDIV or fLOG or fMOV or fMUL
	    or fSFT) begin
      rMXALU <= (fBRA | fMOV) ? 3'o3 :
		(fSFT) ? 3'o2 :
		(fLOG) ? 3'o1 :
		(fMUL) ? 3'o4 :
		(fBSF) ? 3'o5 :
		(fDIV) ? 3'o6 :
		3'o0;      
   end
			   
   
   // --- DELAY SLOT REGISTERS ------------------------------
   
   reg [31:2] 	 rPCLNK, xPCLNK;
   reg [1:0] 	 rMXDST, xMXDST;
   reg [4:0] 	 rRW, xRW;   
   
   wire 	 fSKIP = (rBRA & !rDLY);
   
   always @(/*AUTOSENSE*/fBCC or fBRU or fGET or fLOD or fRTD or fSKIP
	    or fSTR or rRD or rXCE)
     if (fSKIP) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMXDST <= 2'h0;
	xRW <= 5'h0;
	// End of automatics
     end else begin
	case (rXCE)
	  2'o2: xMXDST <= 2'o1;	  
	  default: xMXDST <= (fSTR | fRTD | fBCC) ? 2'o3 :
			     (fLOD | fGET) ? 2'o2 :
			     (fBRU) ? 2'o1 :
			     2'o0;
	endcase

	case (rXCE)
	  2'o2: xRW <= 5'd14;	  
	  default: xRW <= rRD;
	endcase
	
     end // else: !if(fSKIP)


   // --- DATA WISHBONE ----------------------------------

   wire 	 fDACK = !(rDWBSTB ^ dwb_ack_i);
   
   reg 		 rDWBSTB, xDWBSTB;
   reg 		 rDWBWRE, xDWBWRE;

   assign 	 dwb_stb_o = rDWBSTB;
   assign 	 dwb_wre_o = rDWBWRE;
   
   
   always @(/*AUTOSENSE*/fLOD or fSKIP or fSTR or iwb_ack_i or rXCE)
     if (fSKIP | |rXCE) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xDWBSTB <= 1'h0;
	xDWBWRE <= 1'h0;
	// End of automatics
     end else begin
	xDWBSTB <= (fLOD | fSTR) & iwb_ack_i;
	xDWBWRE <= fSTR & iwb_ack_i;	
     end
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBSTB <= 1'h0;
	rDWBWRE <= 1'h0;
	// End of automatics
     end else if (fDACK) begin
	rDWBSTB <= #1 xDWBSTB;
	rDWBWRE <= #1 xDWBWRE;	
     end	
   

   // --- FSL WISHBONE -----------------------------------

   wire 	 fFACK = !(rFSLSTB ^ fsl_ack_i);   
	 
   reg 		 rFSLSTB, xFSLSTB;
   reg 		 rFSLWRE, xFSLWRE;

   assign 	 fsl_stb_o = rFSLSTB;
   assign 	 fsl_wre_o = rFSLWRE;   

   always @(/*AUTOSENSE*/fGET or fPUT or fSKIP or iwb_ack_i or rXCE) 
     if (fSKIP | |rXCE) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xFSLSTB <= 1'h0;
	xFSLWRE <= 1'h0;
	// End of automatics
     end else begin
	xFSLSTB <= (fPUT | fGET) & iwb_ack_i;
	xFSLWRE <= fPUT & iwb_ack_i;	
     end

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFSLSTB <= 1'h0;
	rFSLWRE <= 1'h0;
	// End of automatics
     end else if (fFACK) begin
	rFSLSTB <= #1 xFSLSTB;
	rFSLWRE <= #1 xFSLWRE;	
     end
   
   // --- PIPELINE CONTROL DELAY ----------------------------

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMXDST <= 2'h0;
	rRW <= 5'h0;
	// End of automatics
     end else if (gena) begin
	//rPCLNK <= #1 xPCLNK;
	rMXDST <= #1 xMXDST;
	rRW <= #1 xRW;
     end

   
endmodule // aeMB_ctrl
