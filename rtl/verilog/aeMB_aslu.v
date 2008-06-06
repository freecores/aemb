/* $Id: aeMB_aslu.v,v 1.13 2008-06-06 09:36:02 sybreon Exp $
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
 *      +---------+
 *      |         |
 * SRC =| INTEGER |
 *      | UNIT    |= RES
 * TGT =|         |
 *      |         |
 *      +---------+
 */

module aeMB_aslu (/*AUTOARG*/
   // Outputs
   x_add, x_alu, m_alu,
   // Inputs
   x_opa, x_opb, x_opc, x_imm, gclk, grst, gena
   );

   // results
   output [31:2] x_add;
   output [31:0] x_alu;
   output [31:0] m_alu;
   
   // source operands
   input [31:0]  x_opa,
		 x_opb;

   // instruction pipe
   input [5:0] 	 x_opc;
   input [7:0] 	 x_imm;   
   
   input 	 gclk,
		 grst,
		 gena;
   
   
   // Infer a ADD with carry cell because ADDSUB cannot be inferred
   // across technologies.
   
   reg [31:0] 		add_ex;
   reg 			add_c;
   
   wire [31:0] 		wADD;
   wire 		wADC;

   wire 		fCCC = !x_opc[5] & x_opc[1]; // & !x_opc[4]
   wire 		fSUB = !x_opc[5] & x_opc[0]; // & !x_opc[4]
   wire 		fCMP = !x_opc[3] & x_imm[1]; // unsigned only
   wire 		wCMP = (fCMP) ? !wADC : wADD[31]; // cmpu adjust
   
   wire [31:0] 		wOPA = (fSUB) ? ~x_opa : x_opa;
   wire 		wOPC = (fCCC) ? rMSR_CC : fSUB;
   
   assign 		{wADC, wADD} = (x_opb + wOPA) + wOPC; // add carry
   
   always @(/*AUTOSENSE*/wADC or wADD or wCMP) begin
      {add_c, add_ex} <= #1 {wADC, wCMP, wADD[30:0]}; // add with carry
   end
      
   // SHIFT/LOGIC/MOVE
   reg [31:0] 		slm_ex;

   always @(/*AUTOSENSE*/rMSR_CC or x_imm or x_opa or x_opb or x_opc)
     case (x_opc[2:0])
       // LOGIC
       3'o0: slm_ex <= #1 x_opa | x_opb;
       3'o1: slm_ex <= #1 x_opa & x_opb;
       3'o2: slm_ex <= #1 x_opa ^ x_opb;
       3'o3: slm_ex <= #1 x_opa & ~x_opb;
       // SHIFT/SEXT
       3'o4: case ({x_imm[6:5],x_imm[0]})
	       3'o1: slm_ex <= #1 {x_opa[31],x_opa[31:1]}; // SRA
	       3'o3: slm_ex <= #1 {rMSR_CC,x_opa[31:1]}; // SRC
	       3'o5: slm_ex <= #1 {1'b0,x_opa[31:1]}; // SRL
	       3'o6: slm_ex <= #1 {{(24){x_opa[7]}}, x_opa[7:0]}; // SEXT8
	       3'o7: slm_ex <= #1  {{(16){x_opa[15]}}, x_opa[15:0]}; // SEXT16
	       default: slm_ex <= #1 32'hX;
	     endcase // case ({x_imm[6:5],x_imm[0]})
       // MFS/MTS/MSET/MCLR
       //3'o5: slm_ex <= #1 sfr_of;       
       // BRL (PC from SFR)
       //3'o6: slm_ex <= #1 sfr_of;
       default: slm_ex <= #1 32'hX;       
     endcase // case (x_opc[2:0])
   
   
   
endmodule // aeMB_aslu
