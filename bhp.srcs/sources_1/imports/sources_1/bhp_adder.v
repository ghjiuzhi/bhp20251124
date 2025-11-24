`timescale      1ns/1ns

`define GFP_DATA_WIDTH 256

module bhp_adder(
	input wire [`GFP_DATA_WIDTH-1:0]			add_a_i,
	input wire [`GFP_DATA_WIDTH-1:0]			add_b_i,
	
	output reg [`GFP_DATA_WIDTH:0]				add_rslt_o
	);

	always @ ( * ) 
	begin
		add_rslt_o = add_a_i + add_b_i;
	end


endmodule
