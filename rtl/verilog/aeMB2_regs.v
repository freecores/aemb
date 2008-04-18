/* $Id: aeMB2_regs.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * Register File Wrapper
 * @file aeMB2_regs.v

 * A collection of general purpose and special function registers.
 
 */

module aeMB2_regs (/*AUTOARG*/
   // Outputs
   opd_if, opb_if, opa_if,
   // Inputs
   xwb_mx, sfr_mx, sel_mx, rpc_mx, rpc_if, rd_of, rd_ex, ra_of,
   opc_of, opa_of, mux_of, mux_ex, mul_mx, imm_of, ich_dat, grst,
   gpha, gclk, dwb_mx, dena, bsf_mx, alu_mx, alu_c
   );

   parameter AEMB_HTX = 1;

   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	opa_if;			// From gprf0 of aeMB2_gprf.v
   output [31:0]	opb_if;			// From gprf0 of aeMB2_gprf.v
   output [31:0]	opd_if;			// From gprf0 of aeMB2_gprf.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		alu_c;			// To sfrf0 of aeMB2_sfrf.v
   input [31:0]		alu_mx;			// To gprf0 of aeMB2_gprf.v
   input [31:0]		bsf_mx;			// To gprf0 of aeMB2_gprf.v
   input		dena;			// To sfrf0 of aeMB2_sfrf.v, ...
   input [31:0]		dwb_mx;			// To gprf0 of aeMB2_gprf.v
   input		gclk;			// To sfrf0 of aeMB2_sfrf.v, ...
   input		gpha;			// To sfrf0 of aeMB2_sfrf.v, ...
   input		grst;			// To sfrf0 of aeMB2_sfrf.v, ...
   input [31:0]		ich_dat;		// To sfrf0 of aeMB2_sfrf.v, ...
   input [15:0]		imm_of;			// To sfrf0 of aeMB2_sfrf.v
   input [31:0]		mul_mx;			// To gprf0 of aeMB2_gprf.v
   input [2:0]		mux_ex;			// To gprf0 of aeMB2_gprf.v
   input [2:0]		mux_of;			// To gprf0 of aeMB2_gprf.v
   input [31:0]		opa_of;			// To sfrf0 of aeMB2_sfrf.v
   input [5:0]		opc_of;			// To sfrf0 of aeMB2_sfrf.v
   input [4:0]		ra_of;			// To sfrf0 of aeMB2_sfrf.v
   input [4:0]		rd_ex;			// To gprf0 of aeMB2_gprf.v
   input [4:0]		rd_of;			// To sfrf0 of aeMB2_sfrf.v, ...
   input [31:2]		rpc_if;			// To sfrf0 of aeMB2_sfrf.v
   input [31:2]		rpc_mx;			// To gprf0 of aeMB2_gprf.v
   input [3:0]		sel_mx;			// To gprf0 of aeMB2_gprf.v
   input [31:0]		sfr_mx;			// To gprf0 of aeMB2_gprf.v
   input [31:0]		xwb_mx;			// To gprf0 of aeMB2_gprf.v
   // End of automatics
   /*AUTOWIRE*/
   
   aeMB2_sfrf
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AEMB_HTX			(AEMB_HTX))
   sfrf0
     (/*AUTOINST*/
      // Inputs
      .rpc_if				(rpc_if[31:2]),
      .alu_c				(alu_c),
      .opc_of				(opc_of[5:0]),
      .imm_of				(imm_of[15:0]),
      .ra_of				(ra_of[4:0]),
      .rd_of				(rd_of[4:0]),
      .opa_of				(opa_of[31:0]),
      .ich_dat				(ich_dat[15:10]),
      .gclk				(gclk),
      .grst				(grst),
      .gpha				(gpha),
      .dena				(dena));
   
   
   aeMB2_gprf
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AEMB_HTX			(AEMB_HTX))
   gprf0
     (/*AUTOINST*/
      // Outputs
      .opa_if				(opa_if[31:0]),
      .opb_if				(opb_if[31:0]),
      .opd_if				(opd_if[31:0]),
      // Inputs
      .mux_of				(mux_of[2:0]),
      .mux_ex				(mux_ex[2:0]),
      .ich_dat				(ich_dat[31:0]),
      .rd_of				(rd_of[4:0]),
      .rd_ex				(rd_ex[4:0]),
      .sel_mx				(sel_mx[3:0]),
      .rpc_mx				(rpc_mx[31:2]),
      .xwb_mx				(xwb_mx[31:0]),
      .dwb_mx				(dwb_mx[31:0]),
      .alu_mx				(alu_mx[31:0]),
      .sfr_mx				(sfr_mx[31:0]),
      .mul_mx				(mul_mx[31:0]),
      .bsf_mx				(bsf_mx[31:0]),
      .gclk				(gclk),
      .grst				(grst),
      .dena				(dena),
      .gpha				(gpha));

endmodule // aeMB2_regs

// $Log: not supported by cvs2svn $