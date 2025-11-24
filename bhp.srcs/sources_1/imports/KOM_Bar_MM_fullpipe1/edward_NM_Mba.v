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
module edward_NM_Mba #(
    parameter R_WIDTH = 256
)(
    input                           i_clk,
    input                           i_rst_n,
    input                           i_vld,
    input      [R_WIDTH - 1 : 0]    i_T,
    output reg                      o_vld,
    output reg [2*R_WIDTH - 1 : 0]  o_s
);

reg                     i_vld_d0;
reg                     i_vld_d1;
reg                     i_vld_d2;

reg [R_WIDTH +  19 : 0] o_PAT_part0;
reg [R_WIDTH +  30 : 0] o_PAT_part1;
reg [R_WIDTH +  48 : 0] o_PAT_part2;
reg [R_WIDTH +  66 : 0] o_PAT_part3;
reg [R_WIDTH +  85 : 0] o_PAT_part4;
reg [R_WIDTH + 115 : 0] o_PAT_part5;  
reg [R_WIDTH + 133 : 0] o_PAT_part6;
reg [R_WIDTH + 149 : 0] o_PAT_part7;
reg [R_WIDTH + 163 : 0] o_PAT_part8;
reg [R_WIDTH + 178 : 0] o_PAT_part9;
reg [R_WIDTH + 199 : 0] o_PAT_part10;
reg [R_WIDTH + 220 : 0] o_PAT_part11;
reg [R_WIDTH + 240 : 0] o_PAT_part12;
reg [R_WIDTH + 255 : 0] o_PAT_part13;

reg [R_WIDTH + 50 : 0]  o_PAT_reg1;
reg [R_WIDTH + 117 : 0] o_PAT_reg2;
reg [R_WIDTH + 165 : 0] o_PAT_reg3;
reg [R_WIDTH + 222 : 0] o_PAT_reg4;
reg [R_WIDTH + 257 : 0] o_PAT_reg5;

reg [R_WIDTH +  44 : 0] o_NAT_part0;
reg [R_WIDTH +  79 : 0] o_NAT_part1;
reg [R_WIDTH +  97 : 0] o_NAT_part2;
reg [R_WIDTH + 157 : 0] o_NAT_part3;
reg [R_WIDTH + 194 : 0] o_NAT_part4;
reg [R_WIDTH + 212 : 0] o_NAT_part5;
reg [R_WIDTH + 247 : 0] o_NAT_part6;
reg [R_WIDTH + 253 : 0] o_NAT_part7;

reg [R_WIDTH + 159 : 0] o_NAT_reg1;
reg [R_WIDTH + 255 : 0] o_NAT_reg2;

reg [2*R_WIDTH - 1 : 0] Negative_adder_rslt;
reg [2*R_WIDTH - 1 : 0] Positive_adder_rslt;


// Positive Adder: 
// [3, 5, 11, 17, 
// 23, 26, 28, 30, 
// 34, 39, 46, 48, 
// 55, 58, 60, 66, 
// 73, 75, 83, 85, 
// 94,  102, 111, 115, 
// 117, 122, 130, 133, 
// 136, 138, 140, 149, 
// 151, 153, 155, 163, 
// 165, 168, 175, 178, 
// 180, 186, 188, 199, 
// 201, 208, 214, 220, 
// 231, 234, 237, 240, 
// 242]
// Positive Adder: 
// [1, 3, 9, 15, 
// 21, 24, 26, 28, 
// 32, 37, 44, 46, 
// 53, 56, 58, 64, 
// 71, 73, 81, 83, 
// 92,  100, 109, 113, 
// 115, 120, 128, 131, 
// 134, 136, 138, 147, 
// 149, 151, 153, 161, 
// 163, 166, 173, 176, 
// 178, 184, 186, 197, 
// 199, 206, 212, 218, 
// 229, 232, 235, 238, 
// 240, 254]
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
        o_PAT_part8 <= 'b0;
        o_PAT_part9 <= 'b0;
        o_PAT_part10<= 'b0;
        o_PAT_part11<= 'b0;
        o_PAT_part12<= 'b0;
        o_PAT_part13<= 'b0;
    end
    else if (i_vld) begin
        o_PAT_part0 <= ((i_T <<   1) + (i_T <<   3) + (i_T <<   9) + (i_T <<  15));
        o_PAT_part1 <= ((i_T <<  21) + (i_T <<  24) + (i_T <<  26) + (i_T <<  28));
        o_PAT_part2 <= ((i_T <<  32) + (i_T <<  37) + (i_T <<  44) + (i_T <<  46));
        o_PAT_part3 <= ((i_T <<  53) + (i_T <<  56) + (i_T <<  58) + (i_T <<  64));
        o_PAT_part4 <= ((i_T <<  71) + (i_T <<  73) + (i_T <<  81) + (i_T <<  83));
        o_PAT_part5 <= ((i_T <<  92) + (i_T << 100) + (i_T << 109) + (i_T << 113));
        o_PAT_part6 <= ((i_T << 115) + (i_T << 120) + (i_T << 128) + (i_T << 131));
        o_PAT_part7 <= ((i_T << 134) + (i_T << 136) + (i_T << 138) + (i_T << 147));
        o_PAT_part8 <= ((i_T << 149) + (i_T << 151) + (i_T << 153) + (i_T << 161));
        o_PAT_part9 <= ((i_T << 163) + (i_T << 166) + (i_T << 173) + (i_T << 176));
        o_PAT_part10<= ((i_T << 178) + (i_T << 184) + (i_T << 186) + (i_T << 197));
        o_PAT_part11<= ((i_T << 199) + (i_T << 206) + (i_T << 212) + (i_T << 218));
        o_PAT_part12<= ((i_T << 229) + (i_T << 232) + (i_T << 235) + (i_T << 238));
        o_PAT_part13<= ((i_T << 240) + (i_T << 254));
    end 
end      


always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_PAT_reg1 <= 'b0;
        o_PAT_reg2 <= 'b0;
        o_PAT_reg3 <= 'b0;
        o_PAT_reg4 <= 'b0;
        o_PAT_reg5 <= 'b0;
    end
    else if (i_vld_d0) begin
        o_PAT_reg1 <= o_PAT_part0 + o_PAT_part1 + o_PAT_part2;
        o_PAT_reg2 <= o_PAT_part3 + o_PAT_part4 + o_PAT_part5;
        o_PAT_reg3 <= o_PAT_part6 + o_PAT_part7 + o_PAT_part8;
        o_PAT_reg4 <= o_PAT_part9 + o_PAT_part10 + o_PAT_part11;
        o_PAT_reg5 <= o_PAT_part12 + o_PAT_part13;
    end 
end    


// Negative Adder: 
// [7, 13, 19, 44, 
// 62, 69, 71, 79, 
// 87, 89, 91, 97, 
// 100, 109, 124, 157,
//  171, 183, 191, 194, 
//  204, 206, 210, 212, 
//  224, 226, 245, 247, 
//  250, 253]
// [5, 11, 17, 42, 
// 60, 67, 69, 77, 
// 85, 87, 89, 95, 
//  98,  107,  122, 155, 
// 169, 181, 189, 192, 
// 202, 204, 208, 210, 
// 222, 224, 243, 245, 
// 248, 251]
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
    end
    else if (i_vld) begin
        o_NAT_part0 <= ((i_T <<   5) + (i_T <<  11) + (i_T <<  17) + (i_T <<  42));
        o_NAT_part1 <= ((i_T <<  60) + (i_T <<  67) + (i_T <<  69) + (i_T <<  77));
        o_NAT_part2 <= ((i_T <<  85) + (i_T <<  87) + (i_T <<  89) + (i_T <<  95));
        o_NAT_part3 <= ((i_T <<  98) + (i_T << 107) + (i_T << 122) + (i_T << 155));
        o_NAT_part4 <= ((i_T << 169) + (i_T << 181) + (i_T << 189) + (i_T << 192));
        o_NAT_part5 <= ((i_T << 202) + (i_T << 204) + (i_T << 208) + (i_T << 210));
        o_NAT_part6 <= ((i_T << 222) + (i_T << 224) + (i_T << 243) + (i_T << 245));
        o_NAT_part7 <= ((i_T << 248) + (i_T << 251));        
    end          
end


always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_NAT_reg1 <= 'b0;
        o_NAT_reg2 <= 'b0;
    end
    else if (i_vld_d0) begin
        o_NAT_reg1 <= o_NAT_part0 + o_NAT_part1 + o_NAT_part2 + o_NAT_part3;
        o_NAT_reg2 <= o_NAT_part4 + o_NAT_part5 + o_NAT_part6 + o_NAT_part7;
    end 
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        Positive_adder_rslt <= 'b0;
        Negative_adder_rslt <= 'b0;
    end
    else if (i_vld_d1) begin
        Positive_adder_rslt <= o_PAT_reg1 + o_PAT_reg2 + o_PAT_reg3 + o_PAT_reg4 + o_PAT_reg5;
        Negative_adder_rslt <= o_NAT_reg1 + o_NAT_reg2;
    end 
end    

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        o_s <= 1'b0;
    end
    else if (i_vld_d2)begin
        o_s <= Positive_adder_rslt - Negative_adder_rslt;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        i_vld_d0 <= 1'b0;
        i_vld_d1 <= 1'b0;
        i_vld_d2 <= 1'b0;
        o_vld    <= 1'b0;
    end
    else begin
        i_vld_d0 <= i_vld;
        i_vld_d1 <= i_vld_d0;
        i_vld_d2 <= i_vld_d1;
        o_vld    <= i_vld_d2;
    end
end

endmodule