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


module CarrySaveAdder_15cc#(
	parameter 	DATA_WIDTH		=	256
	)(
        input  [DATA_WIDTH-1 : 0]         A_in,
        input  [DATA_WIDTH-1 : 0]         B_in,
        input  [DATA_WIDTH-1 : 0]         C_in,

        output [DATA_WIDTH-1 : 0]         Sum_out,
        output [DATA_WIDTH-1 : 0]         Carry_out
    );

    assign Sum_out = A_in ^ B_in ^ C_in;
    assign Carry_out = (A_in & B_in) | (A_in & C_in) | (B_in & C_in);

endmodule
