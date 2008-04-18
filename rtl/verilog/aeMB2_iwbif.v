/* $Id: aeMB2_iwbif.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * Instruction Wishbone Interface
 * @file aeMB2_iwbif.v
 
  * This handles the instruction fetch portion of the pipeline. It
    alternates the PC and performs bubble/branch insertion. Bus
    transactions are independent of the pipeline.
 
 */

module aeMB2_iwbif (/*AUTOARG*/
   // Outputs
   iwb_adr_o, iwb_stb_o, iwb_sel_o, iwb_wre_o, iwb_cyc_o, ich_adr,
   ich_fil, fet_fb, rpc_if, rpc_mx,
   // Inputs
   iwb_ack_i, iwb_dat_i, ich_hit, hzd_bpc, hzd_fwd, bra_ex, bpc_ex,
   gclk, grst, dena, iena, gpha
   );
   parameter AEMB_IWB = 32;
   parameter AEMB_HTX = 1;
   
   // Wishbone
   output [AEMB_IWB-1:2] iwb_adr_o;
   output 		 iwb_stb_o;
   output [3:0] 	 iwb_sel_o;
   output 		 iwb_wre_o;
   output 		 iwb_cyc_o;   
   input 		 iwb_ack_i;
   input [31:0] 	 iwb_dat_i;
   
   // Cache
   output [AEMB_IWB-1:2] ich_adr;
   output 		 ich_fil;   
   input 		 ich_hit;
   
   // Internal
   output 		 fet_fb;   
   
   output [31:2] 	 rpc_if,
			 //rpc_of,
			 rpc_mx;

   input 		 hzd_bpc,
			 hzd_fwd;
   
   input [1:0] 		 bra_ex;   
   input [31:2] 	 bpc_ex;
   
   // SYS signals
   input 		 gclk,
			 grst,
			 dena,
			 iena,
			 gpha;      

   assign 		 fet_fb = !iwb_stb_o | iwb_ack_i;   
   
   /*AUTOWIRE*/   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [3:0]		iwb_sel_o;
   reg			iwb_stb_o;
   reg [31:2]		rpc_if;
   reg [31:2]		rpc_mx;
   // End of automatics

   reg [31:2] 		rADR, rADR_;
   reg [31:2] 		rPC0, rPC1;
   
   assign 		iwb_adr_o = rADR;
   assign 		iwb_wre_o = 1'b0;
   assign 		iwb_cyc_o = iwb_stb_o;

   assign 		ich_adr = rADR;
   assign 		ich_fil = iwb_stb_o;
   
   // Hazard detection
   
   // ADDRESS
   wire [31:2] 		wPCINC = (ich_adr + 1); // incrementer
   wire [31:2] 		wPCNXT = rADR_;
   //(gpha & AEMB_HTX[0]) ? rPC1 : rPC0;


   reg [31:2] 		rpc_of, rpc_ex;
   reg 			ich_stb;
   wire 		ich_fb = !ich_stb | ich_hit;

   wire 		fHZD = !ich_fb | hzd_fwd;   
   
   // BARREL
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	iwb_sel_o <= 4'h0;
	rADR <= 30'h0;
	rADR_ <= 30'h0;
	// End of automatics
     end else if (iena) begin
	/*
	if (gpha)
	  rPC0 <= #1 wPCINC;
	else
	  rPC1 <= #1 wPCINC;
	*/
		
	case ({fHZD, bra_ex[1]})
	  2'o0: rADR <= #1 wPCNXT[AEMB_IWB-1:2]; // normal increment
	  2'o1: rADR <= #1 bpc_ex[AEMB_IWB-1:2]; // brach/return/break
	  2'o2: rADR <= #1 rpc_if[AEMB_IWB-1:2]; // bubble/hazard
	  2'o3: rADR <= #1 rpc_if[AEMB_IWB-1:2]; // bubble/hazard
	endcase // case ({fHZD, bra_ex[1]})

	rADR_ <= #1 wPCINC;
	
	//1'b1;	
	iwb_sel_o <= #1 4'hF;	
     end // if (iena)

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rpc_ex <= 30'h0;
	rpc_if <= 30'h0;
	rpc_mx <= 30'h0;
	rpc_of <= 30'h0;
	// End of automatics
     end else if (dena) begin
	/*
	case ({fHZD, bra_ex[1]})
	  2'o0: rADR <= #1 wPCNXT[AEMB_IWB-1:2]; // normal increment
	  2'o1: rADR <= #1 bpc_ex[AEMB_IWB-1:2]; // brach/return/break
	  2'o2: rADR <= #1 rpc_if[AEMB_IWB-1:2]; // bubble/hazard
	 // 2'o3: rADR <= #1 (bra_ex[0]) ? rpc_if[AEMB_IWB-1:2] : bpc_ex[AEMB_IWB-1:2]; // brach/return/break
	  //2'o3: rADR <= #1 bpc_ex[AEMB_IWB-1:2]; // brach/return/break
	  2'o3: rADR <= #1 rpc_if[AEMB_IWB-1:2]; // bubble/hazard
	  //default: rADR <= #1 32'hX; // illegal	  
	endcase // case ({fHZD, bra_ex[1]})
	 */
	
	{rpc_mx, // PC PIPELINE
	 rpc_ex, 
	 rpc_of, 
	 rpc_if} <= #1 {rpc_ex, 
			rpc_of, 
			rpc_if, 
			rADR};		
     end



   
      
   // dislocated from pipeline
   always @(posedge gclk)
     if (grst) begin
	//iwb_stb_o <= 1'b1;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	iwb_stb_o <= 1'h0;
	// End of automatics
     end else begin
	iwb_stb_o <= #1 (!ich_hit & ich_stb) & !iwb_ack_i;
	//& !bra_ex[1];
	//	     iwb_stb_o & !iwb_ack_i;	
	//iwb_stb_o <= #1 (iena) ? (!ich_hit & ich_stb) & !iwb_ack_i : //& !bra_ex[1];
	  //iwb_stb_o & !iwb_ack_i;	
     end

   
endmodule // aeMB2_fetch

// $Log: not supported by cvs2svn $