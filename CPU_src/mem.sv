module dmem(input  logic        clk, we,
            input  logic [31:0] a, wd,
            output logic [31:0] rd);

  logic [31:0] RAM[63:0];

  assign rd = RAM[a[31:2]]; // word aligned

  always_ff @(posedge clk)
    if (we) RAM[a[31:2]] <= wd;

endmodule// dmem


module imem(input  logic [29:0] a,
            output logic [31:0] rd);

  logic [31:0] RAM[127:0];

  initial
      $readmemh("/media/sf_CPU/assembler/check_new_comANDhazard_bin.dat",RAM);

  assign rd = RAM[a]; // word aligned
endmodule// imem