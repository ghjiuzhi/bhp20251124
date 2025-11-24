//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/07/01 16:55:31
// Design Name: 
// Module Name: kom_level2
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


module karasuba_mul #(
    parameter MUL_WIDTH = 256
)(
    input                               i_clk,
    input                               i_rst_n,
    input                               i_vld,
    input   [MUL_WIDTH - 1 : 0]         i_A,
    input   [MUL_WIDTH - 1 : 0]         i_B,
    output  [MUL_WIDTH * 2 - 1 : 0]     o_C,
    output                              o_vld
);

localparam L1_H_WIDTH = MUL_WIDTH >> 1;                     //64
localparam L1_L_WIDTH = MUL_WIDTH - L1_H_WIDTH;             //64
localparam L1_M_WIDTH = L1_L_WIDTH + 1;                     //65

localparam L2_H_WIDTH_L1H = L1_H_WIDTH >> 1;                //32
localparam L2_L_WIDTH_L1H = L1_H_WIDTH - L2_H_WIDTH_L1H;    //33
localparam L2_M_WIDTH_L1H = L2_L_WIDTH_L1H + 1;             //32

localparam L2_H_WIDTH_L1M = L1_M_WIDTH >> 1;                //32
localparam L2_L_WIDTH_L1M = L1_M_WIDTH - L2_H_WIDTH_L1M;    //34
localparam L2_M_WIDTH_L1M = L2_L_WIDTH_L1M + 1;             //33

localparam L2_H_WIDTH_L1L = L1_L_WIDTH >> 1;                //32
localparam L2_L_WIDTH_L1L = L1_L_WIDTH - L2_H_WIDTH_L1L;    //33
localparam L2_M_WIDTH_L1L = L2_L_WIDTH_L1L + 1;             //32

reg                                 i_vld_d0;
reg                                 i_vld_d1;
reg                                 i_vld_d2;
reg                                 i_vld_d3;

wire [L1_M_WIDTH - 1 : 0]           Ah_add_Al;
wire [L1_M_WIDTH - 1 : 0]           Bh_add_Bl;

wire [L2_M_WIDTH_L1H - 1 : 0]       Ahh_add_Ahl;
wire [L2_M_WIDTH_L1H - 1 : 0]       Bhh_add_Bhl;

wire [L2_M_WIDTH_L1L - 1 : 0]       Alh_add_All;
wire [L2_M_WIDTH_L1L - 1 : 0]       Blh_add_Bll;

wire [L2_M_WIDTH_L1M - 1 : 0]       AhaddAlh_add_AhaddAll;
wire [L2_M_WIDTH_L1M - 1 : 0]       BhaddBlh_add_BhaddBll;

wire [L2_H_WIDTH_L1H * 2 - 1 : 0]   pe1_out;
wire [L2_M_WIDTH_L1H * 2 - 1 : 0]   pe2_out;
wire [L2_L_WIDTH_L1H * 2 - 1 : 0]   pe3_out;

wire [L2_H_WIDTH_L1M * 2 - 1 : 0]   pe4_out;
wire [L2_M_WIDTH_L1M * 2 - 1 : 0]   pe5_out;
wire [L2_L_WIDTH_L1M * 2 - 1 : 0]   pe6_out;

wire [L2_H_WIDTH_L1L * 2 - 1 : 0]   pe7_out;
wire [L2_M_WIDTH_L1L * 2 - 1 : 0]   pe8_out;
wire [L2_L_WIDTH_L1L * 2 - 1 : 0]   pe9_out;

reg  [L2_H_WIDTH_L1H * 2 - 1 : 0]   blk1_sa_in1;    
reg  [L2_M_WIDTH_L1H * 2 - 1 : 0]   blk1_sa_in2;    
reg  [L2_L_WIDTH_L1H * 2 - 1 : 0]   blk1_sa_in3;
wire [L1_H_WIDTH *  2 - 1: 0]       blk1_sa_out;

reg  [L2_H_WIDTH_L1M * 2 - 1 : 0]   blk2_sa_in1;    
reg  [L2_M_WIDTH_L1M * 2 - 1 : 0]   blk2_sa_in2;    
reg  [L2_L_WIDTH_L1M * 2 - 1 : 0]   blk2_sa_in3;
wire [L1_M_WIDTH * 2 - 1 : 0]       blk2_sa_out;

reg  [L2_H_WIDTH_L1L * 2 - 1 : 0]   blk3_sa_in1;    
reg  [L2_M_WIDTH_L1L * 2 - 1 : 0]   blk3_sa_in2;    
reg  [L2_L_WIDTH_L1L * 2 - 1 : 0]   blk3_sa_in3;
wire [L1_L_WIDTH * 2 - 1 : 0]       blk3_sa_out;

