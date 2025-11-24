`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20230403
// Design Name: 
// Module Name: CSA_4T1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module CSA_4T1_15cc#(
	parameter 	DATA_WIDTH		=	256
	)(
        input   [DATA_WIDTH-1 : 0]          A_in,
        input   [DATA_WIDTH-1 : 0]          B_in,
        input   [DATA_WIDTH-1 : 0]          C_in,
        input   [DATA_WIDTH-1 : 0]          D_in,

        input                               sub2_en_in,

        output  [DATA_WIDTH-1 : 0]          S_out
    );

wire [DATA_WIDTH-1 : 0]     CSA0_A_in;
wire [DATA_WIDTH-1 : 0]     CSA0_B_in;
wire [DATA_WIDTH-1 : 0]     CSA0_C_in;
wire [DATA_WIDTH-1 : 0]     CSA0_Sum_out;
wire [DATA_WIDTH-1 : 0]     CSA0_Carry_out;

wire [DATA_WIDTH-1 : 0]     CSA1_A_in;
wire [DATA_WIDTH-1 : 0]     CSA1_B_in;
wire [DATA_WIDTH-1 : 0]     CSA1_C_in;
wire [DATA_WIDTH-1 : 0]     CSA1_Sum_out;
wire [DATA_WIDTH-1 : 0]     CSA1_Carry_out;

wire [DATA_WIDTH-1 : 0]     CSA2_Sum_in;
wire [DATA_WIDTH-2 : 0]     CSA2_Carry_in;
wire [DATA_WIDTH-1 : 0]     CSA2_Sum_out;
wire [DATA_WIDTH-1 : 0]     CSA2_Carry_out;

wire [DATA_WIDTH-1 : 0]     Adder_A_in;
wire [DATA_WIDTH-1 : 0]     Adder_B_in;
wire [DATA_WIDTH : 0]       Adder_S_out;

assign CSA0_A_in = A_in;
assign CSA0_B_in = B_in;
assign CSA0_C_in = C_in;

assign CSA1_A_in = CSA0_Sum_out;
assign CSA1_B_in = {CSA0_Carry_out[DATA_WIDTH-2:0],1'b0};
assign CSA1_C_in = D_in;

assign CSA2_Sum_in      = CSA1_Sum_out;
assign CSA2_Carry_in    = CSA1_Carry_out[DATA_WIDTH-2 : 0];

assign Adder_A_in = sub2_en_in ? CSA2_Sum_out                               :   CSA1_Sum_out;
assign Adder_B_in = sub2_en_in ? {CSA2_Carry_out[DATA_WIDTH-2 : 0], 1'b0}   :   {CSA1_Carry_out,1'b0};

assign S_out = Adder_S_out[DATA_WIDTH-1 : 0];

CarrySaveAdder_15cc#(
	.DATA_WIDTH         (DATA_WIDTH)
    )
    u0_CSA(
        .A_in           (CSA0_A_in),
        .B_in           (CSA0_B_in),
        .C_in           (CSA0_C_in),

        .Sum_out        (CSA0_Sum_out),
        .Carry_out      (CSA0_Carry_out)
    );
CarrySaveAdder_15cc#(
	.DATA_WIDTH         (DATA_WIDTH)
    )
    u1_CSA(
        .A_in           (CSA1_A_in),
        .B_in           (CSA1_B_in),
        .C_in           (CSA1_C_in),

        .Sum_out        (CSA1_Sum_out),
        .Carry_out      (CSA1_Carry_out)
    );

CarrySaveAdder_Complement_15cc#(
	.DATA_WIDTH         (DATA_WIDTH)
	)
    u_CSA_Complement(
        .Sum_in         (CSA2_Sum_in),
        .Carry_in       (CSA2_Carry_in),

        .Sum_out        (CSA2_Sum_out),
        .Carry_out      (CSA2_Carry_out)
    );

Full_Adder_15cc#(
	.DATA_WIDTH         (DATA_WIDTH)
	)
    u_Full_Adder(
        .A_in           (Adder_A_in),
        .B_in           (Adder_B_in),

        .S_out          (Adder_S_out)
    );
endmodule
