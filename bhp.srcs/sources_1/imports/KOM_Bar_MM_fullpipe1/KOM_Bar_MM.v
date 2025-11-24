//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:    Damon
// 
// Create Date: 2024/08/31 23:54:57
// Design Name: 
// Module Name: KOM_Bar_MM
// Project Name: Barret Modular Multiplier Based on Karatsuba-Ofman Multiplication
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
// `define MM_SIM

module KOM_Bar_MM #(
    parameter MUL_WIDTH = 256
)(
    input                               clk,
    input                               rstn,
    input                               i_vld,
    input       [MUL_WIDTH - 1 : 0]     i_a,
    input       [MUL_WIDTH - 1 : 0]     i_b,

`ifdef MM_SIM
    output      [MUL_WIDTH*2 - 1 : 0]   o_T,
    output      [MUL_WIDTH - 1 : 0]     o_d,
    output      [MUL_WIDTH - 4 : 0]     o_Q,
`endif

    output reg                          o_rslt_vld,
    output      [MUL_WIDTH - 4 : 0]     o_rslt
);

localparam PRIME_P          =  253'h12ab_655e_9a2c_a556_60b4_4d1e_5c37_b001_59aa_76fe_d000_0001_0a11_8000_0000_0001;

wire [2*MUL_WIDTH - 1 : 0]              T;
wire                                    T_vld;
wire [2*MUL_WIDTH - 1 : 0]              s;
wire                                    s_vld;
wire [2*MUL_WIDTH - 1 : 0]              st;
wire                                    st_vld;

reg  [MUL_WIDTH - 3 : 0]                rslt_0;
wire [MUL_WIDTH - 3 : 0]                rslt_1;

reg  [2*MUL_WIDTH - 1 : 0]              T_d0;
reg  [2*MUL_WIDTH - 1 : 0]              T_d1;
reg  [2*MUL_WIDTH - 1 : 0]              T_d2;
reg  [2*MUL_WIDTH - 1 : 0]              T_d3;
reg  [2*MUL_WIDTH - 1 : 0]              T_d4;
reg  [2*MUL_WIDTH - 1 : 0]              T_d5;
reg  [2*MUL_WIDTH - 1 : 0]              T_d6;


always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        T_d0 <= 1'b0;
        T_d1 <= 1'b0;
        T_d2 <= 1'b0;
        T_d3 <= 1'b0;
        T_d4 <= 1'b0;
        T_d5 <= 1'b0;
        T_d6 <= 1'b0;
    end 
    else begin
        T_d0 <= T;
        T_d1 <= T_d0;
        T_d2 <= T_d1;
        T_d3 <= T_d2;
        T_d4 <= T_d3;
        T_d5 <= T_d4;
        T_d6 <= T_d5;
    end
end

edward_NM_Mba #(
    .R_WIDTH (MUL_WIDTH)
)u_edward_NM_Mba(
    .i_clk                      (clk),
    .i_rst_n                    (rstn),
    .i_vld                      (T_vld),
    // .i_T                        (T[MUL_WIDTH-1:0]),
    .i_T                        (T[MUL_WIDTH * 2 - 7 : MUL_WIDTH-6]),
    .o_vld                      (s_vld),
    .o_s                        (s)
);

edward_NM_M #(
    .R_WIDTH (MUL_WIDTH)
)u_edward_NM_M(
    .i_clk                      (clk),
    .i_rst_n                    (rstn),
    .i_vld                      (s_vld),
    .i_s                        (s[MUL_WIDTH * 2 - 1 : MUL_WIDTH]),
    .o_vld                      (st_vld),
    .o_t                        (st)
);

// assign rslt_0 = T_d6[MUL_WIDTH - 3 : 0] - st[MUL_WIDTH - 3 : 0];


always @(posedge clk or negedge rstn) begin
    if (!rstn) begin
        rslt_0 <= 0;
    end
    else if (st_vld) begin
        rslt_0 <= T_d6[MUL_WIDTH - 3 : 0] - st[MUL_WIDTH - 3 : 0];
    end
	else begin
		rslt_0 <= rslt_0;
	end
end
assign rslt_1 = rslt_0 - PRIME_P;
assign o_rslt = rslt_1[MUL_WIDTH - 3] ? rslt_0[MUL_WIDTH - 4 : 0]   :   rslt_1[MUL_WIDTH - 4 : 0];

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            o_rslt_vld <= 1'b0;
        end
        else begin
            o_rslt_vld <= st_vld;
        end
    end

    karasuba_mul #(
        .MUL_WIDTH  (MUL_WIDTH)
    )
    u_karasuba_mul
    (
        .i_clk      (clk),
        .i_rst_n    (rstn),
        .i_vld      (i_vld),
        .i_A        (i_a),
        .i_B        (i_b),
        .o_C        (T),
        .o_vld      (T_vld)
    );


`ifdef MM_SIM
    assign  o_T = T;
    assign  o_d = s[2*MUL_WIDTH - 1 : MUL_WIDTH];
    assign  o_Q = st[252:0];
`endif

endmodule

