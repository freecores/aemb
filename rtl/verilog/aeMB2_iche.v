/* $Id: aeMB2_iche.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * Instruction Cache Block
 * @file aeMB2_iche.v

 * This is a non-optional instruction cache. If it is not enabled, the
   processor will not work. It can be set to the size of a single
   block of RAM to reduce resources.
 
 */

module aeMB2_iche (/*AUTOARG*/
   // Outputs
   ich_dat, ich_hit, ich_fb,
   // Inputs
   ich_adr, ich_fil, iwb_dat_i, iwb_ack_i, rpc_if, gclk, grst, iena,
   gpha
   );
   parameter AEMB_IWB = 32;   
   parameter AEMB_ICH = 11;
   parameter AEMB_HTX = 1;   
   
   // Cache
   input [AEMB_IWB-1:2] ich_adr;
   input 		ich_fil;   
   output [31:0] 	ich_dat;
   output 		ich_hit;
   output 		ich_fb;
   
   // Wishbone
   input [31:0] 	iwb_dat_i;
   input 		iwb_ack_i;   

   // Internal
   input [31:2] 	rpc_if;   
   
   // SYS signals
   input 		gclk,
			grst,
			iena,
			gpha;      
   
   /*AUTOWIRE*/
   /*AUTOREG*/

   wire 		wTAG_HIT, wCHK_HIT;   
   wire [31:0] 		wODAT, wIDAT;
   
   wire [AEMB_IWB-1:AEMB_ICH-1] wTAG_RD, // Tags
				wTAG_PC, 
				wTAG_WR; 
   wire [7:0] 			wCHK_RD, // Checks
				wCHK_WR; 
     
   // TAGS AND HITS
   assign 		ich_fb = ich_hit ;   
   
   assign 		wTAG_PC = rpc_if[AEMB_IWB-1:AEMB_ICH-1];
   assign 		ich_hit = wCHK_HIT & wTAG_HIT;
   
   assign 		wTAG_HIT = (wTAG_PC == wTAG_RD);   
   assign		wCHK_HIT = (wCHK_RD == 8'hAE); 
   
   assign 		wTAG_WR = ich_adr[AEMB_IWB-1:AEMB_ICH-1];
   assign 		wCHK_WR = 8'hAE; // Magic code
   // TODO: Play with the Magic codes
   
   // CACHE RAM INTERFACE
   
   // HTX is enabled, split the cache to avoid trashing.
   assign 		{wTAG_RD, wCHK_RD} = wODAT;   
   assign 		wIDAT = {32'd0, wTAG_WR, wCHK_WR};
   
   wire 		wWRE = iwb_ack_i & ich_fil;   
   wire [AEMB_ICH-2:1] 	wTLNE = {ich_adr[AEMB_ICH-2:2], 1'b1};   
   wire [AEMB_ICH-2:1] 	wDLNE = {ich_adr[AEMB_ICH-2:2], 1'b0};
   
   /* fasm_dpsram AUTO_TEMPLATE (
    .xdat_o(wODAT),
    .xdat_i(wIDAT),
    .xwre_i(wWRE),
    .xadr_i(wTLNE),
    .xclk_i(gclk),
    .xena_i(iena),
    
    .dat_o(ich_dat[31:0]),
    .dat_i(iwb_dat_i[31:0]),
    .adr_i(wDLNE),
    .ena_i(iena),
    .clk_i(gclk),
    .wre_i(wWRE),
    ) */
   
   fasm_dpsram
     #(.AW(AEMB_ICH-2), .DW(32))
   cache0
     (/*AUTOINST*/
      // Outputs
      .dat_o				(ich_dat[31:0]),	 // Templated
      .xdat_o				(wODAT),		 // Templated
      // Inputs
      .adr_i				(wDLNE),		 // Templated
      .dat_i				(iwb_dat_i[31:0]),	 // Templated
      .wre_i				(wWRE),			 // Templated
      .xadr_i				(wTLNE),		 // Templated
      .xdat_i				(wIDAT),		 // Templated
      .xwre_i				(wWRE),			 // Templated
      .clk_i				(gclk),			 // Templated
      .ena_i				(iena),			 // Templated
      .xclk_i				(gclk),			 // Templated
      .xena_i				(iena));			 // Templated
   
endmodule // aeMB2_iche

// $Log: not supported by cvs2svn $