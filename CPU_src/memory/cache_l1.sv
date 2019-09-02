//  MSI == 2'b00 - incorrect
//  MSI == 2'b01 - share
//  MSI == 2'b10 - modify 
module cache_l1
(
    input  logic rst,
    input  logic clk,

    input  logic set_incor_snp,
    input  logic re_snp,
    input  logic [31:0] addr_snp,
    output logic [31:0] Rdata_snp,
    output logic en_out_snp,

    input  logic we_core,
    input  logic re_core,
    input  logic [31:0] addr_core,
    output logic [31:0] Rdata_core,
    input  logic [31:0] Wdata_core,
    output logic ack_core,

    output logic we_l2,
    output logic re_l2,
    output logic [31:0] addr_l2,
    input  logic [33:0] Rdata_l2, //+ 2 бита для msi
    output logic [33:0] Wdata_l2, //+ 2 бита для msi
    output logic ack_l2
);
// не изменять !!!
localparam LEVEL_CACHE = 1;
localparam WIDTH_TEG   = 32 - 2 - WIDTH_INDEX;
localparam WIDTH_INDEX = 8;     
localparam NUM_CANAL   = 4;

logic [WIDTH_INDEX-1:0] index;
logic [WIDTH_TEG-1  :0] teg;
logic [1:0] random, replace;
logic miss_we, miss_re;
 

typedef enum logic [1:0] {  INCOR,
                            SHARE,
                            MODIF} msi_type;

typedef struct{
    msi_type              msi [NUM_CANAL-1:0];
    logic [WIDTH_TEG-1:0] teg [NUM_CANAL-1:0];
    logic [31:0]          data[NUM_CANAL-1:0];
} str_cache_type;

str_cache_type str_cache[WIDTH_INDEX-1:0];

typedef enum logic [2:0] {  WAIT,
                            MISS_WE,
                            MISS_RE} state_type;

state_type state, nextstate;

always_comb  
    if(state == WAIT &&  (set_incor_snp || re_snp))begin
        index = addr_snp [31 : WIDTH_INDEX + 2];
        teg   = addr_snp [31 : WIDTH_INDEX + 2];
    end
    else if(state == WAIT && (we_core || re_core))begin
        index = addr_core[31 : WIDTH_INDEX + 2];
        teg   = addr_core[31 : WIDTH_INDEX + 2];
    end
    else if(state == MISS_WE || state == MISS_RE)begin
        index = index_hold;
        teg   = teg_hold;
    else begin
        index = 0;
        teg   = 0;
    end



always_ff @(posedge rst,posedge clk)
    if(rst)begin
        random     <= 0;
        index_hold <= 0;
        teg_hold   <= 0;
    end
    else if(state == WAIT)begin
        random     <= random + 1;
        index_hold <= index;
        teg_hold   <= teg;
    end


always_comb
    if( state == WAIT && we_core && ~set_incor_snp && ~re_snp &&
        str_cache[index].teg[0] != teg &&
        str_cache[index].teg[1] != teg &&
        str_cache[index].teg[2] != teg &&
        str_cache[index].teg[3] != teg)
        case(INCOR)
            str_cache[index].msi[0]: replace = 0;
            str_cache[index].msi[1]: replace = 1;
            str_cache[index].msi[2]: replace = 2;
            str_cache[index].msi[3]: replace = 3;
            default: replace = random;                            
        endcase
    else if( state == WAIT && we_core && ~set_incor_snp && ~re_snp)
        case(teg)
            str_cache[index].teg[0]: replace = 0;
            str_cache[index].teg[1]: replace = 1;
            str_cache[index].teg[2]: replace = 2;
            str_cache[index].teg[3]: replace = 3;
            default: replace = random;                            
        endcase
    else if( state == MISS_RE && 
        str_cache[index_hold].msi[0] != INCOR && 
        str_cache[index_hold].teg[0] == teg_hold)
            replace = 0;

    else if( state == MISS_RE &&
        str_cache[index_hold].msi[1] != INCOR && 
        str_cache[index_hold].teg[1] == teg_hold)
            replace = 1;

    else if( state == MISS_RE &&
        str_cache[index_hold].msi[2] != INCOR && 
        str_cache[index_hold].teg[2] == teg_hold)
            replace = 2;

    else if( state == MISS_RE && 
        str_cache[index_hold].msi[2] != INCOR && 
        str_cache[index_hold].teg[2] == teg_hold)
            replace = 3;

    else if( state == MISS_RE) 
        case (INCOR)
            str_cache[index_hold].msi[0]: replace = 0;
            str_cache[index_hold].msi[1]: replace = 1;
            str_cache[index_hold].msi[2]: replace = 2;
            str_cache[index_hold].msi[3]: replace = 3;
        
            default : replace = random;
        endcase


