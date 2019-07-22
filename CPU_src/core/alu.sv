module alu(
           input  logic        alusrcE, // для overflow
           input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           input  logic [4:0]  shamt,
           output logic [31:0] result,
           output logic        overflow,
           output logic        zero);
  logic over;
  logic [31:0] condinvb, condinvb_plus1, sum;

  assign condinvb = alucontrol[2] ? ~b : b;
  assign condinvb_plus1 = condinvb + alucontrol[2];
  assign {over,sum} = a + condinvb_plus1;


  always_comb
    if(alucontrol == 3'b010 && over && ~(alusrcE && b[15]) )
        overflow = 1'b1;
    
    else if(alucontrol == 3'b010 && a[31] && alusrcE && b[15])
        overflow = ~sum[31];
    
    else if(alucontrol == 3'b110 && a[31] && condinvb_plus1[31])
        overflow = ~sum[31];  
    
    else if(alucontrol == 3'b110 && ~a[31] && ~condinvb_plus1[31])
        overflow = sum[31];
    
    else
        overflow = 1'b0;

  always_comb
    casez (alucontrol)
      3'b011:  result = a << shamt;
      3'b?00:  result = a & b;
      3'b?01:  result = a | b;
      3'b?10:  result = sum;
      3'b?11:  result = sum[31];
      default: result = 0;
    endcase

  assign zero = (result == 32'b0);
endmodule // alu