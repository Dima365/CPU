module test_CPU ();

logic reset;
logic clk;

CPU DUT
	(
		.reset	(reset),
		.clk	(clk)
	);

initial begin 
	reset = 0;
	clk   = 0;

	#50 reset = 1;
	#35 reset = 0;

	#3000 $stop; 
end

always
	#20 clk = ~clk;

endmodule // test_CPU