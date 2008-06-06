/* $Id: aeMB_dwbif.v,v 1.1 2008-06-06 09:36:02 sybreon Exp $
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

module aeMB_dwbif (/*AUTOARG*/
   // Outputs
   dwb_adr_o, dwb_sel_o, dwb_stb_o, dwb_cyc_o, dwb_tag_o, dwb_wre_o,
   dwb_dat_o, z_dwb, m_sel, m_dwb,
   // Inputs
   dwb_dat_i, dwb_ack_i, x_opd, x_opc, x_opa, x_opb, r_msr, x_add,
   gclk, grst, gena, gpha
   );
   parameter DWB = 32; ///< data bus address width   
   
   // DWB control signals
   output [DWB-1:2] dwb_adr_o;   
   output [3:0]     dwb_sel_o;   
   output 	    dwb_stb_o,
		    dwb_cyc_o,
		    dwb_tag_o, // cache enable
		    dwb_wre_o;   
   output [31:0]    dwb_dat_o;   
   input [31:0]     dwb_dat_i; 		 
   input 	    dwb_ack_i;
   
   // INTERNAL
   output 	    z_dwb;
   output [3:0]     m_sel;   
   output [31:0]    m_dwb;   
   input [31:0]     x_opd;   
   input [5:0] 	    x_opc;    
   input [1:0] 	    x_opa;
   input [1:0] 	    x_opb;
   input [7:0] 	    r_msr;   
   input [DWB-1:2]  x_add;
   
   // SYS signals
   input 	    gclk,
		    grst,
		    gena,
		    gpha;   
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg			dwb_cyc_o;
   reg [31:0]		dwb_dat_o;
   reg [3:0]		dwb_sel_o;
   reg			dwb_stb_o;
   reg			dwb_wre_o;
   reg [31:0]		m_dwb;
   reg [3:0]		m_sel;
   // End of automatics
   
   wire [1:0] 		wOFF = (x_opa[1:0] + x_opb[1:0]); // small adder   
   wire [3:0] 		wSEL = {x_opc[1:0], wOFF};
   
   // ENABLE FEEDBACK
   assign 		z_dwb = (dwb_stb_o ~^ dwb_ack_i);   

   // DATA bus
   assign 		dwb_adr_o = x_add; // passthru

   // STORE SIZER
   // TODO: Move the right words to the right place
   // TODO: Make this work with m_dwb to for partial word loads.
   
   reg [31:0] 		dwb_lat;   
   reg [31:0] 		opd_ex;
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_dat_o <= 32'h0;
	// End of automatics
     end else if (gena) begin
	//opd_ex <= #1 x_opd;	
	case (x_opc[1:0])
	  2'o0: dwb_dat_o <= #1 {(4){x_opd[7:0]}};
	  2'o1: dwb_dat_o <= #1 {(2){x_opd[15:0]}};
	  2'o2: dwb_dat_o <= #1 x_opd;
	  default: dwb_dat_o <= #1 32'hX;
	endcase // case (x_opc[1:0])
     end

   // WISHBONE PIPELINE
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	dwb_sel_o <= 4'h0;
	dwb_wre_o <= 1'h0;
	m_dwb <= 32'h0;
	m_sel <= 4'h0;
	// End of automatics
     end else if (gena) begin
	m_sel <= #1 dwb_sel_o; // FIXME: do away with this! Combine
				// dwb_dat_o & m_dwb. dwb_dat_o can
				// hold the existing RD value and have
				// m_dwb latch the correct bytes
				// depending on dwb_sel_o.
	
	dwb_wre_o <= #1 x_opc[2]; // SXX
	
	m_dwb <= #1 (dwb_ack_i) ? 
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
     end // if (gena)

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
     //end else if (z_dwb) begin
     end else if (z_dwb) begin
	dwb_stb_o <= #1
		     (gena) ? &x_opc[5:4] : // LXX/SSS
		     (dwb_stb_o & !dwb_ack_i); // LXX/SSS
	dwb_cyc_o <= #1 
		     (gena) ? &x_opc[5:4] | r_msr[0] :
		     (dwb_stb_o & !dwb_ack_i) | r_msr[0];	
     end

   assign dwb_tag_o = r_msr[7]; // MSR_DCE	
   
endmodule // aeMB2_dwbif

