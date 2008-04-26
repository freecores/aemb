/* $Id: aeMB2_gprf.v,v 1.3 2008-04-26 01:09:06 sybreon Exp $
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
 * General Purpose Register File
 * @aeMB2_gprf.v
 
 * Dual set of 32 general purpose registers for the core. These are
   R0-R31. A zero is written to R0 for both sets during reset and
   maintained after that.
 
 */

module aeMB2_gprf (/*AUTOARG*/
   // Outputs
   opa_if, opb_if, opd_if,
   // Inputs
   mux_of, mux_ex, ich_dat, rd_of, rd_ex, sel_mx, rpc_mx, xwb_mx,
   dwb_mx, alu_mx, sfr_mx, mul_mx, bsf_mx, gclk, grst, dena, gpha
   );
   parameter AEMB_HTX = 1;   
   
   // INTERNAL
   output [31:0] opa_if,
		 opb_if,
		 opd_if;   
   
   input [2:0] 	 mux_of,
		 mux_ex;
   input [31:0]  ich_dat;
   input [4:0] 	 rd_of,
		 rd_ex;
   
   // DATA SOURCSE
   input [3:0] 	 sel_mx;
   input [31:2]  rpc_mx;
   input [31:0]  xwb_mx,
		 dwb_mx,
		 alu_mx,
		 sfr_mx,
		 mul_mx,
		 bsf_mx;   
   
   // SYSTEM
   input 	 gclk,
		 grst,
		 dena,
		 gpha;   

   /*AUTOWIRE*/
   /*AUTOREG*/

   wire [31:0] 	 opd_wr;      
   reg [31:0] 	 rMEMA[63:0],
		 rMEMB[63:0],
		 rMEMD[63:0];      
   reg [31:0] 	 mem_mx;
   reg [31:0] 	 regd;   
   reg 		 wrb_fb;   
   reg [4:0] 	 rd_mx;
   reg [2:0] 	 mux_mx;   
   
   // PIPELINE
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	mux_mx <= 3'h0;
	rd_mx <= 5'h0;
	wrb_fb <= 1'h0;
	// End of automatics
     end else if (dena) begin
	wrb_fb <= #1 |rd_ex & |mux_ex; // FIXME: check mux
	
	rd_mx <= #1 rd_ex;	
	mux_mx <= #1 mux_ex;	
     end

   // LOAD SIZER   
   always @(/*AUTOSENSE*/dwb_mx or sel_mx) begin
      case (sel_mx)
	// 8'bits
	4'h8: mem_mx <= #1 {24'd0, dwb_mx[31:24]};
	4'h4: mem_mx <= #1 {24'd0, dwb_mx[23:16]};
	4'h2: mem_mx <= #1 {24'd0, dwb_mx[15:8]};
	4'h1: mem_mx <= #1 {24'd0, dwb_mx[7:0]};
	// 16'bits
	4'hC: mem_mx <= #1 {16'd0, dwb_mx[31:16]};
	4'h3: mem_mx <= #1 {16'd0, dwb_mx[15:0]};
	// 32'bits
	4'hF: mem_mx <= #1 dwb_mx;
	//4'h0: mem_mx <= #1 xwb_mx;
	default: mem_mx <= 32'hX;	
      endcase // case (sel_mx)
   end // always @ (...
   
   // SELECT SOURCE
   localparam [2:0] MUX_ALU = 3'o7,
		    MUX_SFR = 3'o5,
		    MUX_BSF = 3'o4,
		    MUX_MUL = 3'o3,
		    MUX_MEM = 3'o2,
		    MUX_RPC = 3'o1,
		    MUX_NOP = 3'o0;   
   
   always @(/*AUTOSENSE*/alu_mx or bsf_mx or mem_mx or mul_mx
	    or mux_mx or rpc_mx or sfr_mx)
     case (mux_mx)
       MUX_ALU: regd <= #1 alu_mx; // ALU
       MUX_RPC: regd <= #1 {rpc_mx[31:2], 2'o0}; // PC Link
       MUX_MEM: regd <= #1 mem_mx; // RAM/FSL
       MUX_MUL: regd <= #1 mul_mx; // MULTIPLIER
       MUX_BSF: regd <= #1 bsf_mx; // SHIFTER
       MUX_NOP: regd <= #1 32'h0;
       MUX_SFR: regd <= #1 sfr_mx;       
       default: regd <= #1 32'hX;                     
     endcase // case (mux_rd)

   
   // REGISTER FILE - Infer LUT memory
   wire [5:0] 	 wRD = {gpha, ich_dat[25:21]};
   wire [5:0] 	 wRA = {gpha, ich_dat[20:16]};
   wire [5:0] 	 wRB = {gpha, ich_dat[15:11]};
   wire [5:0] 	 wRW = {!gpha, rd_mx};
   
   assign 	 opd_wr = rMEMD[wRW];   
   assign 	 opa_if = rMEMA[wRA];
   assign 	 opb_if = rMEMB[wRB];
   assign 	 opd_if = rMEMD[wRD];   
   
   always @(posedge gclk)
     if (grst | (dena & wrb_fb)) begin
	rMEMA[wRW] <= #1 regd;
	rMEMB[wRW] <= #1 regd;	
	rMEMD[wRW] <= #1 regd;
     end
   
   // synopsys translate_off
   // initialise RAM to random contents for simulation only
   integer 	 i;
   initial begin
      for (i=0;i<64;i=i+1) begin
	 rMEMA[i] <= $random;
	 rMEMB[i] <= $random;
	 rMEMD[i] <= $random;      
      end
   end
   // synopsys translate_on
   
endmodule // aeMB2_gprf

/*
 $Log: not supported by cvs2svn $
 Revision 1.2  2008/04/20 16:34:32  sybreon
 Basic version with some features left out.

 Revision 1.1  2008/04/18 00:21:52  sybreon
 Initial import.
*/
