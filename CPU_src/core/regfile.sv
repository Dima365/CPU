module regfile(input  logic        clk,
               input  logic        reset, 
               input  logic        we3, 
               input  logic [4:0]  ra1, ra2, wa3, 
               input  logic [31:0] wd3, 
               output logic [31:0] rd1, rd2);

  logic [31:0] rf[31:0];

  // three ported register file
  // read two ports combinationally
  // write third port on rising edge of clk
  // register 0 hardwired to 0
  // note: for pipelined processor, write third port
  // on falling edge of clk

generate
  for (genvar i = 0; i < 32; i++) begin
    always_ff @(posedge reset, negedge clk)
        if(reset)
            rf[i] <= 0;    
        else if (we3 && i == wa3) 
            rf[i] <= wd3;
  end    
endgenerate
    

  assign rd1 = (ra1 != 0) ? rf[ra1] : 0;
  assign rd2 = (ra2 != 0) ? rf[ra2] : 0;
endmodule // regfile