always_comb
    if( state == WAIT && we_core && ~set_incor_snp && ~re_snp &&
        str_cache[index].msi[0] == MODIF &&
        str_cache[index].msi[1] == MODIF &&
        str_cache[index].msi[2] == MODIF &&
        str_cache[index].msi[3] == MODIF &&
        str_cache[index].tge[0] != teg   &&
        str_cache[index].teg[1] != teg   &&
        str_cache[index].teg[2] != teg   &&
        str_cache[index].teg[3] != teg   &&)
            miss_we = 1;
    else 
            miss_we = 0;


always_comb
    if(state == WAIT && re_core && ~set_incor_snp && ~re_snp)
        case(teg)
            str_cache[index].teg[0]: if(str_cache[index].msi[0] == INCOR)
                                        miss_re = 1;
            str_cache[index].teg[1]: if(str_cache[index].msi[1] == INCOR)
                                        miss_re = 1;
            str_cache[index].teg[2]: if(str_cache[index].msi[2] == INCOR)
                                        miss_re = 1;
            str_cache[index].teg[3]: if(str_cache[index].msi[3] == INCOR)
                                        miss_re = 1;
            default: miss_re = 1;                            
        endcase
    else
        miss_re = 0;

always_ff @(posedge rst, posedge clk)
    if(rst)
        state <= WAIT;
    else 
        state <= nextstate;

always_comb
    case(state)
        WAIT:    if(miss_we)
                    nextstate = MISS_WE;
                 else if(miss_re)
                    nextstate = MISS_RE;
                 else 
                    nextstate = WAIT;

        MISS_WE:
                 if(ack_l2 && str_cache[index_hold].msi[replace] == MODIF)
                    nextstate = MISS_WE_WE;
                 else if(ack_l2)
                    nextstate = WAIT;
                 else 
                    nextstate = MISS_WE;

        MISS_RE: if(ack_l2 && str_cache[index_hold].msi[replace] == MODIF)
                    nextstate = MISS_RE_WE;
                 else if(ack_l2)
                    nextstate = WAIT
                 else 
                    nextstate = MISS_RE; 
    endcase



generate
    for(genvar i = 0; i < WIDTH_INDEX; i++)begin // i
        for(genvar j = 0; j < NUM_CANAL; j++)begin // j
            always_ff @(posedge rst, posedge clk)
                if(rst)begin
                    str_cache[i].msi[j]  <= 0;
                    str_cache[i].teg[j]  <= 0;
                    str_cache[i].data[j] <= 0;
                end
                else begin
                    case(state)
                        WAIT:       if( set_incor_snp && 
                                        teg == str_cache[i].teg[j] && 
                                        index == i
                                        ) begin 
                                            str_cache[i].msi[j]  <= INCOR;
                                            str_cache[i].teg[j]  <= str_cache[i].teg[j];
                                            str_cache[i].data[j] <= str_cache[i].data[j];
                                        end
                                    else if(we_core && ~miss_we && index == i replace = j)begin
                                            str_cache[i].data[j] <= Wdata_core;

                                    end

                        MISS_WE:   if(ack_l2)


                        MISS_RE:    if(ack_l2 && index_hold == i && replace == j)begin
                                            str_cache[i].msi[j]  <= Wdata_l2[33:32];
                                            str_cache[i].teg[j]  <= teg_hold; 
                                            str_cache[i].data[j] <= Wdata_l2[31:0];
                                    end
                                 
                    endcase 
                end
        end // j
    end // i

