/* $Id: aeMB2_idmx.v,v 1.2 2007-12-12 19:16:59 sybreon Exp $
**
** AEMB2 INSTRUCTION DECODE MUX
** 
** Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
**  
** This file is part of AEMB.
**
** AEMB is free software: you can redistribute it and/or modify it
** under the terms of the GNU Lesser General Public License as
** published by the Free Software Foundation, either version 3 of the
** License, or (at your option) any later version.
**
** AEMB is distributed in the hope that it will be useful, but WITHOUT
** ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
** or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General
** Public License for more details.
**
** You should have received a copy of the GNU Lesser General Public
** License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
*/

module aeMB2_idmx (/*AUTOARG*/
   // Outputs
   rIMM_OF, rOPC_OF, rRA_OF, rRD_OF, rRD_EX, rRD_MA, rOPD_EX, rOPD_MA,
   rALU_OF,
   // Inputs
   rBRA, rXCE, rINT, rIMM_IF, rALT_IF, rOPC_IF, rRA_IF, rRB_IF,
   rRD_IF, rMSR_TXE, pha_i, clk_i, rst_i, ena_i
   );
   parameter TXE = 1;
   
   parameter MUL = 1;
   parameter BSF = 1;
   parameter FSL = 1;   
   
   output [15:0] rIMM_OF;
   output [5:0]  rOPC_OF;
   output [4:0]  rRA_OF,
		 rRD_OF;
   
   output [4:0]  rRD_EX,  
		 rRD_MA;   
   output [2:0]  rOPD_EX,
		 rOPD_MA;
   
   output [2:0]  rALU_OF; // addsub, logic, bshift, sext, mul, mov, ldst

   
   input [1:0] 	 rBRA;
   input 	 rXCE,
		 rINT;
   
   input [15:0]  rIMM_IF;
   input [10:0]  rALT_IF;   
   input [5:0] 	 rOPC_IF;
   input [4:0] 	 rRA_IF,
		 rRB_IF,
		 rRD_IF;
   
   input 	 rMSR_TXE;
   
   input 	 pha_i,
		 clk_i,
		 rst_i,
		 ena_i;   
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [2:0]		rALU_OF;
   reg [15:0]		rIMM_OF;
   reg [5:0]		rOPC_OF;
   reg [2:0]		rOPD_EX;
   reg [2:0]		rOPD_MA;
   reg [4:0]		rRA_OF;
   reg [4:0]		rRD_EX;
   reg [4:0]		rRD_MA;
   reg [4:0]		rRD_OF;
   // End of automatics

   //wire [31:0] 		wXCEOP = 32'hBA2D0020; // Vector 0x20
   wire [31:0] 		wINTOP = 32'hB9CE0010; // Vector 0x10   
   wire [31:0] 		wNOPOP = 32'h88000000; // branch-no-delay/stall
   
   /* Partial decoding */
   wire [5:0] 		rOPC = rOPC_IF;
   wire [4:0] 		rRA = rRA_IF;
   wire [4:0] 		rRB = rRB_IF;   
   wire 		fSFT = (rOPC == 6'o44);
   wire 		fLOG = ({rOPC[5:4],rOPC[2]} == 3'o4);      
   wire 		fMUL = (rOPC == 6'o20) | (rOPC == 6'o30);
   wire 		fBSF = (rOPC == 6'o21) | (rOPC == 6'o31);
   wire 		fDIV = (rOPC == 6'o22);   
   wire 		fRTD = (rOPC == 6'o55);
   wire 		fBCC = (rOPC == 6'o47) | (rOPC == 6'o57);
   wire 		fBRU = (rOPC == 6'o46) | (rOPC == 6'o56);
   wire 		fBRA = fBRU & rRA[3];      
   wire 		fIMM = (rOPC == 6'o54);
   wire 		fMOV = (rOPC == 6'o45);      
   wire 		fLOD = ({rOPC[5:4],rOPC[2]} == 3'o6);
   wire 		fSTR = ({rOPC[5:4],rOPC[2]} == 3'o7);
   wire 		fLDST = (rOPC[5:4] == 2'o3);      
   wire 		fPUT = (rOPC == 6'o33) & rRB[4];
   wire 		fGET = (rOPC == 6'o33) & !rRB[4];
   
   /* Hazard detection */

   wire 		fLOAD = (rOPD_EX == 3'o2);
   wire 		fMULT = (rOPD_EX == 3'o3);
   wire 		fWRE = |rRD_EX;   
   wire 		fOPBHZD = (rRB_IF == rRD_EX) & (fLOAD | fMULT) & !fMOV & !rOPC_IF[3] & fWRE;
   wire 		fOPAHZD = (rRA_IF == rRD_EX) & (fLOAD | fMULT) & !fBRU & fWRE;
   wire 		fOPDHZD = (rRD_IF == rRD_EX) & (fLOAD | fMULT) & fSTR & fWRE;   
   wire 		fHAZARD = fOPBHZD | fOPAHZD | fOPDHZD;
   
   wire 		fSKIP = (rBRA == 2'o2) | // non-delay branch
			!(rMSR_TXE | pha_i) |
			fOPBHZD | fOPAHZD; // hazards

   /* ALU Selector */
   
   always @(posedge clk_i)
     if (rst_i) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rALU_OF <= 3'h0;
	// End of automatics
     end else if (ena_i) begin
	rALU_OF <= #1
		   (fSKIP) ? 3'o1 : // NOP
		   (fBRA | fMOV) ? 3'o3 :
		   (fSFT) ? 3'o2 :
		   (fLOG) ? 3'o1 :
		   (fMUL) ? 3'o4 :
		   (fBSF) ? 3'o5 :
		   3'o0;      	
     end

   /* WB Selector */

   reg [2:0] rOPD_OF;
   
   always @(posedge clk_i)
     if (rst_i) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rOPD_EX <= 3'h0;
	rOPD_MA <= 3'h0;
	rOPD_OF <= 3'h0;
	// End of automatics
     end else if (ena_i) begin
	rOPD_MA <= #1 rOPD_EX;	
	rOPD_EX <= #1 rOPD_OF;	
	rOPD_OF <= #1
		   (fSKIP) ? 3'o7: // NOP
		   (fSTR | fRTD | fBCC) ? 3'o7 : // STR/RTD/BCC		   
		   (fLOD | fGET) ? 3'o2 : // RAM/FSL
		   (fBRU) ? 3'o1 : // PCLNK
		   (fMUL) ? 3'o3 : // MUL
		   (|rRD_IF) ? 3'o0 : // ALU
		   3'o7; // ALU
     end // if (ena_i)
   
   /* Passthrough */

   always @(posedge clk_i)
     if (rst_i) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rIMM_OF <= 16'h0;
	rOPC_OF <= 6'h0;
	rRA_OF <= 5'h0;
	rRD_EX <= 5'h0;
	rRD_MA <= 5'h0;
	rRD_OF <= 5'h0;
	// End of automatics
     end else if (ena_i) begin // if (rst_i)
	rRD_MA <= #1 rRD_EX;
	rRD_EX <= #1 rRD_OF;	
	
	// TODO: Interrrupt
	case (fSKIP)
	  2'o0: {rOPC_OF, rRD_OF, rRA_OF, rIMM_OF} <= #1 {rOPC_IF, rRD_IF, rRA_IF, rIMM_IF};
	  2'o1: {rOPC_OF, rRD_OF, rRA_OF, rIMM_OF} <= #1 wNOPOP; // delay/stall
	  default: {rOPC_OF, rRD_OF, rRA_OF} <= #1 16'hX;	  
	endcase // case (fSKIP)
	
     end // if (ena_i)
   
endmodule // aeMB2_idmx

/* $Log: not supported by cvs2svn $
/* Revision 1.1  2007/12/11 00:43:17  sybreon
/* initial import
/* */