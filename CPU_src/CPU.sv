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

imem mem_instr
	(
		.a  			(bus.imem.pcF[7:2]),
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
		.zero           ()
	);

bypass bypass_i
	(  
        .reset     (reset),
        .clk       (clk),
		.bus       (bus)
	);



endmodule //CPU





