// $Id: edk32.v,v 1.2 2007-11-02 19:16:10 sybreon Exp $
//
// AEMB EDK 3.2 Compatible Core TEST
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
// Revision 1.1  2007/11/02 03:25:45  sybreon
// New EDK 3.2 compatible design with optional barrel-shifter and multiplier.
// Fixed various minor data hazard bugs.
// Code compatible with -O0/1/2/3/s generated code.
//

module edk32 ();


   // INITIAL SETUP //////////////////////////////////////////////////////
   
   reg 	     sys_clk_i, sys_rst_i, sys_int_i, sys_exc_i;
   reg 	     svc;
   integer   inttime;
   
   always #5 sys_clk_i = ~sys_clk_i;   

   initial begin
      //$dumpfile("dump.vcd");
      //$dumpvars(1,dut);
   end
   
   initial begin
      svc = 0;      
      sys_clk_i = 1;
      sys_rst_i = 1;
      sys_int_i = 0;
      sys_exc_i = 0;      
      #30 sys_rst_i = 0;
   end

   initial fork
      //inttime $display("FSADFASDFSDAF");      
      //#10000 sys_int_i = 1;
      //#1100 sys_int_i = 0;
      //#100000 $displayh("\nTest Completed."); 
      //#4000 $finish;
   join   

   
   // FAKE MEMORY ////////////////////////////////////////////////////////
   
   wire [15:2] iwb_adr_o;
   wire        iwb_stb_o;
   wire        dwb_stb_o;
   reg [31:0]  rom [0:65535];
   wire [31:0] iwb_dat_i;
   reg 	       iwb_ack_i, dwb_ack_i;

   reg [31:0]  ram[0:65535];
   wire [31:0] dwb_dat_i;
   reg [31:0]  dwblat;
   wire        dwb_we_o;
   reg [15:2]  dadr,iadr;
   wire [3:0]  dwb_sel_o; 
   wire [31:0] dwb_dat_o;
   wire [15:2] dwb_adr_o;
   wire [31:0] dwb_dat_t;   
   
   assign      {dwb_dat_i[7:0],dwb_dat_i[15:8],dwb_dat_i[23:16],dwb_dat_i[31:24]} = ram[dadr];
   assign      {iwb_dat_i[7:0],iwb_dat_i[15:8],iwb_dat_i[23:16],iwb_dat_i[31:24]} = ram[iadr];
   assign      {dwb_dat_t} = ram[dwb_adr_o];
   
   always @(negedge sys_clk_i) begin
      iwb_ack_i <= #1 iwb_stb_o;
      dwb_ack_i <= #1 dwb_stb_o;
      iadr <= #1 iwb_adr_o;
      dadr <= dwb_adr_o;
      
      if (dwb_we_o & dwb_stb_o) begin
	 case (dwb_sel_o)
	   4'h1: ram[dwb_adr_o] <= {dwb_dat_o[7:0],dwb_dat_t[23:0]};
	   4'h2: ram[dwb_adr_o] <= {dwb_dat_t[31:24],dwb_dat_o[15:8],dwb_dat_t[15:0]};	   
	   4'h4: ram[dwb_adr_o] <= {dwb_dat_t[31:16],dwb_dat_o[23:16],dwb_dat_t[7:0]};	   
	   4'h8: ram[dwb_adr_o] <= {dwb_dat_t[31:8],dwb_dat_o[31:24]};	   
	   4'h3: ram[dwb_adr_o] <= {dwb_dat_o[7:0],dwb_dat_o[15:8],dwb_dat_t[15:0]};	   
	   4'hC: ram[dwb_adr_o] <= {dwb_dat_t[31:16],dwb_dat_o[23:16],dwb_dat_o[31:24]};	   	  
	   4'hF: ram[dwb_adr_o] <= {dwb_dat_o[7:0],dwb_dat_o[15:8],dwb_dat_o[23:16],dwb_dat_o[31:24]};	   
	 endcase // case (dwb_sel_o)
      end // if (dwb_we_o & dwb_stb_o)
   end // always @ (negedge sys_clk_i)

   integer i;   
   initial begin
      for (i=0;i<65535;i=i+1) begin
	 ram[i] <= $random;
      end
      #1 $readmemh("aeMB.rom",ram);
   end

   // DISPLAY OUTPUTS ///////////////////////////////////////////////////

   //assign dut.rRESULT = dut.rSIMM;   

   integer rnd;   
   always @(posedge sys_clk_i) begin

      // Interrupt Monitors
      if (!dut.rMSR_IE) begin
	 rnd = $random % 30;	 
	 inttime = $stime + 1000 + (rnd*rnd * 10);
      end
      if ($stime > inttime) begin
	 sys_int_i = 1;
	 svc = 0;	 
      end
      if (($stime > inttime + 500) && !svc) begin
	 $display("\n\t*** INTERRUPT TIMEOUT ***", inttime);	 
	 $finish;	 
      end
      if (dwb_we_o & (dwb_dat_o == "RTNI")) sys_int_i = 0;	 
      if (|dut.rXCE) svc = 1;
      
      // Pass/Fail Monitors
      if (dwb_we_o & (dwb_dat_o == "FAIL")) begin
	 $display("\n\tFAIL");	 
	 $finish;
      end
      if (iwb_dat_i == 32'hb8000000) begin
	 $display("\n\t*** PASSED ALL TESTS ***");
	 $finish;	 
      end
   end // always @ (posedge sys_clk_i)


   always @(posedge sys_clk_i) if (dut.gena) begin
      $write ("\n", ($stime/10));
      $writeh ("\tPC=", {iwb_adr_o,2'd0});

      // DECODE
      $writeh ("\t");
      
      case (dut.bpcu.rATOM)
	2'o2, 2'o1: $write("/");
	2'o0, 2'o3: $write("\\");
      endcase // case (dut.bpcu.rATOM)


      case ({dut.rBRA, dut.rDLY})
	2'b00: $write(" ");
	2'b01: $write(".");	
	2'b10: $write("-");
	2'b11: $write("+");	
      endcase // case ({dut.rBRA, dut.rDLY})
            
      case (dut.rOPC)
	6'o00: if (dut.rRD == 0) $write("   "); else $write("ADD");
	6'o01: $write("RSUB");	
	6'o02: $write("ADDC");	
	6'o03: $write("RSUBC");	
	6'o04: $write("ADDK");	
	6'o05: case (dut.rIMM[1:0])
		 2'o0: $write("RSUBK");	
		 2'o1: $write("CMP");	
		 2'o3: $write("CMPU");	
		 default: $write("XXX");
	       endcase // case (dut.rIMM[1:0])
	6'o06: $write("ADDKC");	
	6'o07: $write("RSUBKC");	

	6'o10: $write("ADDI");	
	6'o11: $write("RSUBI");	
	6'o12: $write("ADDIC");	
	6'o13: $write("RSUBIC");	
	6'o14: $write("ADDIK");	
	6'o15: $write("RSUBIK");	
	6'o16: $write("ADDIKC");	
	6'o17: $write("RSUBIKC");	

	6'o20: $write("MUL");	
	6'o21: case (dut.rALT[10:9])
		 2'o0: $write("BSRL");		 
		 2'o1: $write("BSRA");		 
		 2'o2: $write("BSLL");		 
		 default: $write("XXX");		 
	       endcase // case (dut.rALT[10:9])
	6'o22: $write("IDIV");	

	6'o30: $write("MULI");	
	6'o31: case (dut.rALT[10:9])
		 2'o0: $write("BSRLI");		 
		 2'o1: $write("BSRAI");		 
		 2'o2: $write("BSLLI");		 
		 default: $write("XXX");		 
	       endcase // case (dut.rALT[10:9])
	6'o33: $write("GETPUT");

	6'o40: $write("OR");
	6'o41: $write("AND");	
	6'o42: if (dut.rRD == 0) $write("   "); else $write("XOR");
	6'o43: $write("ANDN");	
	6'o44: case (dut.rIMM[6:5])
		 2'o0: $write("SRA");
		 2'o1: $write("SRC");
		 2'o2: $write("SRL");
		 2'o3: if (dut.rIMM[0]) $write("SEXT16"); else $write("SEXT8");		 
	       endcase // case (dut.rIMM[6:5])
	
	6'o45: $write("MOV");	
	6'o46: case (dut.rRA[3:2])
		 3'o0: $write("BR");		 
		 3'o1: $write("BRL");		 
		 3'o2: $write("BRA");		 
		 3'o3: $write("BRAL");		 
	       endcase // case (dut.rRA[3:2])
	
	6'o47: case (dut.rRD[2:0])
		 3'o0: $write("BEQ");	
		 3'o1: $write("BNE");	
		 3'o2: $write("BLT");	
		 3'o3: $write("BLE");	
		 3'o4: $write("BGT");	
		 3'o5: $write("BGE");
		 default: $write("XXX");		 
	       endcase // case (dut.rRD[2:0])
	
	6'o50: $write("ORI");	
	6'o51: $write("ANDI");	
	6'o52: $write("XORI");	
	6'o53: $write("ANDNI");	
	6'o54: $write("IMMI");	
	6'o55: case (dut.rRD[1:0])
		 2'o0: $write("RTSD");
		 2'o1: $write("RTID");
		 2'o2: $write("RTBD");
		 default: $write("XXX");		 
	       endcase
	6'o56: case (dut.rRA[3:2])
		 3'o0: $write("BRI");		 
		 3'o1: $write("BRLI");		 
		 3'o2: $write("BRAI");		 
		 3'o3: $write("BRALI");		 
	       endcase // case (dut.rRA[3:2])
	6'o57: case (dut.rRD[2:0])
		 3'o0: $write("BEQI");	
		 3'o1: $write("BNEI");	
		 3'o2: $write("BLTI");	
		 3'o3: $write("BLEI");	
		 3'o4: $write("BGTI");	
		 3'o5: $write("BGEI");	
		 default: $write("XXX");		 
	       endcase // case (dut.rRD[2:0])
	
	6'o60: $write("LBU");	
	6'o61: $write("LHU");	
	6'o62: $write("LW");	
	6'o64: $write("SB");	
	6'o65: $write("SH");	
	6'o66: $write("SW");	
	
	6'o70: $write("LBUI");	
	6'o71: $write("LHUI");	
	6'o72: $write("LWI");	
	6'o74: $write("SBI");	
	6'o75: $write("SHI");	
	6'o76: $write("SWI");

	default: $write("XXX");	
      endcase // case (dut.rOPC)

      case (dut.rOPC[3])
	1'b1: $writeh("\tr",dut.rRD,", r",dut.rRA,", h",dut.rIMM);
	1'b0: $writeh("\tr",dut.rRD,", r",dut.rRA,", r",dut.rRB,"  ");	
      endcase // case (dut.rOPC[3])


      // ALU
      $write("\t");
      //$writeh(" I=",dut.rSIMM);
      $writeh(" A=",dut.rOPA);
      $writeh(" B=",dut.rOPB);
      
      case (dut.rMXALU)
	3'o0: $write(" ADD");
	3'o1: $write(" LOG");
	3'o2: $write(" SFT");
	3'o3: $write(" MOV");
	3'o4: $write(" MUL");
	3'o5: $write(" BSF");
	default: $write(" XXX");
      endcase // case (dut.rMXALU)
      $writeh("=h",dut.xecu.xRESULT);

      // WRITEBACK
      $writeh("\tSR=", {dut.xecu.rMSR_BIP, dut.xecu.rMSR_C, dut.xecu.rMSR_IE, dut.xecu.rMSR_BE}," ");
      
      if (dut.regf.fRDWE) begin
	 case (dut.rMXDST)
	   2'o2: $writeh("R",dut.rRW,"=RAM(h",dut.regf.xWDAT,")");
	   2'o1: $writeh("R",dut.rRW,"=LNK(h",dut.regf.xWDAT,")");
	   2'o0: $writeh("R",dut.rRW,"=ALU(h",dut.regf.xWDAT,")");
	 endcase // case (dut.rMXDST)
      end

      // STORE
      if (dwb_stb_o & dwb_we_o) $writeh("RAM(",{dwb_adr_o,2'd0},")=",dwb_dat_o,":",dwb_sel_o);      
      
   end // if (dut.gena)
   
   
   // INTERNAL WIRING ////////////////////////////////////////////////////
   
   aeMB_edk32 #(16,16)
     dut (
	  .sys_int_i(sys_int_i),
	  .dwb_ack_i(dwb_ack_i),
	  .dwb_stb_o(dwb_stb_o),
	  .dwb_adr_o(dwb_adr_o),
	  .dwb_dat_o(dwb_dat_o),
	  .dwb_dat_i(dwb_dat_i),
	  .dwb_wre_o(dwb_we_o),
	  .dwb_sel_o(dwb_sel_o),
	  .iwb_adr_o(iwb_adr_o),
	  .iwb_dat_i(iwb_dat_i),
	  .iwb_stb_o(iwb_stb_o),
	  .iwb_ack_i(iwb_ack_i),
	  .sys_clk_i(sys_clk_i),
	  .sys_rst_i(sys_rst_i)
	  );




   
endmodule // edk32