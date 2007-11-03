// $Id: aeMB_edk32.v,v 1.3 2007-11-03 08:34:55 sybreon Exp $
//
// AEMB EDK 3.2 Compatible Core
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
// Revision 1.2  2007/11/02 19:20:58  sybreon
// Added better (beta) interrupt support.
// Changed MSR_IE to disabled at reset as per MB docs.
//
// Revision 1.1  2007/11/02 03:25:40  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module aeMB_edk32 (/*AUTOARG*/
   // Outputs
   iwb_stb_o, iwb_adr_o, dwb_wre_o, dwb_stb_o, dwb_sel_o, dwb_dat_o,
   dwb_adr_o,
   // Inputs
   sys_rst_i, sys_int_i, sys_clk_i, iwb_dat_i, iwb_ack_i, dwb_dat_i,
   dwb_ack_i
   );

   parameter IW = 32;
   parameter DW = 32;
   
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [DW-1:2]	dwb_adr_o;		// From xecu of aeMB_xecu.v
   output [31:0]	dwb_dat_o;		// From regf of aeMB_regf.v
   output [3:0]		dwb_sel_o;		// From xecu of aeMB_xecu.v
   output		dwb_stb_o;		// From ctrl of aeMB_ctrl.v
   output		dwb_wre_o;		// From ctrl of aeMB_ctrl.v
   output [IW-1:2]	iwb_adr_o;		// From bpcu of aeMB_bpcu.v
   output		iwb_stb_o;		// From ibuf of aeMB_ibuf.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		dwb_ack_i;		// To scon of aeMB_scon.v
   input [31:0]		dwb_dat_i;		// To regf of aeMB_regf.v
   input		iwb_ack_i;		// To scon of aeMB_scon.v, ...
   input [31:0]		iwb_dat_i;		// To ibuf of aeMB_ibuf.v
   input		sys_clk_i;		// To scon of aeMB_scon.v
   input		sys_int_i;		// To scon of aeMB_scon.v
   input		sys_rst_i;		// To scon of aeMB_scon.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			gclk;			// From scon of aeMB_scon.v
   wire			gena;			// From scon of aeMB_scon.v
   wire			grst;			// From scon of aeMB_scon.v
   wire [10:0]		rALT;			// From ibuf of aeMB_ibuf.v
   wire [1:0]		rATOM;			// From bpcu of aeMB_bpcu.v
   wire			rBRA;			// From bpcu of aeMB_bpcu.v
   wire			rDLY;			// From bpcu of aeMB_bpcu.v
   wire [31:0]		rDWBDI;			// From regf of aeMB_regf.v
   wire [3:0]		rDWBSEL;		// From xecu of aeMB_xecu.v
   wire			rDWBSTB;		// From ctrl of aeMB_ctrl.v
   wire [15:0]		rIMM;			// From ibuf of aeMB_ibuf.v
   wire			rMSR_BIP;		// From xecu of aeMB_xecu.v
   wire			rMSR_IE;		// From xecu of aeMB_xecu.v
   wire [1:0]		rMXALT;			// From ctrl of aeMB_ctrl.v
   wire [2:0]		rMXALU;			// From ctrl of aeMB_ctrl.v
   wire [1:0]		rMXDST;			// From ctrl of aeMB_ctrl.v
   wire [1:0]		rMXSRC;			// From ctrl of aeMB_ctrl.v
   wire [1:0]		rMXTGT;			// From ctrl of aeMB_ctrl.v
   wire [5:0]		rOPC;			// From ibuf of aeMB_ibuf.v
   wire [31:2]		rPC;			// From bpcu of aeMB_bpcu.v
   wire [31:2]		rPCLNK;			// From bpcu of aeMB_bpcu.v
   wire [4:0]		rRA;			// From ibuf of aeMB_ibuf.v
   wire [4:0]		rRB;			// From ibuf of aeMB_ibuf.v
   wire [4:0]		rRD;			// From ibuf of aeMB_ibuf.v
   wire [31:0]		rREGA;			// From regf of aeMB_regf.v
   wire [31:0]		rREGB;			// From regf of aeMB_regf.v
   wire [31:0]		rRESULT;		// From xecu of aeMB_xecu.v
   wire [4:0]		rRW;			// From ctrl of aeMB_ctrl.v
   wire [31:0]		rSIMM;			// From ibuf of aeMB_ibuf.v
   wire [1:0]		rXCE;			// From scon of aeMB_scon.v
   // End of automatics
   
   wire [31:0] 		rOPA, rOPB;   
   wire [31:0] 		rRES_MUL, rRES_BSF;

   // --- OPTIONAL COMPONENTS -----------------------------------
   // Trade off hardware size/speed for software speed
   
   aeMB_mult
     mult (
	   // Outputs
	   .rRES_MUL			(rRES_MUL[31:0]),
	   // Inputs
	   .rOPA			(rOPA[31:0]),
	   .rOPB			(rOPB[31:0]));   
     
   aeMB_bsft
     bsft (
	   // Outputs
	   .rRES_BSF			(rRES_BSF[31:0]),
	   // Inputs
	   .rOPA			(rOPA[31:0]),
	   .rOPB			(rOPB[31:0]),
	   .rALT			(rALT[10:0]));
   
       
   // --- NON-OPTIONAL COMPONENTS -------------------------------
   // These components make up the main AEMB processor.
   
   aeMB_scon
     scon (/*AUTOINST*/
	   // Outputs
	   .rXCE			(rXCE[1:0]),
	   .grst			(grst),
	   .gclk			(gclk),
	   .gena			(gena),
	   // Inputs
	   .rOPC			(rOPC[5:0]),
	   .rATOM			(rATOM[1:0]),
	   .rDWBSTB			(rDWBSTB),
	   .dwb_ack_i			(dwb_ack_i),
	   .iwb_ack_i			(iwb_ack_i),
	   .rMSR_IE			(rMSR_IE),
	   .rMSR_BIP			(rMSR_BIP),
	   .rBRA			(rBRA),
	   .rDLY			(rDLY),
	   .sys_clk_i			(sys_clk_i),
	   .sys_rst_i			(sys_rst_i),
	   .sys_int_i			(sys_int_i));   

   aeMB_ibuf
     ibuf (/*AUTOINST*/
	   // Outputs
	   .rIMM			(rIMM[15:0]),
	   .rRA				(rRA[4:0]),
	   .rRD				(rRD[4:0]),
	   .rRB				(rRB[4:0]),
	   .rALT			(rALT[10:0]),
	   .rOPC			(rOPC[5:0]),
	   .rSIMM			(rSIMM[31:0]),
	   .iwb_stb_o			(iwb_stb_o),
	   // Inputs
	   .rBRA			(rBRA),
	   .rXCE			(rXCE[1:0]),
	   .iwb_dat_i			(iwb_dat_i[31:0]),
	   .iwb_ack_i			(iwb_ack_i),
	   .gclk			(gclk),
	   .grst			(grst),
	   .gena			(gena));   
   
   aeMB_ctrl
     ctrl (/*AUTOINST*/
	   // Outputs
	   .rMXDST			(rMXDST[1:0]),
	   .rMXSRC			(rMXSRC[1:0]),
	   .rMXTGT			(rMXTGT[1:0]),
	   .rMXALT			(rMXALT[1:0]),
	   .rMXALU			(rMXALU[2:0]),
	   .rRW				(rRW[4:0]),
	   .rDWBSTB			(rDWBSTB),
	   .dwb_stb_o			(dwb_stb_o),
	   .dwb_wre_o			(dwb_wre_o),
	   // Inputs
	   .rXCE			(rXCE[1:0]),
	   .rDLY			(rDLY),
	   .rIMM			(rIMM[15:0]),
	   .rALT			(rALT[10:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rRA				(rRA[4:0]),
	   .rRB				(rRB[4:0]),
	   .rPC				(rPC[31:2]),
	   .rBRA			(rBRA),
	   .rMSR_IE			(rMSR_IE),
	   .gclk			(gclk),
	   .grst			(grst),
	   .gena			(gena));

   aeMB_bpcu #(IW)
     bpcu (/*AUTOINST*/
	   // Outputs
	   .iwb_adr_o			(iwb_adr_o[IW-1:2]),
	   .rPC				(rPC[31:2]),
	   .rPCLNK			(rPCLNK[31:2]),
	   .rBRA			(rBRA),
	   .rDLY			(rDLY),
	   .rATOM			(rATOM[1:0]),
	   // Inputs
	   .rMXALT			(rMXALT[1:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rRA				(rRA[4:0]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .rREGA			(rREGA[31:0]),
	   .rXCE			(rXCE[1:0]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .gena			(gena));

   aeMB_regf
     regf (/*AUTOINST*/
	   // Outputs
	   .rREGA			(rREGA[31:0]),
	   .rREGB			(rREGB[31:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .dwb_dat_o			(dwb_dat_o[31:0]),
	   // Inputs
	   .rOPC			(rOPC[5:0]),
	   .rRA				(rRA[4:0]),
	   .rRB				(rRB[4:0]),
	   .rRW				(rRW[4:0]),
	   .rRD				(rRD[4:0]),
	   .rMXDST			(rMXDST[1:0]),
	   .rPCLNK			(rPCLNK[31:2]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .rBRA			(rBRA),
	   .rDLY			(rDLY),
	   .dwb_dat_i			(dwb_dat_i[31:0]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .gena			(gena));   

   aeMB_xecu #(DW)
     xecu (
	   .rOPA			(rOPA[31:0]),
	   .rOPB			(rOPB[31:0]),
	   /*AUTOINST*/
	   // Outputs
	   .dwb_adr_o			(dwb_adr_o[DW-1:2]),
	   .dwb_sel_o			(dwb_sel_o[3:0]),
	   .rRESULT			(rRESULT[31:0]),
	   .rDWBSEL			(rDWBSEL[3:0]),
	   .rMSR_IE			(rMSR_IE),
	   .rMSR_BIP			(rMSR_BIP),
	   // Inputs
	   .rXCE			(rXCE[1:0]),
	   .rREGA			(rREGA[31:0]),
	   .rREGB			(rREGB[31:0]),
	   .rMXSRC			(rMXSRC[1:0]),
	   .rMXTGT			(rMXTGT[1:0]),
	   .rRA				(rRA[4:0]),
	   .rMXALU			(rMXALU[2:0]),
	   .rBRA			(rBRA),
	   .rDLY			(rDLY),
	   .rSIMM			(rSIMM[31:0]),
	   .rIMM			(rIMM[15:0]),
	   .rOPC			(rOPC[5:0]),
	   .rRD				(rRD[4:0]),
	   .rDWBDI			(rDWBDI[31:0]),
	   .rPC				(rPC[31:2]),
	   .rRES_MUL			(rRES_MUL[31:0]),
	   .rRES_BSF			(rRES_BSF[31:0]),
	   .gclk			(gclk),
	   .grst			(grst),
	   .gena			(gena));

      
endmodule // aeMB_edk32