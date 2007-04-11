/*
 * $Id: aeMB_regfile.v,v 1.7 2007-04-11 16:30:06 sybreon Exp $
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
 * Revision 1.6  2007/04/11 04:30:43  sybreon
 * Added pipeline stalling from incomplete bus cycles.
 * Separated sync and async portions of code.
 *
 * Revision 1.5  2007/04/04 14:08:34  sybreon
 * Added initial interrupt/exception support.
 *
 * Revision 1.4  2007/04/04 06:11:47  sybreon
 * Fixed memory read-write data hazard
 *
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

// 1284@78 - REG
// 227@141 - RAM
module aeMB_regfile(/*AUTOARG*/
   // Outputs
   dwb_dat_o, rREGA, rREGB,
   // Inputs
   dwb_dat_i, rDWBSTB, rDWBWE, rRA, rRB, rRD, rRD_, rRESULT, rFSM,
   rPC, rLNK, rRWE, nclk, nrst, drun, nrun
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
   input [31:0]  rPC;
   //, rPCNXT;
   input 	 rLNK, rRWE;
   input 	 nclk, nrst, drun, nrun;   
   
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
     end else if (nrun) begin
	rPC_ <= #1 rPC;	
     end
   
   // DWB data - Endian Correction
   reg [31:0] 	 rDWBDAT, xDWBDAT;
   //assign 	 dwb_dat_o = rDWBDAT;
   //wire [31:0] 	 wDWBDAT = dwb_dat_i;
   assign 	 dwb_dat_o = {rDWBDAT[7:0],rDWBDAT[15:8],rDWBDAT[23:16],rDWBDAT[31:24]};   
   wire [31:0] 	 wDWBDAT = {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]};   

   // Forwarding Control
   wire 	 fDFWD = (rRD == rRD_) & fWE;
   wire 	 fMFWD = rDWBSTB & ~rDWBWE;   
   wire [31:0] 	 wRESULT = (fMFWD) ? wDWBDAT : rRESULT;   

   // Register Load
   always @(/*AUTOSENSE*/drun or fDFWD or r00 or r01 or r02 or r03
	    or r04 or r05 or r06 or r07 or r08 or r09 or r0A or r0B
	    or r0C or r0D or r0E or r0F or r10 or r11 or r12 or r13
	    or r14 or r15 or r16 or r17 or r18 or r19 or r1A or r1B
	    or r1C or r1D or r1E or r1F or rRD or wRESULT)
     if (drun) begin
	case (rRD)
	  5'h00: xDWBDAT <= (fDFWD) ? wRESULT : r00;
	  5'h01: xDWBDAT <= (fDFWD) ? wRESULT : r01;
	  5'h02: xDWBDAT <= (fDFWD) ? wRESULT : r02;
	  5'h03: xDWBDAT <= (fDFWD) ? wRESULT : r03;
	  5'h04: xDWBDAT <= (fDFWD) ? wRESULT : r04;
	  5'h05: xDWBDAT <= (fDFWD) ? wRESULT : r05;
	  5'h06: xDWBDAT <= (fDFWD) ? wRESULT : r06;
	  5'h07: xDWBDAT <= (fDFWD) ? wRESULT : r07;
	  5'h08: xDWBDAT <= (fDFWD) ? wRESULT : r08;
	  5'h09: xDWBDAT <= (fDFWD) ? wRESULT : r09;
	  5'h0A: xDWBDAT <= (fDFWD) ? wRESULT : r0A;
	  5'h0B: xDWBDAT <= (fDFWD) ? wRESULT : r0B;
	  5'h0C: xDWBDAT <= (fDFWD) ? wRESULT : r0C;
	  5'h0D: xDWBDAT <= (fDFWD) ? wRESULT : r0D;
	  5'h0E: xDWBDAT <= (fDFWD) ? wRESULT : r0E;
	  5'h0F: xDWBDAT <= (fDFWD) ? wRESULT : r0F;
	  5'h10: xDWBDAT <= (fDFWD) ? wRESULT : r10;
	  5'h11: xDWBDAT <= (fDFWD) ? wRESULT : r11;
	  5'h12: xDWBDAT <= (fDFWD) ? wRESULT : r12;
	  5'h13: xDWBDAT <= (fDFWD) ? wRESULT : r13;
	  5'h14: xDWBDAT <= (fDFWD) ? wRESULT : r14;
	  5'h15: xDWBDAT <= (fDFWD) ? wRESULT : r15;
	  5'h16: xDWBDAT <= (fDFWD) ? wRESULT : r16;
	  5'h17: xDWBDAT <= (fDFWD) ? wRESULT : r17;
	  5'h18: xDWBDAT <= (fDFWD) ? wRESULT : r18;
	  5'h19: xDWBDAT <= (fDFWD) ? wRESULT : r19;
	  5'h1A: xDWBDAT <= (fDFWD) ? wRESULT : r1A;
	  5'h1B: xDWBDAT <= (fDFWD) ? wRESULT : r1B;
	  5'h1C: xDWBDAT <= (fDFWD) ? wRESULT : r1C;
	  5'h1D: xDWBDAT <= (fDFWD) ? wRESULT : r1D;
	  5'h1E: xDWBDAT <= (fDFWD) ? wRESULT : r1E;
	  5'h1F: xDWBDAT <= (fDFWD) ? wRESULT : r1F;
	endcase // case (rRD)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xDWBDAT <= 32'h0;
	// End of automatics
     end // else: !if(drun)

   // Load Registers
   reg [31:0] 	     xREGA, xREGB;
   always @(/*AUTOSENSE*/drun or r00 or r01 or r02 or r03 or r04
	    or r05 or r06 or r07 or r08 or r09 or r0A or r0B or r0C
	    or r0D or r0E or r0F or r10 or r11 or r12 or r13 or r14
	    or r15 or r16 or r17 or r18 or r19 or r1A or r1B or r1C
	    or r1D or r1E or r1F or rRA or rRB)
     if (drun) begin
	case (rRA)
	  5'h1F: xREGA <= r1F;	  
	  5'h1E: xREGA <= r1E;	  
	  5'h1D: xREGA <= r1D;	  
	  5'h1C: xREGA <= r1C;	  
	  5'h1B: xREGA <= r1B;	  
	  5'h1A: xREGA <= r1A;	  
	  5'h19: xREGA <= r19;	  
	  5'h18: xREGA <= r18;	  
	  5'h17: xREGA <= r17;	  
	  5'h16: xREGA <= r16;	  
	  5'h15: xREGA <= r15;	  
	  5'h14: xREGA <= r14;	  
	  5'h13: xREGA <= r13;	  
	  5'h12: xREGA <= r12;	  
	  5'h11: xREGA <= r11;	  
	  5'h10: xREGA <= r10;	  
	  5'h0F: xREGA <= r0F;	  
	  5'h0E: xREGA <= r0E;	  
	  5'h0D: xREGA <= r0D;	  
	  5'h0C: xREGA <= r0C;	  
	  5'h0B: xREGA <= r0B;	  
	  5'h0A: xREGA <= r0A;	  
	  5'h09: xREGA <= r09;	  
	  5'h08: xREGA <= r08;	  
	  5'h07: xREGA <= r07;	  
	  5'h06: xREGA <= r06;	  
	  5'h05: xREGA <= r05;	  
	  5'h04: xREGA <= r04;	  
	  5'h03: xREGA <= r03;	  
	  5'h02: xREGA <= r02;	  
	  5'h01: xREGA <= r01;	  
	  5'h00: xREGA <= r00;	  
	endcase // case (rRA)

	case (rRB)
	  5'h1F: xREGB <= r1F;	  
	  5'h1E: xREGB <= r1E;	  
	  5'h1D: xREGB <= r1D;	  
	  5'h1C: xREGB <= r1C;	  
	  5'h1B: xREGB <= r1B;	  
	  5'h1A: xREGB <= r1A;	  
	  5'h19: xREGB <= r19;	  
	  5'h18: xREGB <= r18;	  
	  5'h17: xREGB <= r17;	  
	  5'h16: xREGB <= r16;	  
	  5'h15: xREGB <= r15;	  
	  5'h14: xREGB <= r14;	  
	  5'h13: xREGB <= r13;	  
	  5'h12: xREGB <= r12;	  
	  5'h11: xREGB <= r11;	  
	  5'h10: xREGB <= r10;	  
	  5'h0F: xREGB <= r0F;	  
	  5'h0E: xREGB <= r0E;	  
	  5'h0D: xREGB <= r0D;	  
	  5'h0C: xREGB <= r0C;	  
	  5'h0B: xREGB <= r0B;	  
	  5'h0A: xREGB <= r0A;	  
	  5'h09: xREGB <= r09;	  
	  5'h08: xREGB <= r08;	  
	  5'h07: xREGB <= r07;	  
	  5'h06: xREGB <= r06;	  
	  5'h05: xREGB <= r05;	  
	  5'h04: xREGB <= r04;	  
	  5'h03: xREGB <= r03;	  
	  5'h02: xREGB <= r02;	  
	  5'h01: xREGB <= r01;	  
	  5'h00: xREGB <= r00;	  
	endcase // case (rRB)
     end else begin // if (drun)
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xREGA <= 32'h0;
	xREGB <= 32'h0;
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
	r14 <= #1 (!fR14) ? r14 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r14;	
	r15 <= #1 (!fR15) ? r15 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r15;	
	r16 <= #1 (!fR16) ? r16 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r16;	
	r17 <= #1 (!fR17) ? r17 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r17;	
	r18 <= #1 (!fR18) ? r18 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r18;	
	r19 <= #1 (!fR19) ? r19 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r19;	
	r1A <= #1 (!fR1A) ? r1A : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1A;	
	r1B <= #1 (!fR1B) ? r1B : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1B;	
	r1C <= #1 (!fR1C) ? r1C : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1C;	
	r1D <= #1 (!fR1D) ? r1D : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1D;	
	r1E <= #1 (!fR1E) ? r1E : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1E;	
	r1F <= #1 (!fR1F) ? r1F : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r1F;	

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
	r0E <= #1 //(rFSM == 2'b01) ? rPCNXT :
	       (!fR0E) ? r0E : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r0E;
	// R11 - Exception
	r11 <= #1 //(rFSM == 2'b10) ? rPCNXT :
	       (!fR11) ? r11 : (fLD) ? wDWBDAT : (fLNK) ? rPC_ : (fWE) ? rRESULT : r11;	
     end // else: !if(!nrst)

   // Alternative Design
   reg [31:0]  rMEMA[0:31], rMEMB[0:31], rMEMD[0:31];
   wire [31:0] wDDAT, wREGA, wREGB, wREGD, wWBDAT;   
   wire        wDWE = (fLD | fLNK | fWE) & |rRD_ & nrun;
   assign      wDDAT = (fLD) ? wDWBDAT :
		       (fLNK) ? rPC_ : rRESULT;		       
   assign      wWBDAT = (fDFWD) ? wRESULT : wREGD;   
   
   assign      wREGA = rMEMA[rRA];
   assign      wREGB = rMEMB[rRB];
   assign      wREGD = rMEMD[rRD];
   
   always @(negedge nclk)
     if (wDWE) begin
	rMEMA[rRD_] <= wDDAT;
	rMEMB[rRD_] <= wDDAT;
	rMEMD[rRD_] <= wDDAT;	 
     end
   
   // PIPELINE REGISTERS //////////////////////////////////////////////////

   reg [31:0] rREGA, rREGB;   
   always @(/*AUTOSENSE*/wREGA or wREGB)
     begin
	//rREGA <= #1 xREGA;
	//rREGB <= #1 xREGB;
	rREGA <= #1 wREGA;
	rREGB <= #1 wREGB;	
     end
   
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rDWBDAT <= 32'h0;
	// End of automatics
     end else if (nrun) begin
	//rDWBDAT <= #1 xDWBDAT;	
	rDWBDAT <= #1 wWBDAT;	
     end

   // SIMULATION ONLY ///////////////////////////////////////////////////
   integer i;
   initial begin
      for (i=0;i<31;i=i+1) begin
	 rMEMA[i] <= 0;
	 rMEMB[i] <= 0;
	 rMEMD[i] <= 0;	 
      end
   end
   
   always @(negedge nclk) begin
      if ((fWE & (rRD_== 5'd0)) || (fLNK & (rRD_== 5'd0)) || (fLD & (rRD_== 5'd0))) $displayh("!!! Warning: Write to R0 !!!");
   end
   
endmodule // aeMB_regfile


// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// End: