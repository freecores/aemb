// $Id: aeMB_bsft.v,v 1.2 2007-11-03 08:34:54 sybreon Exp $
//
// AEMB SINGLE CYCLE 32'BIT BARREL SHIFTER
//
// Copyright (C) 2004-2007 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
//  
// This library is free software; you can redistribute it and/or
// modify it under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation; either version 2.1 of
// the License, or (at your option) any later version.
//
// This library is distributed in the hope that it will be useful, but
// WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
// Lesser General Public License for more details.
//  
// You should have received a copy of the GNU Lesser General Public
// License along with this library; if not, write to the Free Software
// Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
// USA
//
// $Log: not supported by cvs2svn $

module aeMB_bsft (/*AUTOARG*/
   // Outputs
   rRES_BSF,
   // Inputs
   rOPA, rOPB, rALT
   );

   output [31:0] rRES_BSF;
   input [31:0]  rOPA, rOPB;
   input [10:0]  rALT;

   reg [31:0] 	 rRES_BSF;
   reg [31:0] 	 xBSRL, xBSRA, xBSLL;
   
   // --- LOGICAL LEFT ----------------------------------------------
   // Infer a logical left barrel shifter.
   
   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSLL <= rOPA << rOPB[4:0];
   
   // --- LOGICAL RIGHT ---------------------------------------------
   // Infer a logical right barrel shifter.

   always @(/*AUTOSENSE*/rOPA or rOPB)
     xBSRL <= rOPA >> rOPB[4:0];

   // --- ARITHMETIC RIGH -------------------------------------------
   // Infer a arithmetic right barrel shifter.
   
   always @(/*AUTOSENSE*/rOPA or rOPB)
     case (rOPB[4:0])
       5'd00: xBSRA <= rOPA;
       5'd01: xBSRA <= {{(1){rOPA[31]}}, rOPA[31:1]};
       5'd02: xBSRA <= {{(2){rOPA[31]}}, rOPA[31:2]};
       5'd03: xBSRA <= {{(3){rOPA[31]}}, rOPA[31:3]};
       5'd04: xBSRA <= {{(4){rOPA[31]}}, rOPA[31:4]};
       5'd05: xBSRA <= {{(5){rOPA[31]}}, rOPA[31:5]};
       5'd06: xBSRA <= {{(6){rOPA[31]}}, rOPA[31:6]};
       5'd07: xBSRA <= {{(7){rOPA[31]}}, rOPA[31:7]};
       5'd08: xBSRA <= {{(8){rOPA[31]}}, rOPA[31:8]};
       5'd09: xBSRA <= {{(9){rOPA[31]}}, rOPA[31:9]};
       5'd10: xBSRA <= {{(10){rOPA[31]}}, rOPA[31:10]};
       5'd11: xBSRA <= {{(11){rOPA[31]}}, rOPA[31:11]};
       5'd12: xBSRA <= {{(12){rOPA[31]}}, rOPA[31:12]};
       5'd13: xBSRA <= {{(13){rOPA[31]}}, rOPA[31:13]};
       5'd14: xBSRA <= {{(14){rOPA[31]}}, rOPA[31:14]};
       5'd15: xBSRA <= {{(15){rOPA[31]}}, rOPA[31:15]};
       5'd16: xBSRA <= {{(16){rOPA[31]}}, rOPA[31:16]};
       5'd17: xBSRA <= {{(17){rOPA[31]}}, rOPA[31:17]};
       5'd18: xBSRA <= {{(18){rOPA[31]}}, rOPA[31:18]};
       5'd19: xBSRA <= {{(19){rOPA[31]}}, rOPA[31:19]};
       5'd20: xBSRA <= {{(20){rOPA[31]}}, rOPA[31:20]};
       5'd21: xBSRA <= {{(21){rOPA[31]}}, rOPA[31:21]};
       5'd22: xBSRA <= {{(22){rOPA[31]}}, rOPA[31:22]};
       5'd23: xBSRA <= {{(23){rOPA[31]}}, rOPA[31:23]};
       5'd24: xBSRA <= {{(24){rOPA[31]}}, rOPA[31:24]};
       5'd25: xBSRA <= {{(25){rOPA[31]}}, rOPA[31:25]};
       5'd26: xBSRA <= {{(26){rOPA[31]}}, rOPA[31:26]};
       5'd27: xBSRA <= {{(27){rOPA[31]}}, rOPA[31:27]};
       5'd28: xBSRA <= {{(28){rOPA[31]}}, rOPA[31:28]};
       5'd29: xBSRA <= {{(29){rOPA[31]}}, rOPA[31:29]};
       5'd30: xBSRA <= {{(30){rOPA[31]}}, rOPA[31:30]};
       5'd31: xBSRA <= {{(31){rOPA[31]}}, rOPA[31]};
     endcase // case (rOPB[4:0])

   always @(/*AUTOSENSE*/rALT or xBSLL or xBSRA or xBSRL)
     case (rALT[10:9])
       2'd0: rRES_BSF <= xBSRL;
       2'd1: rRES_BSF <= xBSRA;       
       2'd2: rRES_BSF <= xBSLL;
       default: rRES_BSF <= 32'hX;       
     endcase // case (rALT[10:9])
   
   
endmodule // aeMB_bsft
