module bypass
(
    input logic reset,
    input logic clk,
    main_bus    bus 
);
// стоит подумать как сделать это красиво
//=========================================
logic jump_delay;

always_ff @(posedge reset, posedge clk)
    if(reset)
        jump_delay <= 0;
    else
        jump_delay <= bus.jumpD;
//=========================================
always_comb
    if(bus.rsE !=0 && bus.rsE == bus.writeregM && bus.regwriteM)
        bus.forwardAE = 2'b10;
    else if(bus.rsE !=0 && bus.rsE == bus.writeregW && bus.regwriteW)
        bus.forwardAE = 2'b01;
    else 
        bus.forwardAE = 2'b00;

always_comb
    if(bus.rtE !=0 && bus.rtE == bus.writeregM && bus.regwriteM)
        bus.forwardBE = 2'b10;
    else if(bus.rtE !=0 && bus.rtE == bus.writeregW && bus.regwriteW)
        bus.forwardBE = 2'b01;
    else 
        bus.forwardBE = 2'b00;

always_comb
    if((bus.rsD == bus.rtE || bus.rtD == bus.rtE) 
            && bus.memtoregE == 2'b01)begin
                bus.stall_F = 1;
                bus.stall_D = 1;
                bus.flushE  = 1;
    end
    else if((bus.jumpD || bus.jump_reg) && ~jump_delay) begin
        bus.stall_F = 0;// подумать над этим !!!!!!!!!!!!!!!!
        bus.stall_D = 1;
        bus.flushE  = 1;
    end
    else if(bus.branchD   && bus.regwriteE && 
            (bus.writeregE == bus.rsD || bus.writeregE == bus.rtD))begin
                bus.stall_F = 1;
                bus.stall_D = 1;
                bus.flushE  = 1;        
    end
    else if(bus.branchD   &&  bus.memtoregM == 2'b01 && 
            (bus.writeregM == bus.rsD && bus.writeregM == bus.rtD))begin
                bus.stall_F = 1;
                bus.stall_D = 1;
                bus.flushE  = 1;        
    end
    else begin 
        bus.stall_F = 0;
        bus.stall_D = 0;
        bus.flushE  = 0;
    end

always_comb
    if((bus.rsD != 0 && bus.rsD == bus.writeregM) && bus.regwriteM)begin
        bus.forwardAD = 2'b01;
        bus.forwardBD = 2'b01;
    end
    else begin 
        bus.forwardAD = 0;
        bus.forwardBD = 0;
    end 



endmodule //bypass