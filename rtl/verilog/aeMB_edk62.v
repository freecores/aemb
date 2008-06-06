/* $Id: aeMB_edk62.v,v 1.1 2008-06-06 09:36:02 sybreon Exp $
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
 */

module aeMB_edk62 (/*AUTOARG*/
   // Outputs
   z_dwb, x_alu, dwb_wre_o, dwb_tag_o, dwb_stb_o, dwb_sel_o,
   dwb_dat_o, dwb_cyc_o, dwb_adr_o, d_dd, d_db, d_da,
   // Inputs
   x_opd, x_opc, x_opb, x_opa, x_imm, w_wre, w_sel, w_rw, r_msr,
   m_xwb, grst, gpha, gena, gclk, dwb_dat_i, dwb_ack_i, dena, d_rd,
   d_rb, d_ra
   );
   parameter DWB = 32; ///< data memory space
    
   parameter MUL = 1; ///< implement hardware multiplier   
   parameter BSF = 1; ///< implement barrel shifter
      
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [31:0]	d_da;			// From regs32 of aeMB_gprf.v
   output [31:0]	d_db;			// From regs32 of aeMB_gprf.v
   output [31:0]	d_dd;			// From regs32 of aeMB_gprf.v
   output [DWB-1:2]	dwb_adr_o;		// From dwb32 of aeMB_dwbif.v
   output		dwb_cyc_o;		// From dwb32 of aeMB_dwbif.v
   output [31:0]	dwb_dat_o;		// From dwb32 of aeMB_dwbif.v
   output [3:0]		dwb_sel_o;		// From dwb32 of aeMB_dwbif.v
   output		dwb_stb_o;		// From dwb32 of aeMB_dwbif.v
   output		dwb_tag_o;		// From dwb32 of aeMB_dwbif.v
   output		dwb_wre_o;		// From dwb32 of aeMB_dwbif.v
   output [31:0]	x_alu;			// From integer32 of aeMB_aslu.v
   output		z_dwb;			// From dwb32 of aeMB_dwbif.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input [4:0]		d_ra;			// To regs32 of aeMB_gprf.v
   input [4:0]		d_rb;			// To regs32 of aeMB_gprf.v
   input [4:0]		d_rd;			// To regs32 of aeMB_gprf.v
   input		dena;			// To barrel32 of aeMB_bsft.v
   input		dwb_ack_i;		// To dwb32 of aeMB_dwbif.v
   input [31:0]		dwb_dat_i;		// To dwb32 of aeMB_dwbif.v
   input		gclk;			// To regs32 of aeMB_gprf.v, ...
   input		gena;			// To regs32 of aeMB_gprf.v, ...
   input		gpha;			// To barrel32 of aeMB_bsft.v, ...
   input		grst;			// To regs32 of aeMB_gprf.v, ...
   input [31:0]		m_xwb;			// To regs32 of aeMB_gprf.v
   input [7:0]		r_msr;			// To dwb32 of aeMB_dwbif.v
   input [4:0]		w_rw;			// To regs32 of aeMB_gprf.v
   input [2:0]		w_sel;			// To regs32 of aeMB_gprf.v
   input		w_wre;			// To regs32 of aeMB_gprf.v
   input [10:0]		x_imm;			// To integer32 of aeMB_aslu.v, ...
   input [31:0]		x_opa;			// To integer32 of aeMB_aslu.v, ...
   input [31:0]		x_opb;			// To integer32 of aeMB_aslu.v, ...
   input [5:0]		x_opc;			// To integer32 of aeMB_aslu.v, ...
   input [31:0]		x_opd;			// To dwb32 of aeMB_dwbif.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire [31:0]		m_alu;			// From integer32 of aeMB_aslu.v
   wire [31:0]		m_bsf;			// From barrel32 of aeMB_bsft.v
   wire [31:0]		m_dwb;			// From dwb32 of aeMB_dwbif.v
   wire [31:0]		m_mul;			// From mult16x16 of aeMB_mult.v
   wire [3:0]		m_sel;			// From dwb32 of aeMB_dwbif.v
   wire [31:2]		x_add;			// From integer32 of aeMB_aslu.v
   // End of automatics
   /*AUTOREG*/

   // ### STORAGE UNITS ###

   /* aeMB_gprf AUTO_TEMPLATE (
    
    ) */

   aeMB_gprf
     #(/*AUTOINSTPARAM*/)
   regs32
     (/*AUTOINST*/
      // Outputs
      .d_da				(d_da[31:0]),
      .d_db				(d_db[31:0]),
      .d_dd				(d_dd[31:0]),
      // Inputs
      .d_ra				(d_ra[4:0]),
      .d_rb				(d_rb[4:0]),
      .d_rd				(d_rd[4:0]),
      .w_rw				(w_rw[4:0]),
      .w_sel				(w_sel[2:0]),
      .w_wre				(w_wre),
      .m_sel				(m_sel[3:0]),
      .m_dwb				(m_dwb[31:0]),
      .m_xwb				(m_xwb[31:0]),
      .m_bsf				(m_bsf[31:0]),
      .m_mul				(m_mul[31:0]),
      .m_alu				(m_alu[31:0]),
      .gclk				(gclk),
      .grst				(grst),
      .gena				(gena));

   // ### EXECUTION UNITS ###
   
   aeMB_aslu
     #(/*AUTOINSTPARAM*/)
   integer32
     (/*AUTOINST*/
      // Outputs
      .x_add				(x_add[31:2]),
      .x_alu				(x_alu[31:0]),
      .m_alu				(m_alu[31:0]),
      // Inputs
      .x_opa				(x_opa[31:0]),
      .x_opb				(x_opb[31:0]),
      .x_opc				(x_opc[5:0]),
      .x_imm				(x_imm[7:0]),
      .gclk				(gclk),
      .grst				(grst),
      .gena				(gena));
   
   aeMB_mult
     #(/*AUTOINSTPARAM*/
       // Parameters
       .MUL				(MUL))
   mult16x16
     (/*AUTOINST*/
      // Outputs
      .m_mul				(m_mul[31:0]),
      // Inputs
      .x_opa				(x_opa[31:0]),
      .x_opb				(x_opb[31:0]),
      .x_opc				(x_opc[5:0]),
      .gclk				(gclk),
      .grst				(grst),
      .gena				(gena));

   aeMB_bsft
     #(/*AUTOINSTPARAM*/
       // Parameters
       .BSF				(BSF))
   barrel32
     (/*AUTOINST*/
      // Outputs
      .m_bsf				(m_bsf[31:0]),
      // Inputs
      .x_opa				(x_opa[31:0]),
      .x_opb				(x_opb[31:0]),
      .x_opc				(x_opc[5:0]),
      .x_imm				(x_imm[10:9]),
      .gclk				(gclk),
      .grst				(grst),
      .dena				(dena),
      .gpha				(gpha));

   // ### MEMORY INTERFACES ###

   aeMB_dwbif
     #(/*AUTOINSTPARAM*/
       // Parameters
       .DWB				(DWB))
   dwb32
     (/*AUTOINST*/
      // Outputs
      .dwb_adr_o			(dwb_adr_o[DWB-1:2]),
      .dwb_sel_o			(dwb_sel_o[3:0]),
      .dwb_stb_o			(dwb_stb_o),
      .dwb_cyc_o			(dwb_cyc_o),
      .dwb_tag_o			(dwb_tag_o),
      .dwb_wre_o			(dwb_wre_o),
      .dwb_dat_o			(dwb_dat_o[31:0]),
      .z_dwb				(z_dwb),
      .m_sel				(m_sel[3:0]),
      .m_dwb				(m_dwb[31:0]),
      // Inputs
      .dwb_dat_i			(dwb_dat_i[31:0]),
      .dwb_ack_i			(dwb_ack_i),
      .x_opd				(x_opd[31:0]),
      .x_opc				(x_opc[5:0]),
      .x_opa				(x_opa[1:0]),
      .x_opb				(x_opb[1:0]),
      .r_msr				(r_msr[7:0]),
      .x_add				(x_add[DWB-1:2]),
      .gclk				(gclk),
      .grst				(grst),
      .gena				(gena),
      .gpha				(gpha));
   
   
endmodule // aeMB_edk62
