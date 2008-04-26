/* $Id: aeMB2_sfrf.v,v 1.2 2008-04-26 17:57:43 sybreon Exp $
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
 * Special Function Register File
 * @file aeMB2_sfrf.v

 This provides the special function registers;
 
 */

module aeMB2_sfrf (/*AUTOARG*/
   // Inputs
   rpc_if, alu_c, opc_of, imm_of, ra_of, rd_of, opa_of, ich_dat, gclk,
   grst, gpha, dena
   );
   parameter AEMB_HTX = 1;

   //output [31:0] sfr_mx; // MTS/MCLR/MSET use
	       //output [13:0] msr_of; // perpetual MSR 

   input [31:2]  rpc_if;

   input 	 alu_c;   
   input [5:0] 	 opc_of; // for MFS/MTS
   input [15:0]  imm_of; // for ALL
   input [4:0] 	 ra_of; // for MSRSET/MSRCLR
   input [4:0] 	 rd_of;   
   input [31:0]  opa_of;
   input [15:10] ich_dat;   
   //input 	 alu_c;
   
   input 	 gclk,
		 grst,
		 gpha,
		 dena;

   /*AUTOREG*/

   reg 			rMSR_C0, rMSR_C1;   
   reg 			rMSR_DCE,
			rMSR_ICE,
			rMSR_XSL,
			rMSR_BIP,
			rMSR_IE,
			rMSR_BE;   
   reg 			alu_cc;

   wire 		wMSR_CC = (gpha & AEMB_HTX[0]) ? rMSR_C0 : rMSR_C1;
   wire 		wMSR_CX = (gpha & AEMB_HTX[0]) ? rMSR_C1 : rMSR_C0;
   /*
   wire 		wMSR_C = (ich_dat == 6'o44) & wMSR_CX | // SRX
				 (ich_dat[15:14] == 2'o0) & ich_dat[11] & wMSR_CX | // ADDC/RSUBC
				 (ich_dat[15:14] == 2'o0) & (ich_dat[11:10] == 2'o1); // RSUB  
   */
   wire 		wMSR_C = alu_c;
   
   /*
    MSR REGISTER
    
    We should keep common configuration bits in the lower 16-bits of
    the MSR in order to avoid using the IMMI instruction.
    
    MSR bits
    31 - CC (carry copy)    
    30 - HTE (hardware thread enabled)
    29 - PHA (current phase)
    
     7 - DCE (data cache enable)   
     5 - ICE (instruction cache enable)    
     3 - BIP (break in progress)
     2 - C (carry flag)
     1 - IE (interrupt enable)
     0 - BE (bus-lock enable)        
    */
   
   wire [31:0] 		wMSR;
   //assign 		msr_of = sfr_of[13:0];   
   assign 		wMSR = {alu_cc,      // MSR_CC								
				AEMB_HTX[0],  // Thread Extension
				gpha,         // Phase
				21'd0,
				rMSR_DCE,     // MSR_DCE
				1'b0,         // resv DZ
				rMSR_ICE,     // MSR_ICE
				1'b0,         // resv for XSL				
				rMSR_BIP,     // MSR_BIP
				alu_cc,      // MSR_C
				rMSR_IE,      // MSR_IE
				rMSR_BE};     // MSR_BE

   reg [31:0] 		sfr_ex;
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	alu_cc <= 1'h0;
	sfr_ex <= 32'h0;
	// End of automatics
     end else if (dena) begin
	alu_cc <= #1 alu_c;	
	//sfr_mx <= #1 sfr_ex;	
	sfr_ex <= #1 wMSR; // Select SFR
     end
   
   // DECODE MTS/MFS/MSRSET/MSRCLR
   wire 		fMOV = (opc_of == 6'o45);
   wire 		fMTS = fMOV & &imm_of[15:14];
   wire 		fMOP = fMOV & ~|imm_of[15:14];   		
   // MSRSET/MSRCLR
   wire [13:0] 		wRES = (ra_of[0]) ? 
			       (wMSR[13:0]) & ~imm_of[13:0] : // MSRCLR
			       (wMSR[13:0]) | imm_of[13:0]; // MSRSET      
   
   // 0 - Break
   // 1 - Interrupt
   // 2 - Exception
   // 3 - Reserved
   wire 	    fRTID = (opc_of == 6'o55) & rd_of[0];
   wire 	    fRTBD = (opc_of == 6'o55) & rd_of[1];
   wire 	    fBRKI = (opc_of == 6'o56) & (ra_of[4:0] == 5'hD);
   wire 	    fBRKB = ((opc_of == 6'o46) | (opc_of == 6'o56)) & (ra_of[4:0] == 5'hC);
   
   //wire 	    fADDC = (opc_of[5:4] == 2'o0) & (!opc_of[2]); // add/sub non K  
   //wire 	    fSHFC = (opc_of == 6'o44) & (imm_of[6:5] != 2'o3);   
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMSR_BE <= 1'h0;
	rMSR_BIP <= 1'h0;
	rMSR_DCE <= 1'h0;
	rMSR_ICE <= 1'h0;
	rMSR_IE <= 1'h0;
	// End of automatics
     end else if (dena) begin
/*	
	msr_of <= #1 // used internally
		  {6'd0,
		   rMSR_DCE,     // MSR_DCE
		   1'b0,         // resv DZ
		   rMSR_ICE,     // MSR_ICE
		   1'b0,         // resv for XSL				
		   rMSR_BIP,     // MSR_BIP
		   alu_c,        // MSR_C
		   rMSR_IE,      // MSR_IE
		   rMSR_BE};     // MSR_BE
*/	 		
	rMSR_DCE <= #1
		   (fMTS) ? opa_of[7] :
		   (fMOP) ? wRES[7] :
		   rMSR_DCE;	
	
	rMSR_ICE <= #1
		   (fMTS) ? opa_of[5] :
		   (fMOP) ? wRES[5] :
		   rMSR_ICE;		
	
	rMSR_BE <= #1
		   (fMTS) ? opa_of[0] :
		   (fMOP) ? wRES[0] :
		   rMSR_BE;	
	
	rMSR_IE <= #1
		   (fBRKI) ? 1'b0 :
		   (fRTID) ? 1'b1 :
		   (fMTS) ? opa_of[1] :
		   (fMOP) ? wRES[1] :
		   rMSR_IE;			

	rMSR_BIP <= #1
		    (fBRKB) ? 1'b1 :
		    (fRTBD) ? 1'b0 :
		    (fMTS) ? opa_of[3] :
		    (fMOP) ? wRES[3] :
		    rMSR_BIP;
	
     end
   
endmodule // aeMB2_sfrf

/*
 $Log: not supported by cvs2svn $
 Revision 1.1  2008/04/18 00:21:52  sybreon
 Initial import.
*/