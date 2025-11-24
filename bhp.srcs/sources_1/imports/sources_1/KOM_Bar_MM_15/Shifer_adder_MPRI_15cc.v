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


module Shifer_adder_MPRI_15cc #(
    parameter WITDH_IN0 = 256,
    parameter WITDH_IN1 = 256,
    parameter WITDH_IN2 = 256,
    parameter WITDH_IN3 = 256
)(
    input [WITDH_IN0 - 1 : 0]               i_T,
    input [WITDH_IN1 - 1 : 0]               i_sa_in1,
    input [WITDH_IN2 - 1 : 0]               i_sa_in2,
    input [WITDH_IN3 - 1 : 0]               i_sa_in3,
    output[WITDH_IN0 - 1 : 0]               o_rout
);

localparam REMAND_WIDTH = WITDH_IN3 >> 1;
localparam ADDER_WIDTH  = WITDH_IN1 + WITDH_IN3 - REMAND_WIDTH; 



wire [ADDER_WIDTH-1 : 0]                A;
wire [ADDER_WIDTH-1 : 0]                B;
wire [ADDER_WIDTH-1 : 0]                C;
wire [ADDER_WIDTH-1 : 0]                D;
wire [WITDH_IN0-1 : 0]                  CSA0_5T1_A;
wire [WITDH_IN0-1 : 0]                  CSA0_5T1_B;
wire [WITDH_IN0-1 : 0]                  CSA0_5T1_C;
wire [WITDH_IN0-1 : 0]                  CSA0_5T1_D;
wire [WITDH_IN0-1 : 0]                  CSA0_5T1_E;
wire                                    CSA0_sub2_en;
wire [WITDH_IN0-1 : 0]                CSA0_S;

// assign o_sa_out[0 +: REMAND_WIDTH] = i_sa_in3[0 +: REMAND_WIDTH]; 
// assign o_sa_out[REMAND_WIDTH +: ADDER_WIDTH] = {i_sa_in1,i_sa_in3[REMAND_WIDTH +: REMAND_WIDTH]} + i_sa_in2 - i_sa_in1 - i_sa_in3;


assign A =  {i_sa_in1,i_sa_in3[REMAND_WIDTH +: REMAND_WIDTH]};
assign B =  {{(ADDER_WIDTH-WITDH_IN2){1'b0}}, i_sa_in2};
assign C =  {{(ADDER_WIDTH-WITDH_IN1){1'b0}}, i_sa_in1};
assign D =  {{(ADDER_WIDTH-WITDH_IN3){1'b0}}, i_sa_in3};

// wire [511 : 0]                t0;

// assign t0[REMAND_WIDTH +: ADDER_WIDTH] = A+B+C+D+2;
// assign t0[0 +: REMAND_WIDTH] = i_sa_in3[0 +: REMAND_WIDTH]; 
// assign o_rout = i_T - t0[WITDH_IN0 - 1 : 0];



assign CSA0_5T1_A = ~{A[WITDH_IN0-REMAND_WIDTH-1 : 0], i_sa_in3[REMAND_WIDTH-1: 0]};
assign CSA0_5T1_B = ~{B[WITDH_IN0-REMAND_WIDTH-1 : 0], {REMAND_WIDTH{1'b0}}};
assign CSA0_5T1_C =  {C[WITDH_IN0-REMAND_WIDTH-1 : 0], {REMAND_WIDTH{1'b0}}};
assign CSA0_5T1_D =  {D[WITDH_IN0-REMAND_WIDTH-1 : 0], {REMAND_WIDTH{1'b0}}};
assign CSA0_5T1_E = i_T;

// assign o_rout = CSA0_5T1_A + CSA0_5T1_B + CSA0_5T1_C + CSA0_5T1_D + CSA0_5T1_E + 2;

CSA_5T1_15cc#(
	.DATA_WIDTH     (WITDH_IN0)
	)
    u0_CSA_5T1(
        .A_in       (CSA0_5T1_A),
        .B_in       (CSA0_5T1_B),
        .C_in       (CSA0_5T1_C),
        .D_in       (CSA0_5T1_D),
        .E_in       (CSA0_5T1_E),

        .sub2_en_in (1'b1),

        .S_out      (CSA0_S)
    );
assign o_rout = CSA0_S;



endmodule
