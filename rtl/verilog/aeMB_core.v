//                              -*- Mode: Verilog -*-
// Filename        : aeMB_core.v
// Description     : Microblaze Compatible Core
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Fri Dec 29 16:15:18 2006
// Last Modified By: $Author: sybreon $
// Last Modified On: $Date: 2007-04-04 06:13:23 $
// Update Count    : $Revision: 1.2 $
// Status          : $State: Exp $

/*
 * $Id: aeMB_core.v,v 1.2 2007-04-04 06:13:23 sybreon Exp $
 * 
 * AEMB 32-bit Microblaze Compatible Core
 * Copyright (C) 2006 Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
 *  
 * This library is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU Lesser General Public License as published by 
 * the Free Software Foundation; either version 2.1 of the License, 
 * or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful, but 
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY 
 * or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public 
 * License for more details.
 * 
 * You should have received a copy of the GNU Lesser General Public License 
 * along with this library; if not, write to the Free Software Foundation, Inc.,
 * 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA 
 *
 * DESCRIPTION
 * Microblaze compatible, WISHBONE compliant hardware core. This core is
 * capable of executing software compile for EDK 2.1 using GCC. It has the
 * capability of handling interrupts as well as exceptions.
 *
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

module aeMB_core (/*AUTOARG*/
   // Outputs
   iwb_stb_o, iwb_adr_o, dwb_we_o, dwb_stb_o, dwb_dat_o, dwb_adr_o,
   // Inputs
   sys_run_i, sys_rst_i, sys_int_i, sys_exc_i, sys_clk_i, iwb_dat_i,
   iwb_ack_i, dwb_dat_i, dwb_ack_i
   );
   // Instruction WB address space
   parameter ISIZ = 32;
   // Data WB address space
   parameter DSIZ = 32; 

   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output [DSIZ-1:0]	dwb_adr_o;		// From aslu of aeMB_aslu.v
   output [31:0]	dwb_dat_o;		// From regfile of aeMB_regfile.v
   output		dwb_stb_o;		// From decode of aeMB_decode.v
   output		dwb_we_o;		// From decode of aeMB_decode.v
   output [ISIZ-1:0]	iwb_adr_o;		// From fetch of aeMB_fetch.v
   output		iwb_stb_o;		// From decode of aeMB_decode.v
   // End of automatics
   /*AUTOINPUT*/
   // Beginning of automatic inputs (from unused autoinst inputs)
   input		dwb_ack_i;		// To control of aeMB_control.v
   input [31:0]		dwb_dat_i;		// To regfile of aeMB_regfile.v, ...
   input		iwb_ack_i;		// To control of aeMB_control.v
   input [31:0]		iwb_dat_i;		// To fetch of aeMB_fetch.v, ...
   input		sys_clk_i;		// To control of aeMB_control.v
   input		sys_exc_i;		// To control of aeMB_control.v
   input		sys_int_i;		// To control of aeMB_control.v
   input		sys_rst_i;		// To control of aeMB_control.v
   input		sys_run_i;		// To control of aeMB_control.v
   // End of automatics
   /*AUTOWIRE*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   wire			drst;			// From control of aeMB_control.v
   wire			drun;			// From control of aeMB_control.v
   wire			frst;			// From control of aeMB_control.v
   wire			frun;			// From control of aeMB_control.v
   wire			nclk;			// From control of aeMB_control.v
   wire			nrst;			// From control of aeMB_control.v
   wire			rBRA;			// From decode of aeMB_decode.v
   wire			rDLY;			// From decode of aeMB_decode.v
   wire			rDWBSTB;		// From decode of aeMB_decode.v
   wire			rDWBWE;			// From decode of aeMB_decode.v
   wire [1:0]		rFSM;			// From control of aeMB_control.v
   wire [15:0]		rIMM;			// From decode of aeMB_decode.v
   wire			rIWBSTB;		// From decode of aeMB_decode.v
   wire			rLNK;			// From decode of aeMB_decode.v
   wire [1:0]		rMXALU;			// From decode of aeMB_decode.v
   wire [1:0]		rMXLDST;		// From decode of aeMB_decode.v
   wire [1:0]		rMXSRC;			// From decode of aeMB_decode.v
   wire [1:0]		rMXTGT;			// From decode of aeMB_decode.v
   wire [5:0]		rOPC;			// From decode of aeMB_decode.v
   wire [31:0]		rPC;			// From fetch of aeMB_fetch.v
   wire [31:0]		rPCNXT;			// From fetch of aeMB_fetch.v
   wire [4:0]		rRA;			// From decode of aeMB_decode.v
   wire [4:0]		rRB;			// From decode of aeMB_decode.v
   wire [4:0]		rRD;			// From decode of aeMB_decode.v
   wire [4:0]		rRD_;			// From decode of aeMB_decode.v
   wire [31:0]		rREGA;			// From regfile of aeMB_regfile.v
   wire [31:0]		rREGB;			// From regfile of aeMB_regfile.v
   wire [31:0]		rRESULT;		// From aslu of aeMB_aslu.v
   wire			rRWE;			// From decode of aeMB_decode.v
   wire [31:0]		rSIMM;			// From decode of aeMB_decode.v
   // End of automatics

   aeMB_regfile #(DSIZ)
     regfile (/*AUTOINST*/
	      // Outputs
	      .dwb_dat_o		(dwb_dat_o[31:0]),
	      .rREGA			(rREGA[31:0]),
	      .rREGB			(rREGB[31:0]),
	      // Inputs
	      .dwb_dat_i		(dwb_dat_i[31:0]),
	      .rDWBSTB			(rDWBSTB),
	      .rDWBWE			(rDWBWE),
	      .rRA			(rRA[4:0]),
	      .rRB			(rRB[4:0]),
	      .rRD			(rRD[4:0]),
	      .rRD_			(rRD_[4:0]),
	      .rRESULT			(rRESULT[31:0]),
	      .rFSM			(rFSM[1:0]),
	      .rPC			(rPC[31:0]),
	      .rPCNXT			(rPCNXT[31:0]),
	      .rLNK			(rLNK),
	      .rRWE			(rRWE),
	      .nclk			(nclk),
	      .nrst			(nrst),
	      .drun			(drun),
	      .drst			(drst));

   aeMB_fetch #(ISIZ)
     fetch (/*AUTOINST*/
	    // Outputs
	    .iwb_adr_o			(iwb_adr_o[ISIZ-1:0]),
	    .rPC			(rPC[31:0]),
	    .rPCNXT			(rPCNXT[31:0]),
	    // Inputs
	    .iwb_dat_i			(iwb_dat_i[31:0]),
	    .nclk			(nclk),
	    .nrst			(nrst),
	    .frun			(frun),
	    .rFSM			(rFSM[1:0]),
	    .rBRA			(rBRA),
	    .rRESULT			(rRESULT[31:0]));

   aeMB_control
     control (/*AUTOINST*/
	      // Outputs
	      .rFSM			(rFSM[1:0]),
	      .nclk			(nclk),
	      .nrst			(nrst),
	      .frun			(frun),
	      .drun			(drun),
	      .frst			(frst),
	      .drst			(drst),
	      // Inputs
	      .sys_rst_i		(sys_rst_i),
	      .sys_clk_i		(sys_clk_i),
	      .sys_int_i		(sys_int_i),
	      .sys_exc_i		(sys_exc_i),
	      .sys_run_i		(sys_run_i),
	      .rIWBSTB			(rIWBSTB),
	      .iwb_ack_i		(iwb_ack_i),
	      .rDWBSTB			(rDWBSTB),
	      .dwb_ack_i		(dwb_ack_i),
	      .rBRA			(rBRA),
	      .rDLY			(rDLY));

   aeMB_aslu #(DSIZ)
     aslu (/*AUTOINST*/
	   // Outputs
	   .dwb_adr_o			(dwb_adr_o[DSIZ-1:0]),
	   .rRESULT			(rRESULT[31:0]),
	   // Inputs
	   .dwb_dat_i			(dwb_dat_i[31:0]),
	   .rBRA			(rBRA),
	   .rDLY			(rDLY),
	   .rREGA			(rREGA[31:0]),
	   .rREGB			(rREGB[31:0]),
	   .rSIMM			(rSIMM[31:0]),
	   .rMXSRC			(rMXSRC[1:0]),
	   .rMXTGT			(rMXTGT[1:0]),
	   .rMXALU			(rMXALU[1:0]),
	   .rOPC			(rOPC[5:0]),
	   .rPC				(rPC[31:0]),
	   .rIMM			(rIMM[15:0]),
	   .rRD				(rRD[4:0]),
	   .rRA				(rRA[4:0]),
	   .rMXLDST			(rMXLDST[1:0]),
	   .nclk			(nclk),
	   .nrst			(nrst),
	   .drun			(drun),
	   .drst			(drst));
   

   aeMB_decode
     decode (/*AUTOINST*/
	     // Outputs
	     .rSIMM			(rSIMM[31:0]),
	     .rMXALU			(rMXALU[1:0]),
	     .rMXSRC			(rMXSRC[1:0]),
	     .rMXTGT			(rMXTGT[1:0]),
	     .rRA			(rRA[4:0]),
	     .rRB			(rRB[4:0]),
	     .rRD			(rRD[4:0]),
	     .rRD_			(rRD_[4:0]),
	     .rOPC			(rOPC[5:0]),
	     .rIMM			(rIMM[15:0]),
	     .rDWBSTB			(rDWBSTB),
	     .rDWBWE			(rDWBWE),
	     .rIWBSTB			(rIWBSTB),
	     .rDLY			(rDLY),
	     .rLNK			(rLNK),
	     .rBRA			(rBRA),
	     .rRWE			(rRWE),
	     .rMXLDST			(rMXLDST[1:0]),
	     .iwb_stb_o			(iwb_stb_o),
	     .dwb_stb_o			(dwb_stb_o),
	     .dwb_we_o			(dwb_we_o),
	     // Inputs
	     .rREGA			(rREGA[31:0]),
	     .rRESULT			(rRESULT[31:0]),
	     .iwb_dat_i			(iwb_dat_i[31:0]),
	     .dwb_dat_i			(dwb_dat_i[31:0]),
	     .nclk			(nclk),
	     .nrst			(nrst),
	     .drun			(drun),
	     .frun			(frun),
	     .frst			(frst),
	     .drst			(drst));

   
endmodule // aeMB_core
