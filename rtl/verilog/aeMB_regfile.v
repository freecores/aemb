/*
 * $Id: aeMB_regfile.v,v 1.11 2007-04-26 14:29:53 sybreon Exp $
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
 * Revision 1.10  2007/04/25 22:52:53  sybreon
 * Fixed minor simulation bug.
 *
 * Revision 1.9  2007/04/25 22:15:04  sybreon
 * Added support for 8-bit and 16-bit data types.
 *
 * Revision 1.8  2007/04/12 20:21:33  sybreon
 * Moved testbench into /sim/verilog.
 * Simulation cleanups.
 *
 * Revision 1.7  2007/04/11 16:30:06  sybreon
 * Cosmetic changes
 *
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
   dwb_dat_o, rREGA, rREGB, sDWBDAT,
   // Inputs
   dwb_dat_i, rDWBSTB, rDWBWE, rRA, rRB, rRD, rRD_, rRESULT, rFSM,
   rPC, rOPC, rDWBSEL, rLNK, rRWE, nclk, nrst, drun, nrun
   );
   // Data WB bus width
   parameter DSIZ = 32;

   // Data WB I/F
   output [31:0] dwb_dat_o;
   input [31:0]  dwb_dat_i;
   
   // Internal I/F
   output [31:0] rREGA, rREGB;
   output [31:0] sDWBDAT;
   
   input 	 rDWBSTB, rDWBWE;   
   input [4:0] 	 rRA, rRB, rRD, rRD_;   
   input [31:0]  rRESULT;
   input [1:0] 	 rFSM;   
   input [31:0]  rPC;
   input [5:0] 	 rOPC;   
   input [3:0] 	 rDWBSEL;   
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
   wire [31:0] 	 wDWBDAT;
   reg [31:0] 	 sDWBDAT;   
   reg [31:0] 	 rDWBDAT;
   assign 	 dwb_dat_o = {rDWBDAT[7:0],rDWBDAT[15:8],rDWBDAT[23:16],rDWBDAT[31:24]};   
   assign 	 wDWBDAT = {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]};   

   always @(/*AUTOSENSE*/rDWBSEL or wDWBDAT)
     case (rDWBSEL)      
       default: sDWBDAT <= wDWBDAT;
       4'hC: sDWBDAT <= {16'd0,wDWBDAT[31:16]};
       4'h3: sDWBDAT <= {16'd0,wDWBDAT[15:0]};
       4'h8: sDWBDAT <= {24'd0,wDWBDAT[31:24]};
       4'h4: sDWBDAT <= {24'd0,wDWBDAT[23:16]};
       4'h2: sDWBDAT <= {24'd0,wDWBDAT[15:8]};
       4'h1: sDWBDAT <= {24'd0,wDWBDAT[7:0]};      
       //default: sDWBDAT <= 32'h0;       
     endcase // case (rDWBSEL)
   
   // Forwarding Control
   wire 	 fDFWD = (rRD == rRD_) & fWE;
   wire 	 fMFWD = rDWBSTB & ~rDWBWE;   
   wire [31:0] 	 wRESULT = (fMFWD) ? sDWBDAT : rRESULT;   
      
   // Alternative Design
   reg [31:0]  rMEMA[0:31], rMEMB[0:31], rMEMD[0:31];
   wire [31:0] wDDAT, wREGA, wREGB, wREGD, wWBDAT;   
   wire        wDWE = (fLD | fLNK | fWE) & |rRD_ & nrun;
   assign      wDDAT = (fLD) ? sDWBDAT :
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

   // Resize
   reg [31:0] sWBDAT;
   always @(/*AUTOSENSE*/rOPC or wWBDAT)
     case (rOPC[1:0])
       2'o0: sWBDAT <= {(4){wWBDAT[7:0]}};       
       2'o1: sWBDAT <= {(2){wWBDAT[15:0]}};
       default: sWBDAT <= wWBDAT;       
     endcase // case (rOPC[1:0])
   
   // PIPELINE REGISTERS //////////////////////////////////////////////////

   reg [31:0] rREGA, rREGB;   
   always @(/*AUTOSENSE*/wREGA or wREGB)
     begin
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
	rDWBDAT <= #1 sWBDAT;	
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
   
endmodule // aeMB_regfile


// Local Variables:
// verilog-library-directories:(".")
// verilog-library-files:("")
// End: