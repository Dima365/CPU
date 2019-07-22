interface main_bus 
(
    input  logic clk,
    input  logic reset
);
//FETCH
logic [31:0] pcF, pcplus4F, instrF;
logic stall_F;
//DECODE
logic regwriteD;
logic [1:0] memtoregD;
logic memwriteD;
logic [2:0] alucontrolD;
logic alusrcD;
logic regdstD;
logic jumpD;

logic [31:0] instrD, pcplus4D, pcbranchD, signimmD, pcjumpD;
logic [4:0] rsD, rtD, rdD;
logic branchD, equalD, pcsrcD;
logic [31:0] rd1D, rd2D;

logic kernel_mode;
logic [2:0] int_cause;
logic cause_write;
logic exit_kernel;
logic jump_regD;
logic [31:0] c0D;
logic write_c0D;

logic [4:0] shamtD;
logic stall_D;
//EXECUTE
logic regwriteE;
logic [1:0] memtoregE;
logic memwriteE;
logic [2:0] alucontrolE;
logic alusrcE;
logic regdstE;

logic [31:0] mux_c0E;
logic write_c0E;
logic flushE;
logic overflowE;
logic [2:0] forwardAE, forwardBE;
logic [31:0] signimmE, rd1E, rd2E;
logic [4:0] rsE, rtE, rdE, writeregE;
logic [31:0] srcAE, srcBE;
logic [31:0] aluoutE, writedataE;
logic [31:0] c0E;

logic [4:0] shamtE;
//MEMORY
logic regwriteM;
logic [1:0] memtoregM;
logic memwriteM;

logic write_c0M;
logic [31:0] aluoutM, writedataM, readdataM;
logic [4:0] writeregM;
logic [31:0] c0M;
//WRITEBACK
logic regwriteW;
logic [1:0] memtoregW;

logic write_c0W;
logic [31:0] readdataW, aluoutW, resultW;
logic [4:0] writeregW;
logic [31:0] c0W;

//BYPASS
logic [31:0] AD_mux_out, BD_mux_out;


/////////////////////////////////////////

//FETCH
modport imem(  
                input  pcF, 
                output instrF
             );

always_ff @(posedge reset, posedge clk)
    if(reset) 
        pcF <= 0;
    else if(cause_write)
        pcF <= 32'd72;// ??? куда ???
    else if(jump_regD)
        pcF <= AD_mux_out;
    else if(jumpD)
        pcF <= pcjumpD;
    else if(~stall_F && pcsrcD) 
        pcF <= pcbranchD;
    else if(~stall_F && ~pcsrcD)
        pcF <= pcplus4F;


assign pcplus4F = pcF + 4;

//DECODE
modport regfile(
                input  instrD, resultW,
                input  regwriteW,
                input  writeregW,
                output rd1D, rd2D
              );

modport controller(
                    input  instrD,

                    output int_cause,
                    output cause_write,
                    output exit_kernel,
                    output jump_regD,
                    input  overflowE,
                    input  kernel_mode,
                    output write_c0D,

                    
                    output regwriteD,
                    output memtoregD,
                    output memwriteD,
                    output alucontrolD,
                    output alusrcD,
                    output regdstD,
                    output branchD,
                    output jumpD 
                );

modport coprocessor_0(

                        input  write_c0W,
                        input  resultW,
                        input  writeregW,

                        input  pcF,
                        input  int_cause,
                        input  cause_write,
                        input  rtD,
                        output c0D,
                        output kernel_mode,
                        input  exit_kernel    
                    );

always_ff @(posedge reset, posedge clk)
    if(reset) begin 
        instrD   <= {6'b110001, 26'd0}; // nop
        pcplus4D <= 0;
    end
    else if(jump_regD && stall_D == 0)begin
        instrD   <= {6'b110001, 26'd0}; // nop
        pcplus4D <= 0;
    end        
    else if(jumpD)begin
        instrD   <= {6'b110001, 26'd0}; // nop
        pcplus4D <= 0;
    end
    else if(cause_write)begin 
        instrD   <= {6'b110001, 26'd0}; // nop
        pcplus4D <= 0;
    end
    else if(pcsrcD) begin 
        instrD   <= {6'b110001, 26'd0}; // nop
        pcplus4D <= 0;
    end
    else if(~stall_D) begin 
        instrD   <= instrF;
        pcplus4D <= pcplus4F;
    end


