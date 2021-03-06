/* $Id: aeMB2_dwbif.v,v 1.7 2008-04-27 16:41:55 sybreon Exp $
**
** AEMB2 EDK 6.2 COMPATIBLE CORE
** Copyright (C) 2004-2008 Shawn Tan <shawn.tan@aeste.net>
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
** License along with AEMB. If not, see <http:**www.gnu.org/licenses/>.
*/
/**
 * Data Wishbone Interface
 * @file aeMB2_dwbif.v
  
 * This sets up the Wishbone control signals for the DATA bus
   interfaces. Bus transactions are independent of the pipeline.
 
 */

module aeMB2_dwbif (/*AUTOARG*/
   // Outputs
   dwb_adr_o, dwb_sel_o, dwb_stb_o, dwb_cyc_o, dwb_tag_o, dwb_wre_o,
   dwb_dat_o, dwb_fb, sel_mx, dwb_mx,
   // Inputs
   dwb_dat_i, dwb_ack_i, imm_of, opd_of, opc_of, opa_of, opb_of,
   msr_ex, mem_ex, sfr_mx, gclk, grst, dena, gpha
   );
   parameter AEMB_DWB = 32; ///< data bus address width   

   // DWB control signals
   output [AEMB_DWB-1:2] dwb_adr_o;   
   output [3:0] 	 dwb_sel_o;   
   output 		 dwb_stb_o,
			 dwb_cyc_o,
			 dwb_tag_o, // cache enable
			 dwb_wre_o;   
   output [31:0] 	 dwb_dat_o;   
   input [31:0] 	 dwb_dat_i; 		 
   input 		 dwb_ack_i;
   
   // INTERNAL
   output 		 dwb_fb;
   output [3:0] 	 sel_mx;   
   output [31:0] 	 dwb_mx;   
   input [15:0] 	 imm_of;
   input [31:0] 	 opd_of;   
   input [5:0] 		 opc_of;    
   input [1:0] 		 opa_of;
   input [1:0] 		 opb_of;
   input [7:0] 		 msr_ex;   
   input [AEMB_DWB-1:2]  mem_ex;
   input [7:5] 		 sfr_mx;   
         
   // SYS signals
   input 		 gclk,
			 grst,
			 dena,
			 gpha;   
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			dwb_cyc_o;
   reg [31:0]		dwb_dat_o;
   reg [31:0]		dwb_mx;
   reg [3:0]		dwb_sel_o;
   reg			dwb_stb_o;
   reg			dwb_wre_o;
   reg [3:0]		sel_mx;
   // End of automatics
   
   wire [1:0] 		wOFF = (opa_of[1:0] + opb_of[1:0]); // small adder   
   wire [3:0] 		wSEL = {opc_of[1:0], wOFF};
   
   // ENABLE FEEDBACK
   assign 		dwb_fb = (dwb_stb_o ~^ dwb_ack_i);   

   // DATA bus
   assign 		dwb_adr_o = mem_ex; // passthru

   // STORE SIZER
   // TODO: Move the right words to the right place
   // TODO: Make this work with dwb_mx to for partial word loads.
   
   reg [31:0] 		dwb_lat;   
   reg [31:0] 		opd_ex;
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_dat_o <= 32'h0;
	// End of automatics
     end else if (dena) begin
	//opd_ex <= #1 opd_of;	
	case (opc_of[1:0])
	  2'o0: dwb_dat_o <= #1 {(4){opd_of[7:0]}};
	  2'o1: dwb_dat_o <= #1 {(2){opd_of[15:0]}};
	  2'o2: dwb_dat_o <= #1 opd_of;
	  default: dwb_dat_o <= #1 32'hX;
	endcase // case (opc_of[1:0])
     end

   // WISHBONE PIPELINE
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_mx <= 32'h0;
	dwb_sel_o <= 4'h0;
	dwb_wre_o <= 1'h0;
	sel_mx <= 4'h0;
	// End of automatics
     end else if (dena) begin
	sel_mx <= #1 dwb_sel_o; // FIXME: do away with this! Combine
				// dwb_dat_o & dwb_mx. dwb_dat_o can
				// hold the existing RD value and have
				// dwb_mx latch the correct bytes
				// depending on dwb_sel_o.
	
	dwb_wre_o <= #1 opc_of[2]; // SXX
	
	dwb_mx <= #1 
		  (dwb_ack_i) ? 
		  dwb_dat_i : // stalled from RAM
		  dwb_lat; // latch earlier data

	case (wSEL) // Latch output
	  // 32'bit
	  4'h8: dwb_sel_o <= #1 4'hF;
	  // 16'bit
	  4'h4: dwb_sel_o <= #1 4'hC;
	  4'h6: dwb_sel_o <= #1 4'h3;
	  // 8'bit
	  4'h0: dwb_sel_o <= #1 4'h8;
	  4'h1: dwb_sel_o <= #1 4'h4;
	  4'h2: dwb_sel_o <= #1 4'h2;
	  4'h3: dwb_sel_o <= #1 4'h1;	
	  // XSL bus
	  4'hC, 4'hD, 4'hE, 4'hF: 
	    dwb_sel_o <= #1 4'h0;
	  // TODO: ILLEGAL
	  default: dwb_sel_o <= #1 4'hX;
	endcase // case (wSEL)
     end // if (dena)

   // Independent on pipeline
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_lat <= 32'h0;
	// End of automatics
     end else if (dwb_ack_i) begin
	// LATCH READS
	dwb_lat <= #1 dwb_dat_i;	
     end
      
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_cyc_o <= 1'h0;
	dwb_stb_o <= 1'h0;
	// End of automatics
     //end else if (dwb_fb) begin
     end else if (dwb_fb) begin
	dwb_stb_o <= #1
		     (dena) ? &opc_of[5:4] : // LXX/SSS
		     (dwb_stb_o & !dwb_ack_i); // LXX/SSS
	dwb_cyc_o <= #1 
		     (dena) ? &opc_of[5:4] | msr_ex[0] :
		     (dwb_stb_o & !dwb_ack_i) | msr_ex[0];	
     end

   assign dwb_tag_o = msr_ex[7]; // MSR_DCE	
   
endmodule // aeMB2_dwbif

/*
 $Log: not supported by cvs2svn $
 Revision 1.6  2008/04/26 17:57:43  sybreon
 Minor performance improvements.

 Revision 1.5  2008/04/26 01:09:05  sybreon
 Passes basic tests. Minor documentation changes to make it compatible with iverilog pre-processor.

 Revision 1.4  2008/04/23 14:18:52  sybreon
 Fixed pipelined latching of data bug.

 Revision 1.3  2008/04/21 12:11:38  sybreon
 Passes arithmetic tests with single thread.

 Revision 1.2  2008/04/20 16:34:32  sybreon
 Basic version with some features left out.

 Revision 1.1  2008/04/18 00:21:52  sybreon
 Initial import.
*/