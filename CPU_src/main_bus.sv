interface main_bus 
(
    input  logic clk,
    input  logic reset
);
//FETCH
logic [31:0] pc, pcF, pcplus4F, instrF;
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
logic jump_reg;
logic [31:0] c0D;
logic write_c0;

logic [1:0] forwardAD, forwardBD, 
logic stall_D;
//EXECUTE
logic regwriteE;
logic [1:0] memtoregE;
logic memwriteE;
logic [2:0] alucontrolE;
logic alusrcE;
logic regdstE;


logic flushE;
logic overflowE;
logic [1:0] forwardAE, forwardBE;
logic [31:0] signimmE, rd1E, rd2E;
logic [4:0] rsE, rtE, rdE, writeregE;
logic [31:0] srcAE, srcBE;
logic [31:0] aluoutE, writedataE;
logic [31:0] c0E;
//MEMORY
logic regwriteM;
logic [1:0] memtoregM;
logic memwriteM;

logic [31:0] aluoutM, writedataM, readdataM;
logic [4:0] writeregM;
logic [31:0] c0M;
//WRITEBACK
logic regwriteW;
logic [1:0] memtoregW;

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
    else if(jump_reg)
        pcF <= rd1D;
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
                    output jump_reg
                    input  overflowE,
                    input  kernel_mode,
                    
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

                        input  write_c0,
                        input  resultW,
                        input  writeregW,

                        input  pcF,
                        input  int_cause,
                        input  cause_write,
                        input  rtD,
                        output c0D,
                        output kernel_mode,
                        input  exit_kernel,    
                    )

always_ff @(posedge reset, posedge clk)
    if(reset) begin 
        instrD   <= 0;
        pcplus4D <= 0;
    end
    else if(pcsrcD) begin 
        instrD   <= 0;
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



//EXECUTE
modport alu(
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
    end
    else if(flushE)begin 
        regwriteE   <= 0;
        memtoregE   <= 0;
        memwriteE   <= 0;
        alucontrolE <= 0;
        alusrcE     <= 0;
        regdstE     <= 0;
    end
    else begin 
        regwriteE   <= regwriteD;
        memtoregE   <= memtoregD;
        memwriteE   <= memwriteD;
        alucontrolE <= alucontrolD;
        alusrcE     <= alusrcD;
        regdstE     <= regdstD;  
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
    end
    else if(flushE) begin
        rd1E     <= 0;
        rd2E     <= 0; 
        rsE      <= 0;
        rtE      <= 0;
        rdE      <= 0;
        signimmE <= 0;
        c0E      <= 0;      
    end
    else begin 
        rd1E     <= rd1D;
        rd2E     <= rd2D;
        rsE      <= rsD;
        rtE      <= rtD;
        rdE      <= rdD;
        signimmE <= signimmD;
        c0E      <= c0D;
    end

always_comb
    case (forwardAE)
        2'b00: srcAE = rd1E;
        2'b01: srcAE = resultW;
        2'b10: srcAE = aluoutM;
        2'b11: srcAE = c0M;  
        default : srcAE = 0;
      endcase  

always_comb
    if(alusrcE)
        srcBE = signimmE;
    else 
        case (forwardBE)
            2'b00: srcBE = rd2E;
            2'b01: srcBE = resultW;
            2'b10: srcBE = aluoutM;
            2'b11: srcBE = c0M;
            default : srcBE = 0;
        endcase

assign writeregE  = regdstE ? rdE : rtE;

always_comb
    case (forwardBE)
        2'b00: writedataE = rd2E;
        2'b01: writedataE = resultW;
        2'b10: writedataE = aluoutM;
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
    end
    else begin 
        regwriteM <= regwriteE;
        memtoregM <= memtoregE;
        memwriteM <= memwriteE;
    end

always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        aluoutM    <= 0;
        writedataM <= 0;
        writeregM  <= 0;
    end
    else begin 
        aluoutM    <= aluoutE;
        writedataM <= writedataE;
        writeregM  <= writeregE;
        c0M        <= c0E;      
    end

// WRITEBACK
always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        regwriteW <= 0;
        memtoregW <= 0;
    end
    else begin 
        regwriteW <= regwriteM;
        memtoregW <= memtoregM;        
    end

always_ff @(posedge reset, posedge clk)
    if(reset)begin 
        readdataW <= 0;
        aluoutW   <= 0;
        writeregW <= 0;
    end
    else begin 
        readdataW <= readdataM;
        aluoutW   <= aluoutM;
        writeregW <= writeregM;
        c0W       <= c0M     
    end

always_comb
    if (memtoregW == 2'b10)
        resultW = c0W;
    else if(memtoregW == 2'b00)
        resultW = aluoutW;
    else 
        resultW = readdataW;


// BYPASS

// стоит подумать как сделать это красиво
//=========================================
logic jump_delay;

always_ff @(posedge reset, posedge clk)
    if(reset)
        jump_delay <= 0;
    else
        jump_delay <= jumpD;
//=========================================
always_comb
    if(rsE !=0 && rsE == writeregM && regwriteM && memtoregM == 2'b10)
        forwardAE = 2'b11;
    else if(rsE !=0 && rsE == writeregM && regwriteM)
        forwardAE = 2'b10;
    else if(rsE !=0 && rsE == writeregW && regwriteW)
        forwardAE = 2'b01;
    else 
        forwardAE = 2'b00;

always_comb
    if(rtE !=0 && rtE == writeregM && regwriteM && memtoregM == 2'b10)
        forwardBE = 2'b11;
    else if(rtE !=0 && rtE == writeregM && regwriteM)
        forwardBE = 2'b10;
    else if(rtE !=0 && rtE == writeregW && regwriteW)
        forwardBE = 2'b01;
    else 
        forwardBE = 2'b00;

always_comb
    if((rsD == rtE || rtD == rtE) 
            && memtoregE == 2'b01)begin
                stall_F = 1;
                stall_D = 1;
                flushE  = 1;
    end
    else if((jumpD || jump_reg) && ~jump_delay) begin
        stall_F = 0;// подумать над этим !!!!!!!!!!!!!!!!              
        stall_D = 1;
        flushE  = 1;
    end
    else if(branchD   && regwriteE && 
            (writeregE == rsD || writeregE == rtD))begin
                stall_F = 1;
                stall_D = 1;
                flushE  = 1;        
    end
    else if(branchD   &&  memtoregM == 2'b01 && 
            (writeregM == rsD && writeregM == rtD))begin
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
        BD_mux_out = rd1D;

endinterface// main_bus