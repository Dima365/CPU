module coprocessor_0
(
    input  logic reset,
    input  logic clk,

    input  logic        write_c0W,
    input  logic [31:0] resultW,
    input  logic [4:0]  writeregW,

    input  logic [31:0] pcF,
    input  logic [2:0]  int_cause,
    input  logic        cause_write,
   

    input  logic [4:0]  rtD,

    output logic [31:0] c0D,
    output logic        kernel_mode,// 0 - режим ядра, 1 - пользователя
    input  logic        exit_kernel 
);
logic [2:0]  cause_reg;
logic [31:0] epc;
logic [31:0] point_table; // указатель на таблицу страниц

always_ff @(posedge reset, posedge clk)
    if(reset)
        kernel_mode <= 0;
    else if(exit_kernel) 
        kernel_mode <= 1;
    else if(cause_write)
        kernel_mode <= 0;

always_ff @(posedge reset, posedge clk)
    if(reset)
        cause_reg <= 0;
    else if(cause_write)
        cause_reg <= int_cause;

always_ff @(posedge reset, posedge clk)
    if(reset)
        epc <= 0;
    else if(cause_write)
        case(int_cause)
            3'b001: epc <= pcF - 8;
            3'b010: epc <= pcF - 4;
            3'b011: epc <= pcF - 4;
        endcase // int_cause

always_ff @(posedge reset, negedge clk)//!!!!!!!!!!!!!!!!!!!!!!!!
    if(reset)
        point_table <= 0;
    else if(write_c0 && writeregW == 5'b00011)
        point_table <= resultW;

always_comb
    case(rtD)
        5'b00000: c0D = {'0, kernel_mode};
        5'b00001: c0D = {'0, cause_reg};
        5'b00010: c0D = epc;
        5'b00011: c0D = point_table;
        default:  c0D = 0;
    endcase
    


endmodule // coprocessor_0