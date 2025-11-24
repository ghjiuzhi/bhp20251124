`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 
// Design Name: 
// Module Name: CarrySaveAdder
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


module CarrySaveAdder_Complement_15cc#(
	parameter 	DATA_WIDTH		=	256
	)(
        input  [DATA_WIDTH-1 : 0]         Sum_in,
        input  [DATA_WIDTH-2 : 0]         Carry_in,

        output [DATA_WIDTH-1 : 0]           Sum_out,
        output [DATA_WIDTH-1 : 0]           Carry_out
    );

    wire [DATA_WIDTH-3 : 0] Sum_h;
    wire                    Sum_l;
    wire                    Carry;

    assign Sum_h = Sum_in[DATA_WIDTH-1 : 2] ^ Carry_in[DATA_WIDTH-2 : 1];
    assign Sum_l = ~(Sum_in[1]  ^ Carry_in[0]);

    assign Sum_out = {Sum_h, Sum_l, Sum_in[0]};

    assign Carry = (Sum_in[1]) | (Carry_in[0]);
    
    assign Carry_out = {(Sum_in[DATA_WIDTH-1 : 2] & Carry_in[DATA_WIDTH-2 : 1]), Carry, 1'b0};

endmodule

