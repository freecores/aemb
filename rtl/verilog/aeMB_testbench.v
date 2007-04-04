//                              -*- Mode: Verilog -*-
// Filename        : aeMB_testbench.v
// Description     : AEMB Test Bench
// Author          : Shawn Tan Ser Ngiap <shawn.tan@aeste.net>
// Created On      : Sun Dec 31 17:07:54 2006
// Last Modified By: $Author: sybreon $
// Last Modified On: $Date: 2007-04-04 14:08:34 $
// Update Count    : $Revision: 1.3 $
// Status          : $State: Exp $

/*
 * $Id: aeMB_testbench.v,v 1.3 2007-04-04 14:08:34 sybreon Exp $
 * 
 * AEMB Generic Testbench
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
 * Top level test bench and fake RAM/ROM.
 *
 * HISTORY
 * $Log: not supported by cvs2svn $
 * Revision 1.2  2007/04/04 06:11:59  sybreon
 * Extended testbench code
 *
 * Revision 1.1  2007/03/09 17:52:17  sybreon
 * initial import
 *
 */

module testbench ();
   parameter ISIZ = 16;
   parameter DSIZ = 16;   
   
   reg sys_clk_i, sys_rst_i, sys_int_i, sys_exc_i;

   initial begin
      $dumpfile("aeMB_core.vcd");
      $dumpvars(1,dut,dut.regfile);
   end   
   
   initial begin
      sys_clk_i = 1;
      sys_rst_i = 0;
      sys_int_i = 0;
      sys_exc_i = 0;      
      #10 sys_rst_i = 1;
      #10000 sys_int_i = 1;
      #100 sys_int_i = 0;      
   end
   
   initial fork	
      #100000 $displayh("\nTest Completed."); 
      #100000 $finish;
   join   
   
   always #5 sys_clk_i = ~sys_clk_i;   

   // FAKE ROM
   reg [31:0] rom [0:65535];
   reg [31:0] iwb_dat_i;
   reg 	      iwb_ack_i, dwb_ack_i;
   wire [ISIZ-1:0] iwb_adr_o;
   wire        iwb_stb_o;
   wire        dwb_stb_o;

   always @(posedge sys_clk_i) begin
      iwb_ack_i <= #1 iwb_stb_o;
      dwb_ack_i <= #1 dwb_stb_o;
      iwb_dat_i <= #1 rom[iwb_adr_o[ISIZ-1:2]];
   end
   
   // FAKE RAM
   reg [31:0] ram [0:65535];
   reg [31:0] dwb_dat_i;
   reg [31:0] dwblat;
   wire       dwb_we_o;
   wire [31:0] dwb_dat_o;
   wire [DSIZ-1:0] dwb_adr_o;
   
   always @(posedge sys_clk_i) begin
      ram[dwb_adr_o[DSIZ-1:2]] <= (dwb_we_o & dwb_stb_o) ? dwb_dat_o : ram[dwb_adr_o[DSIZ-1:2]];
      dwblat <= dwb_adr_o;
      dwb_dat_i <= ram[dwb_adr_o[DSIZ-1:2]];      
   end

   integer i;   
   initial begin
      for (i=0;i<65535;i=i+1) begin
	 ram[i] <= 32'h0;
	 rom[i] <= 32'h0;	 
      end
      
      #1 $readmemh("aeMB.rom",rom);
      #1 $readmemh("aeMB.rom",ram); 

   end   

   always @(posedge sys_clk_i) begin
      $write($stime);
      $writeh(": PC=0x",iwb_adr_o,": INST=",iwb_dat_i);
      if (dwb_stb_o & dwb_we_o) 
	$writeh("; ST: 0x",dwb_adr_o,"=0x",dwb_dat_o);
      #1
      if (dwb_stb_o & ~dwb_we_o)
	$writeh("; LD: 0x",dwb_adr_o,"=0x",dwb_dat_i);

      if ((dwb_adr_o == 16'h8888) && (dwb_dat_o == 32'h7a55ed00))
	$write("; *** INTERRUPT ***");      
      
      #1
      $write("\n");      
   end
   
   aeMB_core #(ISIZ,DSIZ)
     dut (
	  .sys_int_i(sys_int_i),.sys_exc_i(sys_exc_i),
	  .dwb_ack_i(dwb_ack_i),.dwb_stb_o(dwb_stb_o),.dwb_adr_o(dwb_adr_o),
	  .dwb_dat_o(dwb_dat_o),.dwb_dat_i(dwb_dat_i),.dwb_we_o(dwb_we_o),
	  .iwb_adr_o(iwb_adr_o),.iwb_dat_i(iwb_dat_i),.iwb_stb_o(iwb_stb_o),
	  .iwb_ack_i(iwb_ack_i),
	  .sys_clk_i(sys_clk_i), .sys_rst_i(sys_rst_i),.sys_run_i(1'b1)
	  );
   
endmodule