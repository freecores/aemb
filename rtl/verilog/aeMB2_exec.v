/* $Id: aeMB2_exec.v,v 1.3 2008-04-26 01:11:30 sybreon Exp $
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
 * Execution Units Wrapper
 * @file aeMB2_exec.v

 * Collection of all the execution units.
 
 */

module aeMB2_exec (/*AUTOARG*/
   // Outputs
   sfr_mx, mul_mx, msr_ex, mem_ex, bsf_mx, bpc_ex, alu_mx, alu_ex,
   // Inputs
   rd_of, ra_of, opd_of, opc_of, opb_of, opa_of, imm_of, grst, gpha,
   gclk, dena
   );
   parameter AEMB_IWB = 32;
   parameter AEMB_DWB = 32;
   parameter AEMB_MUL = 1;
   parameter AEMB_BSF = 1;   
   parameter AEMB_HTX = 1;   
   
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	alu_ex;			// From intu0 of aeMB2_intu.v
   output [31:0]	alu_mx;			// From intu0 of aeMB2_intu.v
   output [31:2]	bpc_ex;			// From intu0 of aeMB2_intu.v
   output [31:0]	bsf_mx;			// From bsft0 of aeMB2_bsft.v
   output [31:2]	mem_ex;			// From intu0 of aeMB2_intu.v
   output [7:0]		msr_ex;			// From intu0 of aeMB2_intu.v
   output [31:0]	mul_mx;			// From mult0 of aeMB2_mult.v
   output [31:0]	sfr_mx;			// From intu0 of aeMB2_intu.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		dena;			// To bsft0 of aeMB2_bsft.v, ...
   input		gclk;			// To bsft0 of aeMB2_bsft.v, ...
   input		gpha;			// To bsft0 of aeMB2_bsft.v, ...
   input		grst;			// To bsft0 of aeMB2_bsft.v, ...
   input [15:0]		imm_of;			// To bsft0 of aeMB2_bsft.v, ...
   input [31:0]		opa_of;			// To bsft0 of aeMB2_bsft.v, ...
   input [31:0]		opb_of;			// To bsft0 of aeMB2_bsft.v, ...
   input [5:0]		opc_of;			// To bsft0 of aeMB2_bsft.v, ...
   input [31:0]		opd_of;			// To intu0 of aeMB2_intu.v
   input [4:0]		ra_of;			// To intu0 of aeMB2_intu.v
   input [4:0]		rd_of;			// To intu0 of aeMB2_intu.v
   // End of automatics
   /*AUTOWIRE*/

   aeMB2_bsft
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AEMB_BSF			(AEMB_BSF))
   bsft0
     (/*AUTOINST*/
      // Outputs
      .bsf_mx				(bsf_mx[31:0]),
      // Inputs
      .opa_of				(opa_of[31:0]),
      .opb_of				(opb_of[31:0]),
      .opc_of				(opc_of[5:0]),
      .imm_of				(imm_of[10:9]),
      .gclk				(gclk),
      .grst				(grst),
      .dena				(dena),
      .gpha				(gpha));   
   
   aeMB2_mult
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AEMB_MUL			(AEMB_MUL))
   mult0
     (/*AUTOINST*/
      // Outputs
      .mul_mx				(mul_mx[31:0]),
      // Inputs
      .opa_of				(opa_of[31:0]),
      .opb_of				(opb_of[31:0]),
      .opc_of				(opc_of[5:0]),
      .gclk				(gclk),
      .grst				(grst),
      .dena				(dena),
      .gpha				(gpha));   

   aeMB2_intu
     #(/*AUTOINSTPARAM*/
       // Parameters
       .AEMB_DWB			(AEMB_DWB),
       .AEMB_IWB			(AEMB_IWB),
       .AEMB_HTX			(AEMB_HTX))
   intu0
     (/*AUTOINST*/
      // Outputs
      .mem_ex				(mem_ex[31:2]),
      .bpc_ex				(bpc_ex[31:2]),
      .alu_ex				(alu_ex[31:0]),
      .alu_mx				(alu_mx[31:0]),
      .msr_ex				(msr_ex[7:0]),
      .sfr_mx				(sfr_mx[31:0]),
      // Inputs
      .opc_of				(opc_of[5:0]),
      .opa_of				(opa_of[31:0]),
      .opb_of				(opb_of[31:0]),
      .opd_of				(opd_of[31:0]),
      .imm_of				(imm_of[15:0]),
      .rd_of				(rd_of[4:0]),
      .ra_of				(ra_of[4:0]),
      .gclk				(gclk),
      .grst				(grst),
      .dena				(dena),
      .gpha				(gpha));   
   
endmodule // aeMB2_exec

/*
 $Log: not supported by cvs2svn $
 Revision 1.2  2008/04/26 01:09:06  sybreon
 Passes basic tests. Minor documentation changes to make it compatible with iverilog pre-processor.

 Revision 1.1  2008/04/18 00:21:52  sybreon
 Initial import.
*/