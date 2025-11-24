//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 15:10:14
// Design Name: 
// Module Name: karatsuba
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

`define pipe

module kom_pe #(
    parameter PE_WIDTH = 34
)(

    input                           i_clk,
    input                           i_rst_n,

    input   [PE_WIDTH - 1 : 0]      i_pe_in0,
    input   [PE_WIDTH - 1 : 0]      i_pe_in1,
    output  [PE_WIDTH*2 - 1 : 0]    o_pe_out
);

    localparam MUL_IN1 = PE_WIDTH >> 1; 
    localparam MUL_IN3 = PE_WIDTH - MUL_IN1; 
    localparam MUL_IN2 = MUL_IN3 + 1; 

    wire [MUL_IN1 * 2 - 1 : 0]  i_sa_in1;
    wire [MUL_IN2 * 2 - 1 : 0]  i_sa_in2;
    wire [MUL_IN3 * 2 - 1 : 0]  i_sa_in3;

    reg [MUL_IN1 * 2 - 1 : 0]  i_sa_in1_tmp;
    reg [MUL_IN2 * 2 - 1 : 0]  i_sa_in2_tmp;
    reg [MUL_IN3 * 2 - 1 : 0]  i_sa_in3_tmp;

    assign i_sa_in1 = i_pe_in0[MUL_IN3 +: MUL_IN1] * i_pe_in1[MUL_IN3 +: MUL_IN1];
    
    assign i_sa_in2 = (i_pe_in0[MUL_IN3 +: MUL_IN1] + i_pe_in0[0 +: MUL_IN3]) * (i_pe_in1[MUL_IN3 +: MUL_IN1] + i_pe_in1[0 +: MUL_IN3]);

    assign i_sa_in3 = i_pe_in0[0 +: MUL_IN3] * i_pe_in1[0 +: MUL_IN3];


    always @(posedge i_clk or negedge i_rst_n) begin
        if (!i_rst_n)  begin
            i_sa_in1_tmp <= 'b0;
            i_sa_in2_tmp <= 'b0;
            i_sa_in3_tmp <= 'b0;        
        end
        else begin
            i_sa_in1_tmp <= i_sa_in1;
            i_sa_in2_tmp <= i_sa_in2;
            i_sa_in3_tmp <= i_sa_in3;
        end
    end

    Shifer_adder #(
        .WITDH_IN1      (MUL_IN1 * 2),
        .WITDH_IN2      (MUL_IN2 * 2),
        .WITDH_IN3      (MUL_IN3 * 2)
    )u_Shifer_adder(
        .i_sa_in1       (i_sa_in1_tmp),
        .i_sa_in2       (i_sa_in2_tmp),
        .i_sa_in3       (i_sa_in3_tmp),
        .o_sa_out       (o_pe_out) 
    );

endmodule