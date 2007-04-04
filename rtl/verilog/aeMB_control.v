//                              -*- Mode: Verilog -*-
// Filename        : aeMB_control.v
// Description     : AEMB MCU Control Unit
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Fri Dec 29 18:21:27 2006
// Last Modified By: $Author: sybreon $
// Last Modified On: $Date: 2007-04-04 14:08:34 $
// Update Count    : $Revision: 1.2 $
// Status          : $State: Exp $

/*
 * $Id: aeMB_control.v,v 1.2 2007-04-04 14:08:34 sybreon Exp $
 * 
 * AE68 System Control Unit
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
 * Controls the state of the processor.
 * 
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

module aeMB_control (/*AUTOARG*/
   // Outputs
   rFSM, nclk, nrst, frun, drun, frst, drst,
   // Inputs
   sys_rst_i, sys_clk_i, sys_int_i, sys_exc_i, sys_run_i, rIWBSTB,
   iwb_ack_i, rDWBSTB, dwb_ack_i, rBRA, rDLY
   );
   // System
   input 	sys_rst_i, sys_clk_i;
   input 	sys_int_i;
   input 	sys_exc_i;   
   input 	sys_run_i;
   
   // Instruction WB
   input 	rIWBSTB;
   input 	iwb_ack_i;

   // Data WB
   input 	rDWBSTB;
   input 	dwb_ack_i;   

   // Internal
   input 	rBRA, rDLY;   
   output [1:0] rFSM;
   //, rLDST;
   output 	nclk, nrst;   
   output 	frun, drun;
   output 	frst, drst;
      
   // Clock code here
   assign 	nclk = sys_clk_i;

   // Debounce reset
   reg [1:0] 	rRST;
   assign 	nrst = rRST[1];
   always @(posedge nclk or negedge sys_rst_i)     
     if (!sys_rst_i) begin
	//rNRST <= 2'h3;	
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rRST <= 2'h0;
	// End of automatics
     end else begin
	rRST <= {rRST[0],sys_rst_i};
     end

   // Quiet RUN signal
   wire 	qrun = ~((rDWBSTB ^ dwb_ack_i) | ((rIWBSTB ^ iwb_ack_i)));

   // Debounce Interrupt/Exception Signals
   reg [2:0] rEXC, rINT;
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rEXC <= 3'h0;
	rINT <= 3'h0;
	// End of automatics
     end else begin
	rEXC <= #1 {rEXC[1:0], sys_exc_i};
	rINT <= #1 {rINT[1:0], sys_int_i};	
     end
   
   // Machine States
   parameter [1:0]
		FSM_RUN = 2'o0,
		FSM_SWEXC = 2'o3,
		FSM_HWEXC = 2'o2,
		FSM_HWINT = 2'o1;
   
   reg [1:0] 	  rFSM, rNXT;
   always @(negedge nclk or negedge nrst)
     if (!nrst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rFSM <= 2'h0;
	// End of automatics
     end else begin
	rFSM <= #1 rNXT;
     end

   always @(/*AUTOSENSE*/rEXC or rFSM or rINT)
     case (rFSM)
       FSM_HWEXC: rNXT <= FSM_RUN;       
       //FSM_SWEXC: rNXT <= FSM_RUN;     
       FSM_HWINT: rNXT <= FSM_RUN;      
       default: begin
	  rNXT <= (rEXC == 3'h3) ? FSM_HWEXC :
		  (rINT == 3'h3) ? FSM_HWINT :
		  FSM_RUN;	  
       end
     endcase // case(rFSM)
      
   // Pause/Bubble
   reg [1:0]    rRUN;   
   assign 	{drun,frun} = rRUN;
   assign 	drst = nrst;
   assign 	frst = nrst;   
   
   always @(posedge nclk or negedge nrst)
     if (!nrst) begin
	rRUN <= 2'h3;	
	/*AUTORESET*/
     end else begin
	rRUN <= #1 {~(rBRA ^ rDLY), ~rBRA};	
     end
   
endmodule // aeMB_control
