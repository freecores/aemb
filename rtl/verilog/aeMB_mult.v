

module aeMB_mult (/*AUTOARG*/
   // Outputs
   rRES_MUL,
   // Inputs
   rOPA, rOPB
   );

   // INTERNAL
   output [31:0] rRES_MUL;

   input [31:0]  rOPA, rOPB;

   assign 	 rRES_MUL = (rOPA * rOPB);   
   
endmodule // aeMB_mult
