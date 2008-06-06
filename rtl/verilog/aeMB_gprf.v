/* $Id: aeMB_gprf.v,v 1.3 2008-06-06 09:36:02 sybreon Exp $
**
** AEMB EDK 6.2 COMPATIBLE CORE
** Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
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
** License along with AEMB. If not, see <http://www.gnu.org/licenses/>.
*/
/*
 *     +----------+
 *     |          |
 * RA =| REGISTER |= DA
 * RB =| FILE     |= DB
 * RD =|          |= DD
 *     |          |
 * RW =|          |
 *     |          |
 *     +----------+
 */

module aeMB_gprf (/*AUTOARG*/
   // Outputs
   d_da, d_db, d_dd,
   // Inputs
   d_ra, d_rb, d_rd, w_rw, w_sel, w_wre, m_sel, m_dwb, m_xwb, m_bsf,
   m_mul, m_alu, gclk, grst, gena
   );
   // D STAGE
   output [31:0] d_da,
		 d_db,
		 d_dd;
   input [4:0] 	 d_ra,
		 d_rb,
		 d_rd;

   // W STAGE
   input [4:0] 	 w_rw;   
   input [2:0] 	 w_sel; ///< write back selector
   input 	 w_wre; ///< write back enable

   // M STAGE
   input [3:0] 	 m_sel; ///< loaded selector
   input [31:0]  m_dwb, ///< loaded data
		 m_xwb, ///< loaded accelerator
		 m_bsf, ///< barrel shifter
		 m_mul, ///< multiplier
		 m_alu; ///< integer unit
   
   // SYSTEM
   input 	 gclk,
		 grst,
		 gena;

   // LOAD SIZER
   reg [31:0] 	 rmem;   
   always @(/*AUTOSENSE*/m_dwb or m_sel)
     case (m_sel)
       // 8'bits
       4'h8: rmem <= #1 {24'd0, m_dwb[31:24]};
       4'h4: rmem <= #1 {24'd0, m_dwb[23:16]};
       4'h2: rmem <= #1 {24'd0, m_dwb[15:8]};
       4'h1: rmem <= #1 {24'd0, m_dwb[7:0]};
       // 16'bits
       4'hC: rmem <= #1 {16'd0, m_dwb[31:16]};
       4'h3: rmem <= #1 {16'd0, m_dwb[15:0]};
       // 32'bits
       4'hF: rmem <= #1 m_dwb;
       // XSL bus
       4'h0: rmem <= #1 m_dwb;
       default: rmem <= 32'hX;	
     endcase // case (sel_mx)

   // SELECTOR
   reg [31:0] 	 w_dat;
   always @(/*AUTOSENSE*/w_sel)
     case (w_sel)
       default: w_dat <= 32'hX;       
     endcase
		        
   // register write
   wire 	 wWRE = grst | w_wre;   
   
   // register address
   wire [4:0] 	 wRA = d_ra;
   wire [4:0] 	 wRB = d_rb;
   wire [4:0] 	 wRD = d_rd;
   wire [4:0] 	 wRW = w_rw;   

   // register outputs
   wire [31:0] 	 wDA, wDB, wDD;
   assign 	 d_da = ((w_rw == d_ra) & w_wre) ? w_dat : wDA;
   assign 	 d_db = ((w_rw == d_rb) & w_wre) ? w_dat : wDB;
   assign 	 d_dd = ((w_rw == d_rd) & w_wre) ? w_dat : wDD;
      
   /* fasm_dparam AUTO_TEMPLATE "_\([a-z,0-9]+\)" (    
    .AW(5),
    .DW(32),
    
    .dat_o(wD@[31:0]),
    .wre_i(),
    .dat_i(),
    .adr_i(wR@[4:0]),
    .clk_i(),
    .rst_i(),
    .stb_i(),
        
    .xdat_o(),
    .xadr_i(wRW),
    .xdat_i(w_dat),
    .xwre_i(wWRE),
    .xclk_i(gclk),
    .xrst_i(),
    .xstb_i(),
    
    ) */
   
   fasm_dparam
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AW				(5),			 // Templated
       .DW				(32))			 // Templated
   bank_A
     (/*AUTOINST*/
      // Outputs
      .dat_o				(wDA[31:0]),		 // Templated
      .xdat_o				(),			 // Templated
      // Inputs
      .dat_i				(),			 // Templated
      .adr_i				(wRA[4:0]),		 // Templated
      .wre_i				(),			 // Templated
      .stb_i				(),			 // Templated
      .clk_i				(),			 // Templated
      .rst_i				(),			 // Templated
      .xdat_i				(w_dat),		 // Templated
      .xadr_i				(wRW),			 // Templated
      .xwre_i				(wWRE),			 // Templated
      .xstb_i				(),			 // Templated
      .xclk_i				(gclk),			 // Templated
      .xrst_i				());			 // Templated
   
   fasm_dparam
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AW				(5),			 // Templated
       .DW				(32))			 // Templated
   bank_B
     (/*AUTOINST*/
      // Outputs
      .dat_o				(wDB[31:0]),		 // Templated
      .xdat_o				(),			 // Templated
      // Inputs
      .dat_i				(),			 // Templated
      .adr_i				(wRB[4:0]),		 // Templated
      .wre_i				(),			 // Templated
      .stb_i				(),			 // Templated
      .clk_i				(),			 // Templated
      .rst_i				(),			 // Templated
      .xdat_i				(w_dat),		 // Templated
      .xadr_i				(wRW),			 // Templated
      .xwre_i				(wWRE),			 // Templated
      .xstb_i				(),			 // Templated
      .xclk_i				(gclk),			 // Templated
      .xrst_i				());			 // Templated
   
   fasm_dparam
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AW				(5),			 // Templated
       .DW				(32))			 // Templated
   bank_D
     (/*AUTOINST*/
      // Outputs
      .dat_o				(wDD[31:0]),		 // Templated
      .xdat_o				(),			 // Templated
      // Inputs
      .dat_i				(),			 // Templated
      .adr_i				(wRD[4:0]),		 // Templated
      .wre_i				(),			 // Templated
      .stb_i				(),			 // Templated
      .clk_i				(),			 // Templated
      .rst_i				(),			 // Templated
      .xdat_i				(w_dat),		 // Templated
      .xadr_i				(wRW),			 // Templated
      .xwre_i				(wWRE),			 // Templated
      .xstb_i				(),			 // Templated
      .xclk_i				(gclk),			 // Templated
      .xrst_i				());			 // Templated
   
   
endmodule // aeMB_gprf
