/* $Id: aeMB2_xslif.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * Accelerator Interface
 * @file aeMB2_xslif.v
  
 * This sets up the Wishbone control signals for the XSEL bus
   interfaces. Bus transactions are independent of the pipeline.
 
 */

module aeMB2_xslif (/*AUTOARG*/
   // Outputs
   xwb_adr_o, xwb_dat_o, xwb_sel_o, xwb_tag_o, xwb_stb_o, xwb_cyc_o,
   xwb_wre_o, xwb_fb, xwb_mx,
   // Inputs
   xwb_dat_i, xwb_ack_i, imm_of, opc_of, opa_of, gclk, grst, dena,
   gpha
   );
   parameter AEMB_XSL = 1; ///< implement XSEL bus   
   parameter AEMB_XWB = 3; ///< XSEL bus width

   // XWB control signals   
   output [AEMB_XWB+1:2] xwb_adr_o;
   output [31:0] 	 xwb_dat_o;   
   output [3:0] 	 xwb_sel_o;
   output 		 xwb_tag_o;   
   output 		 xwb_stb_o,
			 xwb_cyc_o,
			 xwb_wre_o;
   input [31:0] 	 xwb_dat_i; 		 
   input 		 xwb_ack_i;   
      
   // INTERNAL
   output 		 xwb_fb;
   output [31:0] 	 xwb_mx;   
   input [15:0] 	 imm_of;
   input [5:0] 		 opc_of;    
   input [31:0] 	 opa_of;
   
   // SYS signals
   input 		 gclk,
			 grst,
			 dena,
			 gpha;   
   
   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		xwb_dat_o;
   reg [31:0]		xwb_mx;
   // End of automatics

   reg [3:0] 		xSEL;   
   reg			xSTB, xTAG, xWRE, xACK;      
   reg [AEMB_XWB+1:2] 	xADR;   

   assign 		xwb_sel_o = (AEMB_XSL[0]) ? xSEL : 4'hX;
   assign 		xwb_stb_o = (AEMB_XSL[0]) ? xSTB : 1'b0;
   assign 		xwb_cyc_o = xwb_stb_o;   
   assign 		xwb_wre_o = (AEMB_XSL[0]) ? xWRE : 1'bX;
   assign 		xwb_tag_o = (AEMB_XSL[0]) ? xTAG : 1'bX;
   assign 		xwb_adr_o = (AEMB_XSL[0]) ? xADR :
				    {(AEMB_XWB){1'bX}};   

   // ENABLE FEEDBACK
   assign 		xwb_fb = (!xwb_stb_o | xwb_ack_i | xACK); 

   // Independent on pipeline
   reg [31:0] 		xwb_lat;   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xwb_lat <= 32'h0;
	// End of automatics
     end else if (xwb_stb_o & (xwb_ack_i | xACK)) begin
	// LATCH READS	
	xwb_lat <= #1 xwb_dat_i;	
     end
      
   // XSEL bus
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xACK <= 1'h0;
	xADR <= {(1+(AEMB_XWB+1)-(2)){1'b0}};
	xSEL <= 4'h0;
	xTAG <= 1'h0;
	xWRE <= 1'h0;
	xwb_dat_o <= 32'h0;
	xwb_mx <= 32'h0;
	// End of automatics
     end else if (dena) begin // if (grst)	

	xwb_mx <= #1 (xwb_stb_o & (xwb_ack_i | xACK)) ?
		  xwb_dat_i : xwb_lat;	
	
	xADR <= #1 imm_of[11:0]; // FSLx	
	xWRE <= #1 imm_of[15]; // PUT
	xACK <= #1 imm_of[14]; // nGET/nPUT	
	xTAG <= #1 imm_of[13]; // cGET/cPUT
	xSEL <= #1 4'hF; // 32-bit transfers only

	case (opc_of[1:0])
	  2'o3: xwb_dat_o <= #1 opa_of;
	  default: xwb_dat_o <= #1 32'hX;
	endcase // case (opc_of[1:0])
	
     end // if (dena)

   // dislocate from pipeline
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	xSTB <= 1'h0;
	// End of automatics
     end else begin
	xSTB <= #1 (dena) ? &{!opc_of[5],opc_of[4:3]} : // GET/PUT
		(xSTB & !xwb_ack_i);	
     end
   
endmodule // aeMB2_memif

// $Log: not supported by cvs2svn $
