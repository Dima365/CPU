module alu(input  logic [31:0] a, b,
           input  logic [2:0]  alucontrol,
           output logic [31:0] result,
           output logic        overflow,
           output logic        zero);

  logic [31:0] condinvb, condinvb_plus1, sum;

  assign condinvb = alucontrol[2] ? ~b : b;
  assign condinvb_plus1 = condinvb + alucontrol[2];
  assign sum = a + condinvb_plus1;

  always_comb
    if(alucontrol[2:1] == 2'b11)
        overflow = ~b[31];
    else if(alucontrol[2:1] == 2'b11 && a[31] && condinvb_plus1[31])
        overflow = ~sum[31];  
    else if(alucontrol[2:1] == 2'b11 && ~a[31] && ~condinvb_plus1[31])
        overflow = sum[31];
    else
        overflow = 1'b0;

  always_comb
    case (alucontrol[1:0])
      2'b00: result = a & b;
      2'b01: result = a | b;
      2'b10: result = sum;
      2'b11: result = sum[31];
    endcase

  assign zero = (result == 32'b0);
endmodule // alu