module param_decoder
#(
    parameter WIDTH_DATA_IN  = 32,
    parameter WIDTH_DATA_OUT = 32,

)
(
    input  logic [WIDTH_DATA_IN -1:0] data_in,
    output logic [WIDTH_DATA_OUT-1:0] data_out
);
logic [$clog2(WIDTH_DATA_IN):0] a[WIDTH_DATA_IN-1:0];
generate
    for(genvar i = 0; i < WIDTH_DATA_IN; i++)begin
        assign a[i] = (data_in[WIDTH_DATA_IN-1:i] == 1) ? i : 0; 
    end
endgenerate

assign data_out = |a;



endmodule 