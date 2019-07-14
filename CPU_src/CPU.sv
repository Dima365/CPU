module CPU
(
	input  logic reset,
	input  logic clk,

	output logic [31:0] writedata, 
	output logic [31:0] aluout,
	output logic memwrite
);

main_bus bus
	(
		.reset      (reset),
		.clk 		(clk)
	);


controller ctrl
  	(
  		.op  			(bus.controller.instrD[31:26]),
  		.funct		    (bus.controller.instrD[5:0]),

        .int_cause      (bus.controller.int_cause),
        .cause_write    (bus.controller.cause_write),
        .exit_kernel    (bus.controller.exit_kernel),
        .jump_reg       (bus.controller.jump_regD),
        .overflow       (bus.controller.overflowE),
        .kernel_mode    (bus.controller.kernel_mode),
        .write_c0       (bus.controller.write_c0D),

  		.regwrite  		(bus.controller.regwriteD),
  		.memtoreg  		(bus.controller.memtoregD),
  		.memwrite		(bus.controller.memwriteD),
  		.alucontrol		(bus.controller.alucontrolD),
  		.alusrc			(bus.controller.alusrcD),
  		.regdst			(bus.controller.regdstD),
  		.branch			(bus.controller.branchD),
        .jump           (bus.controller.jumpD),
  		.zero			()
  	);


coprocessor_0 c0 
    (
        .reset          (bus.reset),
        .clk            (bus.clk),

        .write_c0W      (bus.coprocessor_0.write_c0W),
        .resultW        (bus.coprocessor_0.resultW),
        .writeregW      (bus.coprocessor_0.writeregW),

        .pcF            (bus.coprocessor_0.pcF),
        .int_cause      (bus.coprocessor_0.int_cause),
        .cause_write    (bus.coprocessor_0.cause_write),

        .rtD            (bus.coprocessor_0.rtD),

        .c0D            (bus.coprocessor_0.c0D),
        .kernel_mode    (bus.coprocessor_0.kernel_mode),
        .exit_kernel    (bus.coprocessor_0.exit_kernel) 
    );


imem mem_instr
	(
		.a  			(bus.imem.pcF[31:2]),
		.rd             (bus.imem.instrF)
	);

assign writedata = bus.dmem.writedataM;
assign aluout    = bus.dmem.aluoutM;
assign memwrite  = bus.dmem.memwriteM;

dmem mem_data
	(
		.clk   			(bus.clk),
		.we             (bus.dmem.memwriteM),
		.a 				(bus.dmem.aluoutM),
		.wd				(bus.dmem.writedataM),
		.rd             (bus.dmem.readdataM)
	);	

regfile rf
	(
		.clk 			(bus.clk),
        .reset          (bus.reset),
		.we3			(bus.regfile.regwriteW),
		.ra1			(bus.regfile.instrD[25:21]),
		.ra2			(bus.regfile.instrD[20:16]),
		.wa3			(bus.regfile.writeregW),
		.wd3			(bus.regfile.resultW),
		.rd1            (bus.regfile.rd1D),
		.rd2            (bus.regfile.rd2D)
	);

alu alu_i
	(
		.a           	(bus.srcAE),
		.b              (bus.srcBE),
		.alucontrol     (bus.alucontrolE),
		.result         (bus.aluoutE),
        .overflow       (bus.overflowE),
		.zero           ()
	);



endmodule //CPU





