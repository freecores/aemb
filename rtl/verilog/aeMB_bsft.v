/* $Id: aeMB_bsft.v,v 1.4 2008-06-06 09:36:02 sybreon Exp $
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
/*
 * 2-CYCLE BARREL SHIFTER
 */

module aeMB_bsft (/*AUTOARG*/
   // Outputs
   m_bsf,
   // Inputs
   x_opa, x_opb, x_opc, x_imm, gclk, grst, dena, gpha
   );
   parameter BSF = 1; ///< implement barrel shift  

   output [31:0] m_bsf;   
   
   input [31:0]  x_opa;
   input [31:0]  x_opb;
   input [5:0] 	 x_opc;   
   input [10:9]  x_imm;
   
   // SYS signals
   input 	 gclk,
		 grst,
		 dena,
		 gpha;   

   /*AUTOREG*/
   
   reg [31:0] 	 rBSLL, rBSRL, rBSRA;   
   reg [31:0] 	 rBSR;
   reg [10:9] 	 imm_ex;
   
   wire [31:0] 	 wOPB = x_opb;
   wire [31:0] 	 wOPA = x_opa;

   // STAGE-1 SHIFTERS
   
   // logical
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBSLL <= 32'h0;
	rBSRL <= 32'h0;
	// End of automatics
     end else if (dena) begin
	rBSLL <= #1 wOPA << wOPB[4:0];
	rBSRL <= #1 wOPA >> wOPB[4:0];	
     end
   
   // arithmetic
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rBSRA <= 32'h0;
	// End of automatics
     end else if (dena)
       case (wOPB[4:0])
	 5'd00: rBSRA <= wOPA;
	 5'd01: rBSRA <= {{(1){wOPA[31]}}, wOPA[31:1]};
	 5'd02: rBSRA <= {{(2){wOPA[31]}}, wOPA[31:2]};
	 5'd03: rBSRA <= {{(3){wOPA[31]}}, wOPA[31:3]};
	 5'd04: rBSRA <= {{(4){wOPA[31]}}, wOPA[31:4]};
	 5'd05: rBSRA <= {{(5){wOPA[31]}}, wOPA[31:5]};
	 5'd06: rBSRA <= {{(6){wOPA[31]}}, wOPA[31:6]};
	 5'd07: rBSRA <= {{(7){wOPA[31]}}, wOPA[31:7]};
	 5'd08: rBSRA <= {{(8){wOPA[31]}}, wOPA[31:8]};
	 5'd09: rBSRA <= {{(9){wOPA[31]}}, wOPA[31:9]};
	 5'd10: rBSRA <= {{(10){wOPA[31]}}, wOPA[31:10]};
	 5'd11: rBSRA <= {{(11){wOPA[31]}}, wOPA[31:11]};
	 5'd12: rBSRA <= {{(12){wOPA[31]}}, wOPA[31:12]};
	 5'd13: rBSRA <= {{(13){wOPA[31]}}, wOPA[31:13]};
	 5'd14: rBSRA <= {{(14){wOPA[31]}}, wOPA[31:14]};
	 5'd15: rBSRA <= {{(15){wOPA[31]}}, wOPA[31:15]};
	 5'd16: rBSRA <= {{(16){wOPA[31]}}, wOPA[31:16]};
	 5'd17: rBSRA <= {{(17){wOPA[31]}}, wOPA[31:17]};
	 5'd18: rBSRA <= {{(18){wOPA[31]}}, wOPA[31:18]};
	 5'd19: rBSRA <= {{(19){wOPA[31]}}, wOPA[31:19]};
	 5'd20: rBSRA <= {{(20){wOPA[31]}}, wOPA[31:20]};
	 5'd21: rBSRA <= {{(21){wOPA[31]}}, wOPA[31:21]};
	 5'd22: rBSRA <= {{(22){wOPA[31]}}, wOPA[31:22]};
	 5'd23: rBSRA <= {{(23){wOPA[31]}}, wOPA[31:23]};
	 5'd24: rBSRA <= {{(24){wOPA[31]}}, wOPA[31:24]};
	 5'd25: rBSRA <= {{(25){wOPA[31]}}, wOPA[31:25]};
	 5'd26: rBSRA <= {{(26){wOPA[31]}}, wOPA[31:26]};
	 5'd27: rBSRA <= {{(27){wOPA[31]}}, wOPA[31:27]};
	 5'd28: rBSRA <= {{(28){wOPA[31]}}, wOPA[31:28]};
	 5'd29: rBSRA <= {{(29){wOPA[31]}}, wOPA[31:29]};
	 5'd30: rBSRA <= {{(30){wOPA[31]}}, wOPA[31:30]};
	 5'd31: rBSRA <= {{(31){wOPA[31]}}, wOPA[31]};
       endcase // case (wOPB[4:0])

   // STAGE-2 SHIFT
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	imm_ex <= 2'h0;
	rBSR <= 32'h0;
	// End of automatics
     end else if (dena) begin
	case (imm_ex)
	  2'o0: rBSR <= #1 rBSRL;
	  2'o1: rBSR <= #1 rBSRA;       
	  2'o2: rBSR <= #1 rBSLL;
	  default: rBSR <= #1 32'hX;       
	endcase // case (imm_ex)
	imm_ex <= #1 x_imm[10:9]; // delay 1 cycle	
     end

   assign 	 m_bsf = (BSF[0]) ? rBSR : 32'hX;   
         
endmodule // aeMB2_bsft