assign signimmD  = {{16{instrD[15]}}, instrD[15:0]};
assign pcbranchD = pcplus4D + (signimmD << 2);
assign pcjumpD   = {pcplus4D[31:28], instrD[25:0], 2'b00};
assign rsD = instrD[25:21];
assign rtD = instrD[20:16];
assign rdD = instrD[15:11];
assign pcsrcD = equalD & branchD;
assign shamtD = instrD[10:6];


//EXECUTE
modport alu(
                    input alusrcE, // для overflow

                    input srcAE, srcBE,
                    input alucontrolE,
                    output overflowE,
                    output aluoutE
                );

always_ff @(posedge reset, posedge clk)
    if(reset) begin 
        regwriteE   <= 0;
        memtoregE   <= 0;
        memwriteE   <= 0;
        alucontrolE <= 0;
        alusrcE     <= 0;
        regdstE     <= 0;
        write_c0E   <= 0;
    end
    else if(flushE || cause_write)begin 
        regwriteE   <= 0;
        memtoregE   <= 0;
        memwriteE   <= 0;
        alucontrolE <= 0;
        alusrcE     <= 0;
        regdstE     <= 0;
        write_c0E   <= 0;
    end
    else begin 
        regwriteE   <= regwriteD;
        memtoregE   <= memtoregD;
        memwriteE   <= memwriteD;
        alucontrolE <= alucontrolD;
        alusrcE     <= alusrcD;
        regdstE     <= regdstD;
        write_c0E   <= write_c0D;  
    end

always_ff @(posedge reset, posedge clk)
    if(reset) begin
        rd1E     <= 0;
        rd2E     <= 0; 
        rsE      <= 0;
        rtE      <= 0;
        rdE      <= 0;
        signimmE <= 0;
        c0E      <= 0;
        shamtE   <= 0;
    end
    else if(flushE || cause_write) begin
        rd1E     <= 0;
        rd2E     <= 0; 
        rsE      <= 0;
        rtE      <= 0;
        rdE      <= 0;
        signimmE <= 0;
        c0E      <= 0;
        shamtE   <= 0;      
    end
    else begin 
        rd1E     <= rd1D;
        rd2E     <= rd2D;
        rsE      <= rsD;
        rtE      <= rtD;
        rdE      <= rdD;
        signimmE <= signimmD;
        c0E      <= c0D;
        shamtE   <= shamtD;
    end

always_comb
    if(memtoregE == 2'b10 && write_c0M && writeregE == writeregM)
        mux_c0E = c0M;
    else if(memtoregE == 2'b10 && write_c0W && writeregE == writeregW)
        mux_c0E = c0W;
    else 
        mux_c0E = c0E;

always_comb
    case (forwardAE)
        3'b000: srcAE = rd1E;
        3'b001: srcAE = resultW;
        3'b010: srcAE = aluoutM;
        3'b011: srcAE = c0M;  
        3'b100: srcAE = c0W;
        default : srcAE = 0;
      endcase  

always_comb
    if(alusrcE)
        srcBE = signimmE;
    else 
        case (forwardBE)
            3'b000: srcBE = rd2E;
            3'b001: srcBE = resultW;
            3'b010: srcBE = aluoutM;
            3'b011: srcBE = c0M;
            3'b100: srcBE = c0W;
            default : srcBE = 0;
        endcase

assign writeregE  = regdstE ? rdE : rtE;

always_comb
    case (forwardBE)
        3'b000: writedataE = rd2E;
        3'b001: writedataE = resultW;
        3'b010: writedataE = aluoutM;
        3'b011: writedataE = c0M;
        3'b100: writedataE = c0W;
        default : writedataE = 0;
    endcase   

//MEMORY
modport dmem(
                    input  aluoutM, writedataM,
                    input  memwriteM,
                    output readdataM
                );

always_ff @(posedge reset, posedge clk)
    if(reset) begin 
        regwriteM <= 0;
        memtoregM <= 0;
        memwriteM <= 0;
        write_c0M <= 0;
    end
    else if(overflowE)begin
        regwriteM <= 0;
        memtoregM <= 0;
        memwriteM <= 0;
        write_c0M <= 0;
    end
    else begin 
        regwriteM <= regwriteE;
        memtoregM <= memtoregE;
        memwriteM <= memwriteE;
        write_c0M <= write_c0E;
    end

always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        aluoutM    <= 0;
        writedataM <= 0;
        writeregM  <= 0;
        c0M        <= 0;
    end
    else if(overflowE)begin
        aluoutM    <= 0;
        writedataM <= 0;
        writeregM  <= 0;
        c0M        <= 0;
    end
    else begin 
        aluoutM    <= aluoutE;
        writedataM <= writedataE;
        writeregM  <= writeregE;
        c0M        <= mux_c0E;      
    end

// WRITEBACK
always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        regwriteW <= 0;
        memtoregW <= 0;
        write_c0W <= 0;
    end
    else begin 
        regwriteW <= regwriteM;
        memtoregW <= memtoregM;
        write_c0W <= write_c0M;        
    end

always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        readdataW <= 0;
        aluoutW   <= 0;
        writeregW <= 0;
        c0W       <= 0;
    end
    else begin 
        readdataW <= readdataM;
        aluoutW   <= aluoutM;
        writeregW <= writeregM;
        c0W       <= c0M;     
    end

always_comb
    if (memtoregW == 2'b10)
        resultW = c0W;
    else if(memtoregW == 2'b00)
        resultW = aluoutW;
    else 
        resultW = readdataW;


// BYPASS


always_comb
    if(rsE !=0 && rsE == writeregM && regwriteM && memtoregM == 2'b10)
        forwardAE = 3'b011;
    else if(rsE !=0 && rsE == writeregM && regwriteM)
        forwardAE = 3'b010;
    else if(rsE !=0 && rsE == writeregW && regwriteW && memtoregW == 2'b10)
        forwardAE = 3'b100;
    else if(rsE !=0 && rsE == writeregW && regwriteW)
        forwardAE = 3'b001;
    else 
        forwardAE = 3'b000;

always_comb
    if(rtE !=0 && rtE == writeregM && regwriteM && memtoregM == 2'b10)
        forwardBE = 3'b011;
    else if(rtE !=0 && rtE == writeregM && regwriteM)
        forwardBE = 3'b010;
    else if(rtE !=0 && rtE == writeregW && regwriteW && memtoregW == 2'b10)
        forwardBE = 3'b100;
    else if(rtE !=0 && rtE == writeregW && regwriteW)
        forwardBE = 3'b001;
    else 
        forwardBE = 3'b000;

always_comb
    if((rsD == rtE || rtD == rtE) //здесь правильно 
            && memtoregE == 2'b01)begin
                stall_F = 1;
                stall_D = 1;
                flushE  = 1;
    end
    else if(jump_regD && regwriteE && rsD == writeregE) begin
                stall_F = 0;
                stall_D = 1;
                flushE  = 0;
    end
    else if(branchD   && regwriteE && 
            (writeregE == rsD || writeregE == rtD))begin
                stall_F = 1;
                stall_D = 1;
                flushE  = 1;        
    end
    else if(branchD   &&  memtoregM == 2'b01 && 
            (writeregM == rsD || writeregM == rtD))begin
                stall_F = 1;
                stall_D = 1;
                flushE  = 1;        
    end
    else begin 
        stall_F = 0;
        stall_D = 0;
        flushE  = 0;
    end


// вместо сигналов forwardAD и forwardBD
assign equalD = (AD_mux_out == BD_mux_out) ? 1'b1 : 1'b0;

always_comb
    if(rsD != 0 && rsD == writeregM && regwriteM && memtoregM == 2'b10)
        AD_mux_out = c0M;
    else if(rsD != 0 && rsD == writeregM && regwriteM)
        AD_mux_out = aluoutM;
    else
        AD_mux_out = rd1D;
        
always_comb
    if(rtD != 0 && rtD == writeregM && regwriteM && memtoregM == 2'b10)
        BD_mux_out = c0M;
    else if(rtD != 0 && rtD == writeregM && regwriteM)
        BD_mux_out = aluoutM;
    else
        BD_mux_out = rd2D;

endinterface// main_bus