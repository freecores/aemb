//                              -*- Mode: Verilog -*-
// Filename        : aeMB_regfile.v
// Description     : AEMB Register File
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Fri Dec 29 16:17:31 2006
// Last Modified By: $Author: sybreon $
// Last Modified On: $Date: 2007-04-04 06:11:47 $
// Update Count    : $Revision: 1.4 $
// Status          : $State: Exp $

/*
 * $Id: aeMB_regfile.v,v 1.4 2007-04-04 06:11:47 sybreon Exp $
 * 
 * AEMB Register File
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
 * Implements the 32 registers as registers. Some registers require
 * special actions during hardware exception/interrupts. Data forwarding
 * is also taken care of inside here to simplify decode logic.
 *
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.3  2007/04/03 14:46:26  sybreon
 * Fixed endian correction issues on data bus.
 *
 * Revision 1.2  2007/03/26 12:21:31  sybreon
 * Fixed a minor bug where RD is trashed by a STORE instruction. Spotted by Joon Lee.
 *
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

module aeMB_regfile(/*AUTOARG*/
   // Outputs
   dwb_dat_o, rREGA, rREGB,
   // Inputs
   dwb_dat_i, rDWBSTB, rDWBWE, rRA, rRB, rRD, rRD_, rRESULT, rFSM,
   rPC, rPCNXT, rLNK, rRWE, nclk, nrst, drun, drst
   );
   // Data WB bus width
   parameter DSIZ = 32;

   // Data WB I/F
   output [31:0] dwb_dat_o;
   input [31:0]  dwb_dat_i;
   
   // Internal I/F
   output [31:0] rREGA, rREGB;
   input 	 rDWBSTB, rDWBWE;   
   input [4:0] 	 rRA, rRB, rRD, rRD_;   
   input [31:0]  rRESULT;
   input [1:0] 	 rFSM;   
   input [31:0]  rPC, rPCNXT;
   input 	 rLNK, rRWE;
   input 	 nclk, nrst, drun, drst;   
   
   // Register File
   reg [31:0] 	 r00,r01,r02,r03,r04,r05,r06,r07;
   reg [31:0] 	 r08,r09,r0A,r0B,r0C,r0D,r0E,r0F;
   reg [31:0] 	 r10,r11,r12,r13,r14,r15,r16,r17;
   reg [31:0] 	 r18,r19,r1A,r1B,r1C,r1D,r1E,r1F; 		 

   // FLAGS
   wire fWE = rRWE & ~rDWBWE;
   wire fLNK = rLNK;
   wire fLD = rDWBSTB ^ rDWBWE;   

   // PC Latch
   reg [31:0] 	 rPC_;
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rPC_ <= 32'h0;
	// End of automatics
     end else begin
	rPC_ <= #1 rPC;	
     end
   
   // DWB data - Endian Correction
   reg [31:0] 	 rDWBDAT;
   //assign 	 dwb_dat_o = rDWBDAT;
   //wire [31:0] 	 wDWBDAT = dwb_dat_i;
   assign 	 dwb_dat_o = {rDWBDAT[7:0],rDWBDAT[15:8],rDWBDAT[23:16],rDWBDAT[31:24]};   
   wire [31:0] 	 wDWBDAT = {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]};   

   // Forwarding Control
   wire 	 fDFWD = (rRD == rRD_) & fWE;
   wire 	 fMFWD = rDWBSTB & ~rDWBWE;   
   wire [31:0] 	 wRESULT = (fMFWD) ? wDWBDAT : rRESULT;   

   // Register Load
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBDAT <= 32'h0;
	// End of automatics
     end else if (drun) begin
	case (rRD)
	  5'h00: rDWBDAT <= #1 (fDFWD) ? wRESULT : r00;
	  5'h01: rDWBDAT <= #1 (fDFWD) ? wRESULT : r01;
	  5'h02: rDWBDAT <= #1 (fDFWD) ? wRESULT : r02;
	  5'h03: rDWBDAT <= #1 (fDFWD) ? wRESULT : r03;
	  5'h04: rDWBDAT <= #1 (fDFWD) ? wRESULT : r04;
	  5'h05: rDWBDAT <= #1 (fDFWD) ? wRESULT : r05;
	  5'h06: rDWBDAT <= #1 (fDFWD) ? wRESULT : r06;
	  5'h07: rDWBDAT <= #1 (fDFWD) ? wRESULT : r07;
	  5'h08: rDWBDAT <= #1 (fDFWD) ? wRESULT : r08;
	  5'h09: rDWBDAT <= #1 (fDFWD) ? wRESULT : r09;
	  5'h0A: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0A;
	  5'h0B: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0B;
	  5'h0C: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0C;
	  5'h0D: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0D;
	  5'h0E: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0E;
	  5'h0F: rDWBDAT <= #1 (fDFWD) ? wRESULT : r0F;
	  5'h10: rDWBDAT <= #1 (fDFWD) ? wRESULT : r10;
	  5'h11: rDWBDAT <= #1 (fDFWD) ? wRESULT : r11;
	  5'h12: rDWBDAT <= #1 (fDFWD) ? wRESULT : r12;
	  5'h13: rDWBDAT <= #1 (fDFWD) ? wRESULT : r13;
	  5'h14: rDWBDAT <= #1 (fDFWD) ? wRESULT : r14;
	  5'h15: rDWBDAT <= #1 (fDFWD) ? wRESULT : r15;
	  5'h16: rDWBDAT <= #1 (fDFWD) ? wRESULT : r16;
	  5'h17: rDWBDAT <= #1 (fDFWD) ? wRESULT : r17;
	  5'h18: rDWBDAT <= #1 (fDFWD) ? wRESULT : r18;
	  5'h19: rDWBDAT <= #1 (fDFWD) ? wRESULT : r19;
	  5'h1A: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1A;
	  5'h1B: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1B;
	  5'h1C: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1C;
	  5'h1D: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1D;
	  5'h1E: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1E;
	  5'h1F: rDWBDAT <= #1 (fDFWD) ? wRESULT : r1F;
	endcase // case (rRD)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBDAT <= 32'h0;
	// End of automatics
     end // else: !if(drun)

   // Load Registers
   reg [31:0] 	     rREGA, rREGB;
   always @(posedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rREGA <= 32'h0;
	rREGB <= 32'h0;
	// End of automatics
     end else if (drun) begin
	case (rRA)
	  5'h1F: rREGA <= #1 r1F;	  
	  5'h1E: rREGA <= #1 r1E;	  
	  5'h1D: rREGA <= #1 r1D;	  
	  5'h1C: rREGA <= #1 r1C;	  
	  5'h1B: rREGA <= #1 r1B;	  
	  5'h1A: rREGA <= #1 r1A;	  
	  5'h19: rREGA <= #1 r19;	  
	  5'h18: rREGA <= #1 r18;	  
	  5'h17: rREGA <= #1 r17;	  
	  5'h16: rREGA <= #1 r16;	  
	  5'h15: rREGA <= #1 r15;	  
	  5'h14: rREGA <= #1 r14;	  
	  5'h13: rREGA <= #1 r13;	  
	  5'h12: rREGA <= #1 r12;	  
	  5'h11: rREGA <= #1 r11;	  
	  5'h10: rREGA <= #1 r10;	  
	  5'h0F: rREGA <= #1 r0F;	  
	  5'h0E: rREGA <= #1 r0E;	  
	  5'h0D: rREGA <= #1 r0D;	  
	  5'h0C: rREGA <= #1 r0C;	  
	  5'h0B: rREGA <= #1 r0B;	  
	  5'h0A: rREGA <= #1 r0A;	  
	  5'h09: rREGA <= #1 r09;	  
	  5'h08: rREGA <= #1 r08;	  
	  5'h07: rREGA <= #1 r07;	  
	  5'h06: rREGA <= #1 r06;	  
	  5'h05: rREGA <= #1 r05;	  
	  5'h04: rREGA <= #1 r04;	  
	  5'h03: rREGA <= #1 r03;	  
	  5'h02: rREGA <= #1 r02;	  
	  5'h01: rREGA <= #1 r01;	  
	  5'h00: rREGA <= #1 r00;	  
	endcase // case (rRA)

	case (rRB)
	  5'h1F: rREGB <= #1 r1F;	  
	  5'h1E: rREGB <= #1 r1E;	  
	  5'h1D: rREGB <= #1 r1D;	  
	  5'h1C: rREGB <= #1 r1C;	  
	  5'h1B: rREGB <= #1 r1B;	  
	  5'h1A: rREGB <= #1 r1A;	  
	  5'h19: rREGB <= #1 r19;	  
	  5'h18: rREGB <= #1 r18;	  
	  5'h17: rREGB <= #1 r17;	  
	  5'h16: rREGB <= #1 r16;	  
	  5'h15: rREGB <= #1 r15;	  
	  5'h14: rREGB <= #1 r14;	  
	  5'h13: rREGB <= #1 r13;	  
	  5'h12: rREGB <= #1 r12;	  
	  5'h11: rREGB <= #1 r11;	  
	  5'h10: rREGB <= #1 r10;	  
	  5'h0F: rREGB <= #1 r0F;	  
	  5'h0E: rREGB <= #1 r0E;	  
	  5'h0D: rREGB <= #1 r0D;	  
	  5'h0C: rREGB <= #1 r0C;	  
	  5'h0B: rREGB <= #1 r0B;	  
	  5'h0A: rREGB <= #1 r0A;	  
	  5'h09: rREGB <= #1 r09;	  
	  5'h08: rREGB <= #1 r08;	  
	  5'h07: rREGB <= #1 r07;	  
	  5'h06: rREGB <= #1 r06;	  
	  5'h05: rREGB <= #1 r05;	  
	  5'h04: rREGB <= #1 r04;	  
	  5'h03: rREGB <= #1 r03;	  
	  5'h02: rREGB <= #1 r02;	  
	  5'h01: rREGB <= #1 r01;	  
	  5'h00: rREGB <= #1 r00;	  
	endcase // case (rRB)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rREGA <= 32'h0;
	rREGB <= 32'h0;
	// End of automatics
     end // else: !if(drun)
   
   
   // Normal Registers
   wire fR00 = (rRD_ == 5'h00);
   wire fR01 = (rRD_ == 5'h01);
   wire fR02 = (rRD_ == 5'h02);
   wire fR03 = (rRD_ == 5'h03);
   wire fR04 = (rRD_ == 5'h04);
   wire fR05 = (rRD_ == 5'h05);
   wire fR06 = (rRD_ == 5'h06);
   wire fR07 = (rRD_ == 5'h07);
   wire fR08 = (rRD_ == 5'h08);
   wire fR09 = (rRD_ == 5'h09);
   wire fR0A = (rRD_ == 5'h0A);
   wire fR0B = (rRD_ == 5'h0B);
   wire fR0C = (rRD_ == 5'h0C);
   wire fR0D = (rRD_ == 5'h0D);
   wire fR0E = (rRD_ == 5'h0E);
   wire fR0F = (rRD_ == 5'h0F);
   wire fR10 = (rRD_ == 5'h10);
   wire fR11 = (rRD_ == 5'h11);
   wire fR12 = (rRD_ == 5'h12);
   wire fR13 = (rRD_ == 5'h13);
   wire fR14 = (rRD_ == 5'h14);
   wire fR15 = (rRD_ == 5'h15);
   wire fR16 = (rRD_ == 5'h16);
   wire fR17 = (rRD_ == 5'h17);
   wire fR18 = (rRD_ == 5'h18);
   wire fR19 = (rRD_ == 5'h19);
   wire fR1A = (rRD_ == 5'h1A);
   wire fR1B = (rRD_ == 5'h1B);
   wire fR1C = (rRD_ == 5'h1C);
   wire fR1D = (rRD_ == 5'h1D);
   wire fR1E = (rRD_ == 5'h1E);
   wire fR1F = (rRD_ == 5'h1F);
   
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	r01 <= 32'h0;
	r02 <= 32'h0;
	r03 <= 32'h0;
	r04 <= 32'h0;
	r05 <= 32'h0;
	r06 <= 32'h0;
	r07 <= 32'h0;
	r08 <= 32'h0;
	r09 <= 32'h0;
	r0A <= 32'h0;
	r0B <= 32'h0;
	r0C <= 32'h0;
	r0D <= 32'h0;
	r0F <= 32'h0;
	r10 <= 32'h0;
	r12 <= 32'h0;
	r13 <= 32'h0;
	r14 <= 32'h0;
	r15 <= 32'h0;
	r16 <= 32'h0;
	r17 <= 32'h0;
	r18 <= 32'h0;
	r19 <= 32'h0;
	r1A <= 32'h0;
	r1B <= 32'h0;
	r1C <= 32'h0;
	r1D <= 32'h0;
	r1E <= 32'h0;
	r1F <= 32'h0;
	// End of automatics
     end else begin // if (!nrst)
	r01 <= #1 (!fR01) ? r01 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r01;	
	r02 <= #1 (!fR02) ? r02 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r02;	
	r03 <= #1 (!fR03) ? r03 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r03;	
	r04 <= #1 (!fR04) ? r04 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r04;	
	r05 <= #1 (!fR05) ? r05 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r05;	
	r06 <= #1 (!fR06) ? r06 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r06;	
	r07 <= #1 (!fR07) ? r07 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r07;	
	r08 <= #1 (!fR08) ? r08 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r08;	
	r09 <= #1 (!fR09) ? r09 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r09;	
	r0A <= #1 (!fR0A) ? r0A : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0A;	
	r0B <= #1 (!fR0B) ? r0B : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0B;	
	r0C <= #1 (!fR0C) ? r0C : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0C;	
	r0D <= #1 (!fR0D) ? r0D : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0D;	
	r0F <= #1 (!fR0F) ? r0F : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0F;	
	r10 <= #1 (!fR10) ? r10 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r10;	
	r12 <= #1 (!fR12) ? r12 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r12;	
	r13 <= #1 (!fR13) ? r13 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r13;
	
	r14 <= #1 (rFSM == 2'h1) ? rPCNXT : (!fR14) ? r14 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r14;
	
	r15 <= #1 (!fR15) ? r15 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r15;	
	r16 <= #1 (!fR16) ? r16 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r16;
	
	r17 <= #1 (rFSM == 2'h2) ? rPCNXT : (!fR17) ? r17 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r17;
	
	r18 <= #1 (!fR18) ? r18 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r18;	
	r19 <= #1 (!fR19) ? r19 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r19;	
	r1A <= #1 (!fR1A) ? r1A : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1A;	
	r1B <= #1 (!fR1B) ? r1B : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1B;	
	r1C <= #1 (!fR1C) ? r1C : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1C;	
	r1D <= #1 (!fR1D) ? r1D : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1D;	
	r1E <= #1 (!fR1E) ? r1E : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1E;	
	r1F <= #1 (!fR1F) ? r1F : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1F;	

	/*
	r01 <= #1 (!fR01) ? r01 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r01;	
	r02 <= #1 (fR02 & fLD) ? wDWBDAT : (fR02 & fLNK) ? rPC_ : (fR02 & fWE) ? rRESULT : r02;
	r03 <= #1 (fR03 & fLD) ? wDWBDAT : (fR03 & fLNK) ? rPC_ : (fR03 & fWE) ? rRESULT : r03;
	r04 <= #1 (fR04 & fLD) ? wDWBDAT : (fR04 & fLNK) ? rPC_ : (fR04 & fWE) ? rRESULT : r04;
	r05 <= #1 (fR05 & fLD) ? wDWBDAT : (fR05 & fLNK) ? rPC_ : (fR05 & fWE) ? rRESULT : r05;
	r06 <= #1 (fR06 & fLD) ? wDWBDAT : (fR06 & fLNK) ? rPC_ : (fR06 & fWE) ? rRESULT : r06;
	r07 <= #1 (fR07 & fLD) ? wDWBDAT : (fR07 & fLNK) ? rPC_ : (fR07 & fWE) ? rRESULT : r07;
	r08 <= #1 (fR08 & fLD) ? wDWBDAT : (fR08 & fLNK) ? rPC_ : (fR08 & fWE) ? rRESULT : r08;
	r09 <= #1 (fR09 & fLD) ? wDWBDAT : (fR09 & fLNK) ? rPC_ : (fR09 & fWE) ? rRESULT : r09;
	r0A <= #1 (fR0A & fLD) ? wDWBDAT : (fR0A & fLNK) ? rPC_ : (fR0A & fWE) ? rRESULT : r0A;
	r0B <= #1 (fR0B & fLD) ? wDWBDAT : (fR0B & fLNK) ? rPC_ : (fR0B & fWE) ? rRESULT : r0B;
	r0C <= #1 (fR0C & fLD) ? wDWBDAT : (fR0C & fLNK) ? rPC_ : (fR0C & fWE) ? rRESULT : r0C;
	r0D <= #1 (fR0D & fLD) ? wDWBDAT : (fR0D & fLNK) ? rPC_ : (fR0D & fWE) ? rRESULT : r0D;
	//r0E <= #1 (fR0E & fLD) ? wDWBDAT : (fR0E & fLNK) ? rPC_ : (fR0E & fWE) ? rRESULT : r0E;
	r0F <= #1 (fR0F & fLD) ? wDWBDAT : (fR0F & fLNK) ? rPC_ : (fR0F & fWE) ? rRESULT : r0F;
	r10 <= #1 (fR10 & fLD) ? wDWBDAT : (fR10 & fLNK) ? rPC_ : (fR10 & fWE) ? rRESULT : r10;
	//r11 <= #1 (fR11 & fLD) ? wDWBDAT : (fR11 & fLNK) ? rPC_ : (fR11 & fWE) ? rRESULT : r11;
	r12 <= #1 (fR12 & fLD) ? wDWBDAT : (fR12 & fLNK) ? rPC_ : (fR12 & fWE) ? rRESULT : r12;
	r13 <= #1 (fR13 & fLD) ? wDWBDAT : (fR13 & fLNK) ? rPC_ : (fR13 & fWE) ? rRESULT : r13;
	r14 <= #1 (fR14 & fLD) ? wDWBDAT : (fR14 & fLNK) ? rPC_ : (fR14 & fWE) ? rRESULT : r14;
	r15 <= #1 (fR15 & fLD) ? wDWBDAT : (fR15 & fLNK) ? rPC_ : (fR15 & fWE) ? rRESULT : r15;
	r16 <= #1 (fR16 & fLD) ? wDWBDAT : (fR16 & fLNK) ? rPC_ : (fR16 & fWE) ? rRESULT : r16;
	r17 <= #1 (fR17 & fLD) ? wDWBDAT : (fR17 & fLNK) ? rPC_ : (fR17 & fWE) ? rRESULT : r17;
	r18 <= #1 (fR18 & fLD) ? wDWBDAT : (fR18 & fLNK) ? rPC_ : (fR18 & fWE) ? rRESULT : r18;
	r19 <= #1 (fR19 & fLD) ? wDWBDAT : (fR19 & fLNK) ? rPC_ : (fR19 & fWE) ? rRESULT : r19;
	r1A <= #1 (fR1A & fLD) ? wDWBDAT : (fR1A & fLNK) ? rPC_ : (fR1A & fWE) ? rRESULT : r1A;
	r1B <= #1 (fR1B & fLD) ? wDWBDAT : (fR1B & fLNK) ? rPC_ : (fR1B & fWE) ? rRESULT : r1B;
	r1C <= #1 (fR1C & fLD) ? wDWBDAT : (fR1C & fLNK) ? rPC_ : (fR1C & fWE) ? rRESULT : r1C;
	r1D <= #1 (fR1D & fLD) ? wDWBDAT : (fR1D & fLNK) ? rPC_ : (fR1D & fWE) ? rRESULT : r1D;
	r1E <= #1 (fR1E & fLD) ? wDWBDAT : (fR1E & fLNK) ? rPC_ : (fR1E & fWE) ? rRESULT : r1E;
	r1F <= #1 (fR1F & fLD) ? wDWBDAT : (fR1F & fLNK) ? rPC_ : (fR1F & fWE) ? rRESULT : r1F;
	 */
     end // else: !if(!nrst)

   // Special Registers
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	r00 <= 32'h0;
	r0E <= 32'h0;
	r11 <= 32'h0;
	// End of automatics
     end else begin
	// R00 - Zero
	r00 <= #1 r00;	
	// R0E - Interrupt
	r0E <= #1 (rFSM == 2'b11) ? rPC : // Needs verification
	       (!fR0E) ? r0E : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0E;
	// R11 - Exception
	r11 <= #1 (rFSM == 2'b10) ? rPC : // Needs verification
	       (!fR11) ? r11 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r11;	
     end // else: !if(!nrst)


   // Simulation ONLY
   always @(negedge nclk) begin
      if ((fWE & (rRD_== 5'd0)) || (fLNK & (rRD_== 5'd0)) || (fLD & (rRD_== 5'd0))) $displayh("!!! Warning: Write to R0.");
   end	      
      
      
endmodule // aeMB_regfile

// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// End: