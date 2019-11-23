//`timescale 1 ns

module tb ();

	wire [13:0] din;
	wire vin;
	wire rst_n;
	wire clk;
	wire [153:0] b;
	wire [13:0] dout;
	wire vout;
	wire endsim;
	
	fir DUT(
		.DIN(din),
		.VIN(vin),
		.RST_n(rst_n),
		.CLK(clk),
		.b(b),
		.DOUT(dout),
		.VOUT(vout)
		);

	data_maker data_maker_inst(
		.CLK(clk),
		.RST_n(rst_n),
		.VOUT(vin),
		.DOUT(din),
		.B(b),
		.END_SIM(endsim)
	);
	
	data_sink data_sink_inst(
		.CLK(clk),
		.RST_n(rst_n),
		.VIN(vout),
		.DIN(dout)
	);
	
	clk_gen clk_gen_inst(
		.END_SIM(endsim),
		.CLK(clk),
		.RST_n(rst_n)
	);

endmodule
   