endgenerate


always_ff @(posedge rst, posedge clk)
    if(rst)
        Rdata_snp <= 0;
    else if(state == WAIT && re_snp)
        case(teg)
            str_cache[index].teg[0]: if(str_cache[index].msi[0] != INCOR)
                                        Rdata_snp <= str_cache[index].data[0];
            str_cache[index].teg[1]: if(str_cache[index].msi[1] != INCOR)
                                        Rdata_snp <= str_cache[index].data[1];
            str_cache[index].teg[2]: if(str_cache[index].msi[2] != INCOR)
                                        Rdata_snp <= str_cache[index].data[2];
            str_cache[index].teg[3]: if(str_cache[index].msi[3] != INCOR)
                                        Rdata_snp <= str_cache[index].data[3];
        endcase

always_ff @(posedge rst,posedge clk)
    if(rst)
        en_out_snp <= 0;
    else if(state == WAIT && re_snp)
        case(teg)
            str_cache[index].teg[0]: if(str_cache[index].msi[0] != INCOR)
                                        en_out_snp <= 1;
            str_cache[index].teg[1]: if(str_cache[index].msi[1] != INCOR)
                                        en_out_snp <= 1;
            str_cache[index].teg[2]: if(str_cache[index].msi[2] != INCOR)
                                        en_out_snp <= 1;
            str_cache[index].teg[3]: if(str_cache[index].msi[3] != INCOR)
                                        en_out_snp <= 1;
        endcase
    else 
        en_out_snp <= 0;


always_ff @(posedge rst, posedge clk)
    if(rst)
        Rdata_snp <= 0;
    else if(state == WAIT && re_core && ~set_incor_snp && ~re_snp)
        case(teg)
            str_cache[index].teg[0]: if(str_cache[index].msi[0] != INCOR)
                                        Rdata_core <= str_cache[index].data[0];
            str_cache[index].teg[1]: if(str_cache[index].msi[1] != INCOR)
                                        Rdata_core <= str_cache[index].data[1];
            str_cache[index].teg[2]: if(str_cache[index].msi[2] != INCOR)
                                        Rdata_core <= str_cache[index].data[2];
            str_cache[index].teg[3]: if(str_cache[index].msi[3] != INCOR)
                                        Rdata_core <= str_cache[index].data[3];
        endcase
    else if(state == MISS_RE && ack_l2)
        Rdata_core <= Rdata_l2[31:0];


always_ff @(posedge rst, posedge clk)
    if(rst)
        ack_core <= 0;
    else if(state == WAIT && we_core && ~miss_we)
        ack_core <= 1;
    else if(state == WAIT && re_core && ~miss_re)
        ack_core <= 1;
    else if(state != WAIT && nextstate == WAIT)
        ack_core <= 1;
    else 
        ack_core <= 0;

always_ff @(posedge rst, posedge clk)
    if(rst)
        re_l2 <= 0;
    else if(nextstate == MISS_RE && state == WAIT)
        re_l2 <= 1;
    else 
        re_l2 <= 0;


always_ff @(posedge rst, posedge clk)
    if(rst)
        we_l2 <= 0;
    else if(state == WAIT && nextstate == MISS_WE)
        we_l2 <= 1;
    else if(state == MISS_RE && nextstate == MISS_RE_WE)
        we_l2 <= 1;
    else 
        we_l2 <= 0;

always_comb
    if(state == MISS_WE_WE || state == MISS_RE_WE)begin
        Wdata_l2[31:0]  = str_cache[index_hold].data[replace];
        Wdata_l2[33:32] = str_cache[index_hold].msi[replace];;
    end
    else 
        Wdata_l2 = 0;


always_comb
    if(state == MISS_WE || state == MISS_RE || state == MISS_RE_WE)
        addr_l2 = addr_core;
    else 
        addr_l2 = 0;    

endmodule 