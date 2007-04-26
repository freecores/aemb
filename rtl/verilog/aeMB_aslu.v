/*
 * $Id: aeMB_aslu.v,v 1.6 2007-04-26 14:29:53 sybreon Exp $
 *
 * AEMB Arithmetic Shift Logic Unit 
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
 * Arithmetic, shift and logic execution unit
 * 
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.5  2007/04/25 22:15:04  sybreon
 * Added support for 8-bit and 16-bit data types.
 *
 * Revision 1.4  2007/04/11 04:30:43  sybreon
 * Added pipeline stalling from incomplete bus cycles.
 * Separated sync and async portions of code.
 *
 * Revision 1.3  2007/04/04 06:11:05  sybreon
 * Added CMP instruction
 *
 * Revision 1.2  2007/04/03 14:46:26  sybreon
 * Fixed endian correction issues on data bus.
 *
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

// 246@101
module aeMB_aslu (/*AUTOARG*/
   // Outputs
   dwb_adr_o, dwb_sel_o, rRESULT, rDWBSEL,
   // Inputs
   sDWBDAT, rBRA, rDLY, rREGA, rREGB, rSIMM, rMXSRC, rMXTGT, rMXALU,
   rOPC, rPC, rIMM, rRD, rRA, rMXLDST, nclk, nrst, drun, nrun
   );
   parameter DSIZ = 32;

   output [DSIZ-1:0] dwb_adr_o;
   output [3:0]      dwb_sel_o;   
   //input [31:0]      dwb_dat_i;   
   
   output [31:0]     rRESULT;
   output [3:0]      rDWBSEL;
   input [31:0]      sDWBDAT;   
   input 	     rBRA, rDLY;      
   input [31:0]      rREGA, rREGB;
   input [31:0]      rSIMM;
   input [1:0] 	     rMXSRC,rMXTGT;
   input [1:0] 	     rMXALU;
   input [5:0] 	     rOPC;
   input [31:0]      rPC;   
   input [15:0]      rIMM;
   input [4:0] 	     rRD, rRA;   
   input [1:0] 	     rMXLDST;   
   
   input 	     nclk, nrst, drun, nrun;   
   
   reg [31:0] 	    rRESULT, xRESULT;
   reg 		    rMSR_C, xMSR_C;

   // Operands
   wire [31:0] 	    wOPA, wOPB;   
   
   // DWB I/F
   reg [31:0] 	    rDWBADR;
   wire [31:0] 	    wDWBADR;
   
   assign 	    dwb_adr_o = {rDWBADR[DSIZ-1:2],2'b00};
   //assign 	    wDWBADR = (wOPA + wOPB);   

   reg [3:0] 	    rDWBSEL, xDWBSEL;

   always @(/*AUTOSENSE*/rOPC or wDWBADR)
     case (wDWBADR[1:0])
       2'o0: case (rOPC[1:0])
	       2'o0: xDWBSEL <= 4'h8;
	       2'o1: xDWBSEL <= 4'hC;
	       default: xDWBSEL <= 4'hF;
	     endcase // case (rOPC[1:0])
       2'o1: case (rOPC[1:0])
	       2'o0: xDWBSEL <= 4'h4;
	       default: xDWBSEL <= 4'h0;
	     endcase // case (rOPC[1:0])
       2'o2: case (rOPC[1:0])
	       2'o0: xDWBSEL <= 4'h2;
	       2'o1: xDWBSEL <= 4'h3;
	       default: xDWBSEL <= 4'h0;
	     endcase // case (rOPC[1:0])
       2'o3: case (rOPC[1:0])
	       2'o0: xDWBSEL <= 4'h1;
	       default: xDWBSEL <= 4'h0;
	     endcase // case (rOPC[1:0])
     endcase // case (wDWBADR[1:0])
   
   
   // Endian correction
   wire [31:0] 	    wDWBDAT;
   assign 	    dwb_sel_o = {rDWBSEL[0],rDWBSEL[1],rDWBSEL[2],rDWBSEL[3]};
   assign 	    wDWBDAT = sDWBDAT;
   
   // Source and Target Select
   assign 	    wOPA =
		    (rMXSRC == 2'b11) ? wDWBDAT :
		    (rMXSRC == 2'b10) ? rRESULT :
		    (rMXSRC == 2'b01) ? rPC : 
		    rREGA;
   assign 	    wOPB =
		    (rMXTGT == 2'b11) ? wDWBDAT :
		    (rMXTGT == 2'b10) ? rRESULT :
		    (rMXTGT == 2'b01) ? rSIMM :
		    rREGB;
   
   // ARITHMETIC
   //wire 	    wADDC_ = (rOPC[1] & (rMXLDST == 2'o0)) ? rMSR_C : 1'b0;
   wire 	    wADDC_ = (rOPC[1] & rMSR_C) & ~|rMXLDST;
   wire 	    wSUBC_ = (rOPC[1] & rMSR_C | ~rOPC[1]);
   wire 	    wADDC, wSUBC, wRES_AC, wCMPC, wOPC;
   wire [31:0] 	    wADD, wSUB, wRES_A, wCMP, wOPX;
   
   // TODO: verify signed compare
   
   wire 	    wCMP0 = (wOPA[7:0] > wOPB[7:0]);
   wire 	    wCMP1 = (wOPA[15:8] > wOPB[15:8]);
   wire 	    wCMP2 = (wOPA[23:16] > wOPB[23:16]);
   wire 	    wCMP3 = (wOPA[31:24] > wOPB[31:24]);
   wire 	    wCMPU = wCMP3 | (wCMP2 & ~wCMP3) | (wCMP1 & ~wCMP2 & ~wCMP3) | (wCMP0 & ~wCMP2 & ~wCMP3 & ~wCMP1);
      
   //wire 	    wCMPU = (wOPA > wOPB);   
   wire 	    wCMPF = (rIMM[1]) ? wCMPU :
			    ((wCMPU & ~(wOPB[31] ^ wOPA[31])) | (wOPB[31] & ~wOPA[31]));   
   assign 	    {wCMPC,wCMP} = {wSUBC,wCMPF,wSUB[30:0]};  
   //assign 	    {wADDC,wADD} = (wOPB + wOPA) + wADDC_;
   //assign 	    {wSUBC,wSUB} = (wOPB + ~wOPA) + wSUBC_;
   assign 	    wOPX = (rOPC[0] & !rOPC[5]) ? ~wOPA : wOPA ;
   assign 	    wOPC = (rOPC[0] & !rOPC[5]) ? wSUBC_ : wADDC_ ;   
   assign 	    {wSUBC,wSUB} = {wADDC,wADD}; 
   assign 	    {wADDC,wADD} = (wOPB + wOPX) + wOPC; 
   assign 	    wDWBADR = wADD;
   
   
   reg 		    rRES_AC;
   reg [31:0] 	    rRES_A;
   always @(/*AUTOSENSE*/rIMM or rOPC or wADD or wADDC or wCMP
	    or wCMPC or wSUB or wSUBC)
     //{rRES_AC,rRES_A} <= #1 (rOPC[0] & ~rOPC[5]) ? {~wSUBC,wSUB} : {wADDC,wADD};   
     case ({rOPC[3],rOPC[0],rIMM[0]})
       4'h2, 4'h6, 4'h7: {rRES_AC,rRES_A} <= #1 {~wSUBC,wSUB}; // SUB
       4'h3: {rRES_AC,rRES_A} <= #1 {~wCMPC,wCMP}; // CMP
       default: {rRES_AC,rRES_A} <= #1 {wADDC,wADD};       
     endcase // case ({rOPC[5],rOPC[3],rOPC[0],rIMM[0]})
   
   // LOGIC
   wire [31:0] 	    wOR = wOPA | wOPB;
   wire [31:0] 	    wAND = wOPA & wOPB;
   wire [31:0] 	    wXOR = wOPA ^ wOPB;
   wire [31:0] 	    wANDN = wOPA & ~wOPB;
   
   reg [31:0] 	    rRES_L;
   always @(/*AUTOSENSE*/rOPC or wAND or wANDN or wOR or wXOR)
     case (rOPC[1:0])
       2'o0: rRES_L <= #1 wOR;
       2'o1: rRES_L <= #1 wAND;
       2'o2: rRES_L <= #1 wXOR;
       2'o3: rRES_L <= #1 wANDN;       
     endcase // case (rOPC[1:0])
   
   // SHIFT
   wire 	    wSRAC, wSRCC, wSRLC, wRES_SC;
   wire [31:0] 	    wSRA,wSRC, wSRL, wSEXT8, wSEXT16, wRES_S;
   assign 	    {wSRAC,wSRA} = {wOPA[0],wOPA[0],wOPA[31:1]};
   assign 	    {wSRCC,wSRC} = {wOPA[0],rMSR_C,wOPA[31:1]};
   assign 	    {wSRLC,wSRL} = {wOPA[0],1'b0,wOPA[31:1]};
   assign 	    wSEXT8 = {{(24){wOPA[7]}},wOPA[7:0]};
   assign 	    wSEXT16 = {{(16){wOPA[15]}},wOPA[15:0]};
   
   reg 		    rRES_SC;
   reg [31:0] 	    rRES_S;
   
   always @(/*AUTOSENSE*/rIMM or rMSR_C or wSEXT16 or wSEXT8 or wSRA
	    or wSRAC or wSRC or wSRCC or wSRL or wSRLC)
     case (rIMM[6:5])
       2'o0: {rRES_SC,rRES_S} <= #1 {wSRAC,wSRA};
       2'o1: {rRES_SC,rRES_S} <= #1 {wSRCC,wSRC};
       2'o2: {rRES_SC,rRES_S} <= #1 {wSRLC,wSRL};
       2'o3: {rRES_SC,rRES_S} <= #1 (rIMM[0]) ? {rMSR_C,wSEXT16} : {rMSR_C,wSEXT8};       
     endcase // case (rIMM[6:5])

   // MOVE
   reg [31:0] 	    rRES_M;
   always @(/*AUTOSENSE*/rRA or wOPA or wOPB)
     rRES_M <= #1 (rRA[3]) ? wOPB : wOPA;   
   
   // RESULT + C
   always @(/*AUTOSENSE*/drun or rMSR_C or rMXALU or rOPC or rRES_A
	    or rRES_AC or rRES_L or rRES_M or rRES_S or rRES_SC)
     if (drun) begin
	case (rMXALU)
	  2'o0: xRESULT <= #1 rRES_A;
	  2'o1: xRESULT <= #1 rRES_L;
	  2'o2: xRESULT <= #1 rRES_S;
	  2'o3: xRESULT <= #1 rRES_M;	  
	endcase // case (rMXALU)
	case (rMXALU)
	  2'o0: xMSR_C <= #1 (rOPC[2]) ? rMSR_C : rRES_AC;
	  2'o2: xMSR_C <= #1 rRES_SC;
	  default: xMSR_C <= #1 rMSR_C;
	endcase // case (rMXALU)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xMSR_C <= 1'h0;
	xRESULT <= 32'h0;
	// End of automatics
     end // else: !if(drun)

   // PIPELINE REGISTER //////////////////////////////////////////////////
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBADR <= 32'h0;
	rDWBSEL <= 4'h0;
	rMSR_C <= 1'h0;
	rRESULT <= 32'h0;
	// End of automatics
     end else if (nrun) begin
	rRESULT <= #1 xRESULT;
	rMSR_C <= #1 xMSR_C;
	rDWBADR <= #1 wDWBADR;
	rDWBSEL <= #1 xDWBSEL;	
     end
   
endmodule // aeMB_aslu