wire [MUL_WIDTH * 2 - 1 : 0]        blk4_sa_out; 

reg  [MUL_WIDTH * 2 - 1 : 0]        o_tmp_reg;

reg [L1_H_WIDTH * 2 - 1 : 0]        blk1_sa_out_tmp;
reg [L1_M_WIDTH * 2 - 1 : 0]        blk2_sa_out_tmp;
reg [L1_L_WIDTH * 2 - 1 : 0]        blk3_sa_out_tmp;

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        i_vld_d0 <= 1'b0;
        i_vld_d1 <= 1'b0;
        i_vld_d2 <= 1'b0;
        i_vld_d3 <= 1'b0;
    end
    else begin
        i_vld_d0 <= i_vld;
        i_vld_d1 <= i_vld_d0;
        i_vld_d2 <= i_vld_d1;
        i_vld_d3 <= i_vld_d2;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        blk1_sa_in1 <= 'b0;
        blk1_sa_in2 <= 'b0;
        blk1_sa_in3 <= 'b0;
        blk2_sa_in1 <= 'b0;
        blk2_sa_in2 <= 'b0;
        blk2_sa_in3 <= 'b0;
        blk3_sa_in1 <= 'b0;
        blk3_sa_in2 <= 'b0;
        blk3_sa_in3 <= 'b0;
    end
    else if (i_vld_d0)begin
        blk1_sa_in1 <= pe1_out;
        blk1_sa_in2 <= pe2_out;
        blk1_sa_in3 <= pe3_out;
        blk2_sa_in1 <= pe4_out;
        blk2_sa_in2 <= pe5_out;
        blk2_sa_in3 <= pe6_out;
        blk3_sa_in1 <= pe7_out;
        blk3_sa_in2 <= pe8_out;
        blk3_sa_in3 <= pe9_out;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) begin
        blk1_sa_out_tmp <= 'b0;
        blk2_sa_out_tmp <= 'b0;
        blk3_sa_out_tmp <= 'b0;
    end
    else if (i_vld_d1)begin
        blk1_sa_out_tmp <= blk1_sa_out;
        blk2_sa_out_tmp <= blk2_sa_out;
        blk3_sa_out_tmp <= blk3_sa_out;
    end
end

always @(posedge i_clk or negedge i_rst_n) begin
    if (!i_rst_n) 
        o_tmp_reg <= 'b0;
    else if (i_vld_d2)
        o_tmp_reg <= blk4_sa_out;
end

assign o_vld = i_vld_d3;
assign o_C = o_tmp_reg;

assign Ah_add_Al   = i_A[L1_L_WIDTH +: L1_H_WIDTH] + i_A[0 +: L1_L_WIDTH];
assign Bh_add_Bl   = i_B[L1_L_WIDTH +: L1_H_WIDTH] + i_B[0 +: L1_L_WIDTH];

assign Ahh_add_Ahl = i_A[L1_L_WIDTH + L2_L_WIDTH_L1H +: L2_H_WIDTH_L1H] + i_A[L1_L_WIDTH +: L2_L_WIDTH_L1H];
assign Bhh_add_Bhl = i_B[L1_L_WIDTH + L2_L_WIDTH_L1H +: L2_H_WIDTH_L1H] + i_B[L1_L_WIDTH +: L2_L_WIDTH_L1H];

assign Alh_add_All = i_A[L2_L_WIDTH_L1L +: L2_H_WIDTH_L1L] + i_A[0 +: L2_L_WIDTH_L1L];
assign Blh_add_Bll = i_B[L2_L_WIDTH_L1L +: L2_H_WIDTH_L1L] + i_B[0 +: L2_L_WIDTH_L1L];

assign AhaddAlh_add_AhaddAll = Ah_add_Al[L2_L_WIDTH_L1M +: L2_H_WIDTH_L1M] + Ah_add_Al[0 +: L2_L_WIDTH_L1M];
assign BhaddBlh_add_BhaddBll = Bh_add_Bl[L2_L_WIDTH_L1M +: L2_H_WIDTH_L1M] + Bh_add_Bl[0 +: L2_L_WIDTH_L1M];

