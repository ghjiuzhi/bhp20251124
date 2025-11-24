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


module Shifer_adder #(
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

assign o_sa_out[0 +: REMAND_WIDTH] = i_sa_in3[0 +: REMAND_WIDTH]; 
assign o_sa_out[REMAND_WIDTH +: ADDER_WIDTH] = {i_sa_in1,i_sa_in3[REMAND_WIDTH +: REMAND_WIDTH]} + i_sa_in2 - i_sa_in1 - i_sa_in3;

endmodule