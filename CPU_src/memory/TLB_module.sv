module TLB_module
#(
    parameter COUNT_STRING = 32,
    parameter WIDTH_PAGE   = 20,
    parameter WIDTH_OFFSET = 12 
)
(
    input  logic rst,
    input  logic clk,

    input  logic writeTLBM,
    input  logic memtoregM,
    input  logic memwriteM,
    input  logic [31:0] aluoutM,
    input  logic [31:0] writedataM,

    input  logic num_Vpage,
    output logic num_Ppage,

    output logic changePageM,
    output logic missM
);
wor [$clog2(COUNT_STRING):0] index;
typedef struct{
    logic correct;
    logic change;
    logic [WIDTH_PAGE-1:0] num_Vpage;
    logic [WIDTH_PAGE-1:0] num_Ppage; 
} word_TLB;

word_TLB TLB[COUNT_STRING-1:0];

generate
    for(genvar i = 0; i < 32; i++)begin
        always_ff @(posedge rst, posedge clk)
            if(~rst)
                TLB[i].num_Ppage <= 0;
            else if(writeTLBM && aluoutM[1:0] == 2'b00 && aluoutM[31:2] == i) 
                TLB[i].num_Ppage <= aluoutM[31:12];

        always_ff @(posedge rst, posedge clk)
            if(~rst)
                TLB[i].num_Vpage <= 0;
            else if(writeTLBM && aluoutM[1:0] == 2'b01 && aluoutM[31:2] == i) 
                TLB[i].num_Vpage <= aluoutM[31:12];    
    
        always_ff @(posedge rst, posedge clk)
            if(rst)
                TLB[i].correct  <= 0;
            else if(writeTLBM && aluoutM[1:0] == 2'b10 && aluoutM[31:2] == i)
                TLB[i].correct  <= aluoutM[12];

        always_ff @(posedge rst,posedge clk)
            if(rst)
                TLB[i].change <= 0;
            else if(writeTLBM && aluoutM[1:0] == 2'b11 && aluoutM[31:2] == i) 
                TLB[i].change <= 1;
    end

    // index == 0 означает промах TLB, поэтому индексация начинается с 1
    for (genvar i = 1; i <= COUNT_STRING; i++)begin
        always_comb
            if(TLB[i-1].num_Vpage == num_Vpage)
                index = i;
            else 
                index = 0;
    end

    assign num_Ppage = TLB[index-1].num_Ppage;

    always_comb
        if(memtoregM == 2'b01 && index == 0)
            missM = 1'b1;
        else if(memtoregM == 2'b01 && index != 0 && ~TLB[index-1].correct)
            missM = 1'b1;
        else
            missM = 1'b0;

    always_comb
        if(memwriteM && index != 0 && TLB[index].correct && ~TLB[index].change)
            changePageM = 1'b1;
        else 
            changePageM = 1'b0;

endgenerate

endmodule // end TLB_module