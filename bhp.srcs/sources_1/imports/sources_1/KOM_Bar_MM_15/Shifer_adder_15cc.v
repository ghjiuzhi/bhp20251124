`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 19:15:42
// Design Name: 
// Module Name: Shifer_adder
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


module Shifer_adder_15cc #(
    parameter WITDH_IN1 = 64,
    parameter WITDH_IN2 = 68,
    parameter WITDH_IN3 = 66
)(
    input [WITDH_IN1 - 1 : 0]               i_sa_in1,
    input [WITDH_IN2 - 1 : 0]               i_sa_in2,
    input [WITDH_IN3 - 1 : 0]               i_sa_in3,
    output[WITDH_IN1 + WITDH_IN3 - 1 : 0]   o_sa_out 
);

localparam REMAND_WIDTH = WITDH_IN3 >> 1;
localparam ADDER_WIDTH  = WITDH_IN1 + WITDH_IN3 - REMAND_WIDTH; 



wire [ADDER_WIDTH-1 : 0]                CSA0_4T1_A;
wire [ADDER_WIDTH-1 : 0]                CSA0_4T1_B;
wire [ADDER_WIDTH-1 : 0]                CSA0_4T1_C;
wire [ADDER_WIDTH-1 : 0]                CSA0_4T1_D;
wire                                    CSA0_sub2_en;
wire [ADDER_WIDTH-1 : 0]                CSA0_S;

// assign o_sa_out[0 +: REMAND_WIDTH] = i_sa_in3[0 +: REMAND_WIDTH]; 
// assign o_sa_out[REMAND_WIDTH +: ADDER_WIDTH] = {i_sa_in1,i_sa_in3[REMAND_WIDTH +: REMAND_WIDTH]} + i_sa_in2 - i_sa_in1 - i_sa_in3;


assign CSA0_4T1_A = {i_sa_in1,i_sa_in3[REMAND_WIDTH +: REMAND_WIDTH]};
assign CSA0_4T1_B = {{(ADDER_WIDTH-WITDH_IN2){1'b0}}, i_sa_in2};
assign CSA0_4T1_C = ~{{(ADDER_WIDTH-WITDH_IN1){1'b0}}, i_sa_in1};
assign CSA0_4T1_D = ~{{(ADDER_WIDTH-WITDH_IN3){1'b0}}, i_sa_in3};


CSA_4T1_15cc#(
	.DATA_WIDTH     (ADDER_WIDTH)
	)
    u0_CSA_4T1(
        .A_in       (CSA0_4T1_A),
        .B_in       (CSA0_4T1_B),
        .C_in       (CSA0_4T1_C),
        .D_in       (CSA0_4T1_D),

        .sub2_en_in (1'b1),

        .S_out      (CSA0_S)
    );

// wire [WITDH_IN1 + WITDH_IN3 - 1 : 0]   tt; 
// assign CSA0_S = CSA0_4T1_A + CSA0_4T1_B + CSA0_4T1_C + CSA0_4T1_D + 2;
assign o_sa_out[0 +: REMAND_WIDTH] = i_sa_in3[0 +: REMAND_WIDTH]; 
assign o_sa_out[REMAND_WIDTH +: ADDER_WIDTH] = CSA0_S;


endmodule
