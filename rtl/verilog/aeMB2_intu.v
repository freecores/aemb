/* $Id: aeMB2_intu.v,v 1.1 2008-04-18 00:21:52 sybreon Exp $
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
 * One Cycle Integer Unit
 * @file aeMB2_intu.v
 
 * This implements a single cycle integer unit. It performs all basic
   arithmetic, shift, and logic operations. 
 
 */

module aeMB2_intu (/*AUTOARG*/
   // Outputs
   mem_ex, bpc_ex, alu_ex, alu_mx, msr_ex, sfr_mx,
   // Inputs
   opc_of, opa_of, opb_of, opd_of, imm_of, rd_of, ra_of, gclk, grst,
   dena, gpha
   );
   parameter AEMB_DWB = 32;   
   parameter AEMB_IWB = 32;
   parameter AEMB_HTX = 1;
   
   output [31:2] mem_ex;
   output [31:2] bpc_ex;   

   output [31:0] alu_ex,
		 alu_mx;   
   
   input [5:0] 	 opc_of;
   input [31:0]  opa_of;
   input [31:0]  opb_of;
   input [31:0]  opd_of;   
   input [15:0]  imm_of;
   input [4:0] 	 rd_of,
		 ra_of;   
   output [7:0]  msr_ex;   
   output [31:0] sfr_mx;   
   
   // SYS signals
   input 	 gclk,
		 grst,
		 dena,
		 gpha;      

   /*AUTOREG*/
   // Beginning of automatic regs (for this module's undeclared outputs)
   reg [31:0]		alu_ex;
   reg [31:0]		alu_mx;
   reg [31:2]		bpc_ex;
   reg [31:2]		mem_ex;
   reg [31:0]		sfr_mx;
   // End of automatics

   reg 			rMSR_C,
			rMSR_CC,
			rMSR_C0, rMSR_C1,
			rMSR_MTX,
			rMSR_DCE, 
			rMSR_ICE,
			rMSR_BIP, 
			rMSR_IE,
			rMSR_BE;   
   
   
   // ADDER
   
   /* Infer a ADDER cell because ADD/SUB cannot be inferred cross
    technologies. */
   
   // FIXME: Redesign this critical path

   reg [31:0] 		add_ex;
   reg 			add_c;

   wire 		fCCC = !opc_of[5] & !opc_of[4] & opc_of[1];
   wire 		fSUB = !opc_of[5] & !opc_of[4] & opc_of[0];
   wire 		fCMP = !opc_of[3] & !imm_of[1] & imm_of[0];   
   
   wire [31:0] 		wOPA = (fSUB) ? ~opa_of : opa_of;   
   wire 		wOPC = (fCCC) ? rMSR_CC : fSUB;
   wire [31:0] 		wADD;
   wire 		wADC;
   
   assign 		{wADC, wADD} = (opb_of + wOPA) + wOPC;   
   
   always @(/*AUTOSENSE*/fCMP or wADC or wADD) begin
      {add_c, add_ex} <= #1 {wADC, (wADD[31] ^ fCMP) , wADD[30:0]}; // add with carry
   end
      
   // SHIFT/LOGIC/MOVE
   reg [31:0] 		slm_ex;
   reg 			slm_c;

   always @(/*AUTOSENSE*/imm_of or opa_of or opb_of or opc_of
	    or rMSR_CC)
     case (opc_of[2:0])
       // LOGIC
       3'o0: slm_ex <= #1 opa_of | opb_of;
       3'o1: slm_ex <= #1 opa_of & opb_of;
       3'o2: slm_ex <= #1 opa_of ^ opb_of;
       3'o3: slm_ex <= #1 opa_of & ~opb_of;
       // SHIFT/SEXT
       3'o4: case ({imm_of[6:5],imm_of[0]})
	       3'o1: slm_ex <= #1 {opa_of[31],opa_of[31:1]}; // SRA
	       3'o3: slm_ex <= #1 {rMSR_CC,opa_of[31:1]}; // SRC
	       3'o5: slm_ex <= #1 {1'b0,opa_of[31:1]}; // SRL
	       3'o6: slm_ex <= #1 {{(24){opa_of[7]}}, opa_of[7:0]}; // SEXT8
	       3'o7: slm_ex <= #1  {{(16){opa_of[15]}}, opa_of[15:0]}; // SEXT16
	       default: slm_ex <= #1 32'hX;	       
	     endcase // case ({imm_of[6:5],imm_of[0]})
       // MFS/MTS/MSET/MCLR
       //3'o5: slm_ex <= #1 sfr_of;       
       // BRL (PC from SFR)
       //3'o6: slm_ex <= #1 sfr_of;
       default: slm_ex <= #1 32'hX;       
     endcase // case (opc_of[2:0])
   
   always @(/*AUTOSENSE*/imm_of or opa_of or rMSR_CC)
     slm_c <= #1 (&imm_of[6:5]) ? rMSR_CC : opa_of[0];


   // BRANCH CALC
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	bpc_ex <= 30'h0;
	// End of automatics
     end else if (dena) begin
	bpc_ex <= #1 
		  (!opc_of[0] & ra_of[3]) ? // check for BRA
		  opb_of[AEMB_IWB-1:2] : // BRA only
		  add_ex[AEMB_IWB-1:2]; // RTD/BCC/BR
     end
   
   // ALU RESULT
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	alu_ex <= 32'h0;
	alu_mx <= 32'h0;
	mem_ex <= 30'h0;
	// End of automatics
     end else if (dena) begin
	alu_mx <= #1 alu_ex;
	alu_ex <= #1 (opc_of[5]) ? slm_ex : add_ex;	
	mem_ex <= #1 add_ex[AEMB_DWB-1:2]; // LXX/SXX	
     end


   // MSR SECTION

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
     4 - MTX (hardware mutex bit)
     3 - BIP (break in progress)
     2 - C (carry flag)
     1 - IE (interrupt enable)
     0 - BE (bus-lock enable)        
    */

   assign msr_ex = {
		    rMSR_DCE,
		    1'b0,
		    rMSR_ICE,
		    rMSR_MTX,
		    rMSR_BIP,
		    rMSR_C,
		    rMSR_IE,
		    rMSR_BE 
		    };
      
   // MSRSET/MSRCLR (small ALU)
   wire [7:0] wRES = (ra_of[0]) ? 
	       (msr_ex[7:0]) & ~imm_of[7:0] : // MSRCLR
	       (msr_ex[7:0]) | imm_of[7:0]; // MSRSET      
   
   // 0 - Break
   // 1 - Interrupt
   // 2 - Exception
   // 3 - Reserved
   wire 	    fRTID = (opc_of == 6'o55) & rd_of[0];
   wire 	    fRTBD = (opc_of == 6'o55) & rd_of[1];
   wire 	    fBRKI = (opc_of == 6'o56) & (ra_of[4:0] == 5'hD);
   wire 	    fBRKB = ((opc_of == 6'o46) | (opc_of == 6'o56)) & (ra_of[4:0] == 5'hC);
   wire 	    fMOV = (opc_of == 6'o45);
   wire 	    fMTS = fMOV & &imm_of[15:14];
   wire 	    fMOP = fMOV & ~|imm_of[15:14];   

   reg [31:0] 	    sfr_ex;
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMSR_BE <= 1'h0;
	rMSR_BIP <= 1'h0;
	rMSR_DCE <= 1'h0;
	rMSR_ICE <= 1'h0;
	rMSR_IE <= 1'h0;
	rMSR_MTX <= 1'h0;
	sfr_ex <= 32'h0;
	sfr_mx <= 32'h0;
	// End of automatics
     end else if (dena) begin // if (grst)
	sfr_mx <= #1 sfr_ex;	
	sfr_ex <= #1
		  {rMSR_CC,
		   AEMB_HTX[0],
		   !gpha,
		   21'd0,
		   rMSR_DCE,
		   1'b0,
		   rMSR_ICE,
		   rMSR_MTX,
		   rMSR_BIP,
		   rMSR_CC,
		   rMSR_IE,
		   rMSR_BE 
		   };
	
	rMSR_DCE <= #1
		   (fMTS) ? opa_of[7] :
		   (fMOP) ? wRES[7] :
		   rMSR_DCE;	
		
	rMSR_ICE <= #1
		   (fMTS) ? opa_of[5] :
		   (fMOP) ? wRES[5] :
		   rMSR_ICE;
	
	rMSR_MTX <= #1
		   (fMTS) ? opa_of[4] :
		   (fMOP) ? wRES[4] :
		   rMSR_MTX;	
	
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

   // BARREL C
   wire fADDSUB = (opc_of[5:2] == 4'h0) | (opc_of[5:2] == 4'h2);
   wire fSHIFT  = (opc_of[5:2] == 4'h9) & (imm_of[6:5] != 2'o3);
   
   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMSR_CC <= 1'h0;
	// End of automatics
     end else if (dena) begin
	rMSR_CC <= #1 rMSR_C;
     end

   always @(posedge gclk)
     if (grst) begin
	/*AUTORESET*/
	// Beginning of autoreset for uninitialized flops
	rMSR_C <= 1'h0;
	// End of automatics
     end else if (dena) begin
	rMSR_C <= #1
		  (fMTS) ? opa_of[2] :
		  (fMOP) ? wRES[2] :
		  (fSHIFT) ? opa_of[0] : // SRA/SRL/SRC
		  (fADDSUB) ? add_c : // ADD/SUB/ADDC/SUBC
		  rMSR_CC;
     end
   
endmodule // aeMB2_intu

// $Log: not supported by cvs2svn $
