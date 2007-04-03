//                              -*- Mode: Verilog -*-
// Filename        : aeMB_aslu.v
// Description     : AEMB Arithmetic Shift Logic Unit
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Sat Dec 30 06:03:24 2006
// Last Modified By: Shawn Tan
// Last Modified On: 2006-12-30
// Update Count    : 0
// Status          : Unknown, Use with caution!

/*
 * $Id: aeMB_aslu.v,v 1.2 2007-04-03 14:46:26 sybreon Exp $
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
 * Arithmetic, shift and logic execution unit
 * 
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 * 
 */

module aeMB_aslu (/*AUTOARG*/
   // Outputs
   dwb_adr_o, rRESULT,
   // Inputs
   dwb_dat_i, rBRA, rDLY, rREGA, rREGB, rSIMM, rMXSRC, rMXTGT, rMXALU,
   rOPC, rPC, rIMM, rRD, rRA, nclk, nrst, drun, drst
   );
   parameter DSIZ = 32;

   output [DSIZ-1:0] dwb_adr_o;
   input [31:0]      dwb_dat_i;   
   
   output [31:0]     rRESULT;
   input 	     rBRA, rDLY;      
   input [31:0]      rREGA, rREGB;
   input [31:0]      rSIMM;
   input [1:0] 	     rMXSRC,rMXTGT;
   input [1:0] 	     rMXALU;
   input [5:0] 	     rOPC;
   input [31:0]      rPC;   
   input [15:0]      rIMM;
   input [4:0] 	     rRD, rRA;   
   
   
   input 	     nclk, nrst, drun, drst;   
   
   reg [31:0] 	    rRESULT;
   reg 		    rMSR_C;
   
   // Endian correction
   //wire [31:0] 	    wDWBDAT = dwb_dat_i;   
   wire [31:0] 	    wDWBDAT = {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]};   
   
   // Source and Target Select
   wire [31:0] 	    wOPA =
		    (rMXSRC == 2'b11) ? wDWBDAT :
		    (rMXSRC == 2'b10) ? rRESULT :
		    (rMXSRC == 2'b01) ? rPC : 
		    rREGA;
   wire [31:0] 	    wOPB =
		    (rMXTGT == 2'b11) ? wDWBDAT :
		    (rMXTGT == 2'b10) ? rRESULT :
		    (rMXTGT == 2'b01) ? rSIMM :
		    rREGB;
   
   // ARITHMETIC
   wire 	    wADDC_ = (rOPC[1]) ? rMSR_C : 1'b0;
   wire 	    wSUBC_ = (rOPC[1]) ? rMSR_C : 1'b1;
   wire 	    wADDC, wSUBC, wRES_AC;   
   wire [31:0] 	    wADD,wSUB,wRES_A;
   assign 	    {wADDC,wADD} = (wOPB + wOPA) + wADDC_;
   assign 	    {wSUBC,wSUB} = (wOPB + ~wOPA) + wSUBC_;
   
   reg 		    rRES_AC;
   reg [31:0] 	    rRES_A;
   always @(/*AUTOSENSE*/rOPC or wADD or wADDC or wSUB or wSUBC)
     {rRES_AC,rRES_A} <= #1 (rOPC[0] & ~rOPC[5]) ? {~wSUBC,wSUB} : {wADDC,wADD};   
   
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
     endcase // case(rOPC[1:0])
   
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
     endcase // case(rIMM[6:5])

   // MOVE
   reg [31:0] 	    rRES_M;
   always @(/*AUTOSENSE*/rRA or wOPA or wOPB)
     rRES_M <= #1 (rRA[3]) ? wOPB : wOPA;   
   
   // RESULT + C
   always @(negedge nclk or negedge drst)
     if (!drst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRESULT <= 32'h0;
	// End of automatics
     end else if (drun) begin
	case (rMXALU)
	  2'o0: rRESULT <= #1 rRES_A;
	  2'o1: rRESULT <= #1 rRES_L;
	  2'o2: rRESULT <= #1 rRES_S;
	  2'o3: rRESULT <= #1 rRES_M;	  
	endcase // case(rMXALU)
     end else begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRESULT <= 32'h0;
	// End of automatics
     end
   
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMSR_C <= 1'h0;
	// End of automatics
     end else if (drun) begin
	case (rMXALU)
	  2'o0: rMSR_C <= #1 (rOPC[2]) ? rMSR_C : rRES_AC;
	  2'o2: rMSR_C <= #1 rRES_SC;
	  default: rMSR_C <= #1 rMSR_C;
	  //rMSR_C;	  
	endcase // case(rMXALU)
     end

   // DWB I/F
   assign 	    dwb_adr_o = rRESULT;
   //{rRESULT[DSIZ-1:2],2'b00};
   
endmodule // aeMB_aslu
