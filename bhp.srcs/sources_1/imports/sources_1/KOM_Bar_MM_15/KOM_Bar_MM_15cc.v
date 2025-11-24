`timescale 1ns / 1ps
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

module KOM_Bar_MM_15cc #(
    parameter MUL_WIDTH = 256
)(
    input                               clk,
    input                               rstn,
    input                               i_vld,
    input       [MUL_WIDTH - 1 : 0]     i_a,
    input       [MUL_WIDTH - 1 : 0]     i_b,

    output                              o_rslt_vld,
    output      [MUL_WIDTH - 4 : 0]     o_rslt
);

localparam PRIME_P          =  256'h12ab_655e_9a2c_a556_60b4_4d1e_5c37_b001_59aa_76fe_d000_0001_0a11_8000_0000_0001;
// parameter P_MOD              = 256'h12ab_655e_9a2c_a556_60b4_4d1e_5c37_b001_59aa_76fe_d000_0001_0a11_8000_0000_0001;

localparam DELTA            =  256'h36d9_491e_c40b_2c9e_e4e5_1e49_faa8_0548_fd0a_180b_8d69_e258_f520_4c21_151e_79ea;





wire [MUL_WIDTH - 1 : 0]                KOM_A_i;
wire [MUL_WIDTH - 1 : 0]                KOM_B_i;
wire [2*MUL_WIDTH - 1 : 0]              KOM_C_o;
wire                                    KOM_VLD_i;
wire                                    KOM_VLD_o;

wire                                    STATE_MRES;
wire                                    STATE_MMAG;
wire                                    STATE_MPRI;


reg  [14:0]                             state_ctl;
reg  [MUL_WIDTH-1 : 0]                  T_reg;

wire [MUL_WIDTH - 3 : 0]                rslt_0;
wire [MUL_WIDTH - 3 : 0]                rslt_1;

always @(posedge clk or negedge rstn) begin
    if(!rstn)
        state_ctl   <=  15'h1;
    else if (state_ctl[14])
        state_ctl   <=  15'h1;
    else if (i_vld)
        state_ctl   <=  15'h2;
    else if (!state_ctl[0])
        state_ctl   <=  {state_ctl[13:0],state_ctl[14]};
    else
        state_ctl   <=  state_ctl;
end


assign STATE_MRES = |state_ctl[4:0];
assign STATE_MMAG = |state_ctl[9:5];
assign STATE_MPRI = |state_ctl[14:10];


assign KOM_A_i = STATE_MPRI ? KOM_C_o[MUL_WIDTH * 2 - 1 : MUL_WIDTH] :
                    (STATE_MMAG ? KOM_C_o[MUL_WIDTH * 2 - 7 : MUL_WIDTH-6] :
                                    i_a);

assign KOM_B_i = STATE_MPRI ? PRIME_P:
                    (STATE_MMAG ? DELTA:
                                    i_b);

assign KOM_VLD_i = STATE_MRES ?  i_vld : KOM_VLD_o;



assign rslt_0 = KOM_C_o[MUL_WIDTH - 3 : 0];
assign rslt_1 = rslt_0 - PRIME_P;
assign o_rslt = rslt_1[MUL_WIDTH - 3] ? rslt_0[MUL_WIDTH - 4 : 0]   :   rslt_1[MUL_WIDTH - 4 : 0];
assign o_rslt_vld = STATE_MRES & KOM_VLD_o;


always @(posedge clk or negedge rstn) begin
    if(!rstn)
        T_reg   <=  'h0;
    else if (STATE_MMAG & KOM_VLD_o)
        T_reg   <=  KOM_C_o[MUL_WIDTH-1 : 0];
    else 
        T_reg   <=  T_reg;
end



//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------
// Underlying Caculation Modules
//-----------------------------------------------------------------------------
karasuba_mul_15cc #(
        .MUL_WIDTH  (MUL_WIDTH)
    )
    u_karasuba_mul
    (
        .i_clk      (clk),
        .i_rst_n    (rstn),
        .i_vld      (KOM_VLD_i),
        .i_A        (KOM_A_i),
        .i_B        (KOM_B_i),

        .i_T        (T_reg),
        .i_MPRI_en  (STATE_MPRI),

        .o_C        (KOM_C_o),
        .o_vld      (KOM_VLD_o)
    );

//-----------------------------------------------------------------------------
//end of Underlying Caculation Modules
//-----------------------------------------------------------------------------
//-----------------------------------------------------------------------------





endmodule