// kom for block 1
kom_pe #(
    .PE_WIDTH       (L2_H_WIDTH_L1H)
)u_pe_1(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (i_A[L1_L_WIDTH + L2_L_WIDTH_L1H +: L2_H_WIDTH_L1H]),
    .i_pe_in1       (i_B[L1_L_WIDTH + L2_L_WIDTH_L1H +: L2_H_WIDTH_L1H]),
    .o_pe_out       (pe1_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_M_WIDTH_L1H)
)u_pe_2(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (Ahh_add_Ahl),
    .i_pe_in1       (Bhh_add_Bhl),
    .o_pe_out       (pe2_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_L_WIDTH_L1H)
)u_pe_3(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (i_A[L1_L_WIDTH +: L2_L_WIDTH_L1H]),
    .i_pe_in1       (i_B[L1_L_WIDTH +: L2_L_WIDTH_L1H]),
    .o_pe_out       (pe3_out) 
);

// kom for block 2
kom_pe #(
    .PE_WIDTH       (L2_H_WIDTH_L1M)
)u_pe_4(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (Ah_add_Al[L2_L_WIDTH_L1M +: L2_H_WIDTH_L1M]),
    .i_pe_in1       (Bh_add_Bl[L2_L_WIDTH_L1M +: L2_H_WIDTH_L1M]),
    .o_pe_out       (pe4_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_M_WIDTH_L1M)
)u_pe_5(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (AhaddAlh_add_AhaddAll),
    .i_pe_in1       (BhaddBlh_add_BhaddBll),
    .o_pe_out       (pe5_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_L_WIDTH_L1M)
)u_pe_6(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (Ah_add_Al[0 +: L2_L_WIDTH_L1M]),
    .i_pe_in1       (Bh_add_Bl[0 +: L2_L_WIDTH_L1M]),
    .o_pe_out       (pe6_out) 
);

// kom for block 3
kom_pe #(
    .PE_WIDTH       (L2_H_WIDTH_L1L)
)u_pe_7(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (i_A[L2_L_WIDTH_L1L +: L2_H_WIDTH_L1L]),
    .i_pe_in1       (i_B[L2_L_WIDTH_L1L +: L2_H_WIDTH_L1L]),
    .o_pe_out       (pe7_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_M_WIDTH_L1L)
)u_pe_8(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (Alh_add_All),
    .i_pe_in1       (Blh_add_Bll),
    .o_pe_out       (pe8_out) 
);

kom_pe #(
    .PE_WIDTH       (L2_L_WIDTH_L1L)
)u_pe_9(
    .i_clk          (i_clk),
    .i_rst_n        (i_rst_n),
    .i_pe_in0       (i_A[0 +: L2_L_WIDTH_L1L]),
    .i_pe_in1       (i_B[0 +: L2_L_WIDTH_L1L]),
    .o_pe_out       (pe9_out) 
);

Shifer_adder #(
    .WITDH_IN1      (L2_H_WIDTH_L1H*2),
    .WITDH_IN2      (L2_M_WIDTH_L1H*2),
    .WITDH_IN3      (L2_L_WIDTH_L1H*2)
) u_blk1 (
    .i_sa_in1       (blk1_sa_in1),
    .i_sa_in2       (blk1_sa_in2),
    .i_sa_in3       (blk1_sa_in3),
    .o_sa_out       (blk1_sa_out) 
);

Shifer_adder #(
    .WITDH_IN1      (L2_H_WIDTH_L1M*2),
    .WITDH_IN2      (L2_M_WIDTH_L1M*2),
    .WITDH_IN3      (L2_L_WIDTH_L1M*2)
) u_blk2 (
    .i_sa_in1       (blk2_sa_in1),
    .i_sa_in2       (blk2_sa_in2),
    .i_sa_in3       (blk2_sa_in3),
    .o_sa_out       (blk2_sa_out) 
);

Shifer_adder #(
    .WITDH_IN1      (L2_H_WIDTH_L1L*2),
    .WITDH_IN2      (L2_M_WIDTH_L1L*2),
    .WITDH_IN3      (L2_L_WIDTH_L1L*2)
) u_blk3 (
    .i_sa_in1       (blk3_sa_in1),
    .i_sa_in2       (blk3_sa_in2),
    .i_sa_in3       (blk3_sa_in3),
    .o_sa_out       (blk3_sa_out) 
);

Shifer_adder #(
    .WITDH_IN1      (L1_H_WIDTH*2),
    .WITDH_IN2      (L1_M_WIDTH*2),
    .WITDH_IN3      (L1_L_WIDTH*2)
) u_blk4 (
    .i_sa_in1       (blk1_sa_out_tmp),
    .i_sa_in2       (blk2_sa_out_tmp),
    .i_sa_in3       (blk3_sa_out_tmp),
    .o_sa_out       (blk4_sa_out) 
);


endmodule