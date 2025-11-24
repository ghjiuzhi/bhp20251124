`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20230403
// Design Name: 
// Module Name: Full_Adder
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


module Full_Adder_15cc#(
	parameter 	DATA_WIDTH		=	256
	)(
        input   [DATA_WIDTH-1 : 0]          A_in,
        input   [DATA_WIDTH-1 : 0]          B_in,

        output  [DATA_WIDTH : 0]            S_out
    );

assign S_out = A_in + B_in;

endmodule
