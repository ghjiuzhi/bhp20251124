//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/03 15:24:18
// Design Name: 
// Module Name: NM1
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
module fp_edward_NM_M #(
    parameter R_WIDTH = 256
)(
    input                           i_clk,
    input                           i_rst_n,
    input                           i_vld,
    input      [R_WIDTH - 1 : 0]    i_s,
    output reg                      o_vld,
    output reg [2*R_WIDTH - 1 : 0]  o_t
);

reg                     i_vld_d0;
reg                     i_vld_d1;

//-------------Positive part -------------------//
reg [R_WIDTH +  57 : 0] o_PAT_part0;
reg [R_WIDTH + 111 : 0] o_PAT_part1;
reg [R_WIDTH + 121 : 0] o_PAT_part2;
reg [R_WIDTH + 165 : 0] o_PAT_part3;
reg [R_WIDTH + 178 : 0] o_PAT_part4;
reg [R_WIDTH + 205 : 0] o_PAT_part5;
reg [R_WIDTH + 221 : 0] o_PAT_part6;
reg [R_WIDTH + 252 : 0] o_PAT_part7;

reg [R_WIDTH + 167 : 0] o_PAT_reg1;
reg [R_WIDTH + 254 : 0] o_PAT_reg2;

//-------------Nagetive part -------------------//
reg [R_WIDTH + 104 : 0] o_NAT_part0;
reg [R_WIDTH + 125 : 0] o_NAT_part1;
reg [R_WIDTH + 147 : 0] o_NAT_part2;
reg [R_WIDTH + 170 : 0] o_NAT_part3;
reg [R_WIDTH + 193 : 0] o_NAT_part4;

reg [R_WIDTH + 201 : 0] o_NAT_part5;
reg [R_WIDTH + 225 : 0] o_NAT_part6;
reg [R_WIDTH + 237 : 0] o_NAT_part7;
reg [R_WIDTH + 248 : 0] o_NAT_part8;

reg [R_WIDTH + 195 : 0] o_NAT_reg1;
reg [R_WIDTH + 250 : 0] o_NAT_reg2;

reg [2*R_WIDTH - 1 : 0] Negative_adder_rslt;
reg [2*R_WIDTH - 1 : 0] Positive_adder_rslt;

//Positive Adder: 
//[  0,  49,  52,  57, 
//  59,  64,  92, 111,
// 113, 115, 117, 121,
// 129, 150, 159, 165,
// 168, 172, 174, 178,
// 184, 191, 203, 205,
// 207, 214, 217, 221,
// 223, 235, 250, 252]

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_PAT_part0 <= 'b0;
        o_PAT_part1 <= 'b0;
        o_PAT_part2 <= 'b0;
        o_PAT_part3 <= 'b0;
        o_PAT_part4 <= 'b0;
        o_PAT_part5 <= 'b0;
        o_PAT_part6 <= 'b0;
        o_PAT_part7 <= 'b0;
    end
    else if (i_vld) begin
        o_PAT_part0 <= ((i_s <<   0) + (i_s <<  49) + (i_s <<  52) + (i_s <<  57));
        o_PAT_part1 <= ((i_s <<  59) + (i_s <<  64) + (i_s <<  92) + (i_s << 111));
        o_PAT_part2 <= ((i_s << 113) + (i_s << 115) + (i_s << 117) + (i_s << 121));
        o_PAT_part3 <= ((i_s << 129) + (i_s << 150) + (i_s << 159) + (i_s << 165));
        o_PAT_part4 <= ((i_s << 168) + (i_s << 172) + (i_s << 174) + (i_s << 178));
        o_PAT_part5 <= ((i_s << 184) + (i_s << 191) + (i_s << 203) + (i_s << 205));
        o_PAT_part6 <= ((i_s << 207) + (i_s << 214) + (i_s << 217) + (i_s << 221));
        o_PAT_part7 <= ((i_s << 223) + (i_s << 235) + (i_s << 250) + (i_s << 252));
    end 
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_PAT_reg1 <= 'b0;
        o_PAT_reg2 <= 'b0;
    end
    else if (i_vld_d0) begin
        o_PAT_reg1 <= o_PAT_part0 + o_PAT_part1 + o_PAT_part2 + o_PAT_part3;
        o_PAT_reg2 <= o_PAT_part4 + o_PAT_part5 + o_PAT_part6 + o_PAT_part7;
    end
end

//Negative Adder: 
//[ 47,  94,  96, 104,
// 107, 119, 123, 125,
// 127, 140, 142, 147,
// 154, 157, 161, 170,
// 180, 182, 189, 193,
// 195, 197, 199, 201,
// 210, 212, 219, 225,
// 229, 231, 233, 237,
// 239, 242, 244, 246, 248]

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_NAT_part0 <= 'b0;
        o_NAT_part1 <= 'b0;
        o_NAT_part2 <= 'b0;
        o_NAT_part3 <= 'b0;
        o_NAT_part4 <= 'b0;
        o_NAT_part5 <= 'b0;
        o_NAT_part6 <= 'b0;
        o_NAT_part7 <= 'b0;
        o_NAT_part8 <= 'b0;
    end
    else if (i_vld) begin
        o_NAT_part0 <= ((i_s <<  47) + (i_s <<  94) + (i_s <<  96) + (i_s << 104));
        o_NAT_part1 <= ((i_s << 107) + (i_s << 119) + (i_s << 123) + (i_s << 125));
        o_NAT_part2 <= ((i_s << 127) + (i_s << 140) + (i_s << 142) + (i_s << 147));
        o_NAT_part3 <= ((i_s << 154) + (i_s << 157) + (i_s << 161) + (i_s << 170));
        o_NAT_part4 <= ((i_s << 180) + (i_s << 182) + (i_s << 189) + (i_s << 193));
        o_NAT_part5 <= ((i_s << 195) + (i_s << 197) + (i_s << 199) + (i_s << 201));
        o_NAT_part6 <= ((i_s << 210) + (i_s << 212) + (i_s << 219) + (i_s << 225));
        o_NAT_part7 <= ((i_s << 229) + (i_s << 231) + (i_s << 233) + (i_s << 237));
        o_NAT_part8 <= ((i_s << 239) + (i_s << 242) + (i_s << 244) + (i_s << 246) + (i_s << 248));
    end          
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_NAT_reg1 <= 'b0;
        o_NAT_reg2 <= 'b0;
    end
    else if (i_vld_d0) begin
        o_NAT_reg1 <= o_NAT_part0 + o_NAT_part1 + o_NAT_part2 + o_NAT_part3 + o_NAT_part4;
        o_NAT_reg2 <= o_NAT_part5 + o_NAT_part6 + o_NAT_part7 + o_NAT_part8;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_t <= 1'b0;
    end
    else if (i_vld_d1)begin
        o_t <= o_PAT_reg1 + o_PAT_reg2 - o_NAT_reg1 - o_NAT_reg2;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        i_vld_d0 <= 1'b0;
        i_vld_d1 <= 1'b0;
        o_vld    <= 1'b0;
    end
    else begin
        i_vld_d0 <= i_vld;
        i_vld_d1 <= i_vld_d0;
        o_vld    <= i_vld_d1;
    end
end

endmodule