`timescale 1ns / 1ps
`define GFP_DATA_WIDTH 256
// `define INCLUDE_MODULE_PREDATA
`define INCLUDE_MODULE_BROADCAST

module montgomery_add_lookup#(
    parameter P_MOD = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    )(
    input                   clk,
    input                   rstn,

    input   [256 - 1 : 0]   sum_x,
    input   [256 - 1 : 0]   sum_y,
    input   [256 - 1 : 0]   coeff_a,
    input   [256 - 1 : 0]   coeff_b,
    input   [9:0]           MG_j, // 1 2 ... 57; 58 59 ... ; ... 171
    input   [2:0]           bit3,
    input                   bit3_valid,

    output reg                 result_valid,
    output reg [256 - 1 : 0]   result_add_x,
    output reg [256 - 1 : 0]   result_add_y,
    output reg                 lvs_1,             
    output reg [256 - 1 : 0]   lvs_montgomery_y,  
    output reg [256 - 1 : 0]   lvs_bit0and1,      
    output reg [256 - 1 : 0]   lvs_that_y,        
    output reg [256 - 1 : 0]   lvs_lambda,        
    output reg [256 - 1 : 0]   lvs_sum_x,         
    output reg [256 - 1 : 0]   lvs_sum_y,         
    output                     ready,



    output wire [256 - 1 : 0]   top_mul0_a_i         ,
    output wire [256 - 1 : 0]   top_mul0_b_i         ,
    output wire                 top_mul0_ab_valid_i  ,
    input  wire [256 - 1 : 0]   top_mul0_rslt_o      ,
    input  wire                 top_mul0_rslt_valid_o,
    output wire [256 - 1 : 0]   top_inv_a_i          ,
    output wire [256 - 1 : 0]   top_inv_b_i          ,
    output wire                 top_inv_ab_valid_i   ,
    input  wire [256 - 1 : 0]   top_inv_rslt_o       ,
    input  wire                 top_inv_rslt_valid_o ,

    input  wire [32-1:0]i_id,
    input  wire                 i_loop_point,
    input  wire [256 - 1 : 0]   i_x1        ,
    input  wire [256 - 1 : 0]   i_y1        ,
    input  wire [256 - 1 : 0]   i_x2        ,
    input  wire [256 - 1 : 0]   i_y2        ,
    input  wire [256 - 1 : 0]   i_x3        ,
    input  wire [256 - 1 : 0]   i_y3        ,
    input  wire [256 - 1 : 0]   i_x4        ,
    input  wire [256 - 1 : 0]   i_y4        ,
    output wire o_need






    );

reg                 valid_0;
reg                 valid_1;
reg                 valid_2;
reg                 valid_3;
reg                 valid_4;
reg                 valid_5;
reg                 valid_6;
reg [2:0]           reg_bit3;
reg [9:0]           reg_MG_j;
reg [256 - 1 : 0]   reg_sum_x;
reg [256 - 1 : 0]   reg_sum_y;
reg [256 - 1 : 0]   reg_coeff_a;
reg [256 - 1 : 0]   reg_coeff_b;
wire                w_bit0;
wire                w_bit1;
wire                w_bit2;
wire                w_bit0and1;

reg                 reg_ready;

reg [257 - 1:0] montgomery_x;
reg [257 - 1:0] montgomery_y;

reg  [`GFP_DATA_WIDTH-1:0] fas_a_i        ;
reg  [`GFP_DATA_WIDTH-1:0] fas_b_i        ;
reg                        fas_mode_ctrl_i;
wire [`GFP_DATA_WIDTH-1:0] fas_rslt_o     ;

reg            MEM_G123X1_x_ena   ;
reg            MEM_G123X1_y_ena   ;
reg            MEM_G123X2_x_ena   ;
reg            MEM_G123X2_y_ena   ;
reg            MEM_G123X3_x_ena   ;
reg            MEM_G123X3_y_ena   ;
reg            MEM_G123X4_x_ena   ;
reg            MEM_G123X4_y_ena   ;
reg  [7   : 0] MEM_G123X1_x_addra ;
reg  [7   : 0] MEM_G123X1_y_addra ;
reg  [7   : 0] MEM_G123X2_x_addra ;
reg  [7   : 0] MEM_G123X2_y_addra ;
reg  [7   : 0] MEM_G123X3_x_addra ;
reg  [7   : 0] MEM_G123X3_y_addra ;
reg  [7   : 0] MEM_G123X4_x_addra ;
reg  [7   : 0] MEM_G123X4_y_addra ;
wire [255 : 0] MEM_G123X1_x_douta ;
wire [255 : 0] MEM_G123X1_y_douta ;
wire [255 : 0] MEM_G123X2_x_douta ;
wire [255 : 0] MEM_G123X2_y_douta ;
wire [255 : 0] MEM_G123X3_x_douta ;
wire [255 : 0] MEM_G123X3_y_douta ;
wire [255 : 0] MEM_G123X4_x_douta ;
wire [255 : 0] MEM_G123X4_y_douta ;

wire sum_1;

wire  [`GFP_DATA_WIDTH-1:0] ma_this_xp_i      ;
wire  [`GFP_DATA_WIDTH-1:0] ma_this_yp_i      ;
wire  [`GFP_DATA_WIDTH-1:0] ma_that_xp_i      ;
wire  [`GFP_DATA_WIDTH-1:0] ma_that_yp_i      ;
wire  [`GFP_DATA_WIDTH-1:0] ma_coeff_a_i      ;
wire  [`GFP_DATA_WIDTH-1:0] ma_coeff_b_i      ;
wire                        ma_param_valid_i  ;
reg   [`GFP_DATA_WIDTH-1:0] ma_this_xp        ;
reg   [`GFP_DATA_WIDTH-1:0] ma_this_yp        ;
reg   [`GFP_DATA_WIDTH-1:0] ma_that_xp        ;
reg   [`GFP_DATA_WIDTH-1:0] ma_that_yp        ;
reg   [`GFP_DATA_WIDTH-1:0] ma_coeff_a        ;
reg   [`GFP_DATA_WIDTH-1:0] ma_coeff_b        ;
reg                         ma_param_valid    ;

wire [9:0]                       pre_data_G_i_j ; // 1<= J <=171
reg                              pre_data_G_i_v ;
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X1_x; // MEM_G123X1_x_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X1_y; // MEM_G123X1_y_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X2_x; // MEM_G123X2_x_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X2_y; // MEM_G123X2_y_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X3_x; // MEM_G123X3_x_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X3_y; // MEM_G123X3_y_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X4_x; // MEM_G123X4_x_douta,
wire [`GFP_DATA_WIDTH-1:0]       pre_data_G_X4_y; // MEM_G123X4_y_douta,
wire                             pre_data_G_o_v ;

    wire [`GFP_DATA_WIDTH-1:0]       rslt_thaty_o           ;
    wire                             rslt_thaty_tvalid_o    ;
    wire [`GFP_DATA_WIDTH-1:0]       rslt_lambda_o          ;
    wire                             rslt_lambda_tvalid_o   ;
    wire [`GFP_DATA_WIDTH-1:0]       rslt_sumx_o            ;
    wire                             rslt_sumx_tvalid_o     ;
    wire [`GFP_DATA_WIDTH-1:0]       rslt_sumy_o            ;
    wire                             rslt_sumy_tvalid_o     ;
    wire                             rslt_all_tvalid_o      ;

wire [256 - 1 : 0]   t1_mul0_a_i          ,t2_mul0_a_i          ,t3_mul0_a_i          ;
wire [256 - 1 : 0]   t1_mul0_b_i          ,t2_mul0_b_i          ,t3_mul0_b_i          ;
wire                 t1_mul0_ab_valid_i   ,t2_mul0_ab_valid_i   ,t3_mul0_ab_valid_i   ;
wire [256 - 1 : 0]   t1_mul0_rslt_o       ,t2_mul0_rslt_o       ,t3_mul0_rslt_o       ;
wire                 t1_mul0_rslt_valid_o ,t2_mul0_rslt_valid_o ,t3_mul0_rslt_valid_o ;
wire [256 - 1 : 0]   t1_inv_a_i           ,t2_inv_a_i           ,t3_inv_a_i           ;
wire [256 - 1 : 0]   t1_inv_b_i           ,t2_inv_b_i           ,t3_inv_b_i           ;
wire                 t1_inv_ab_valid_i    ,t2_inv_ab_valid_i    ,t3_inv_ab_valid_i    ;
wire [256 - 1 : 0]   t1_inv_rslt_o        ,t2_inv_rslt_o        ,t3_inv_rslt_o        ;
wire                 t1_inv_rslt_valid_o  ,t2_inv_rslt_valid_o  ,t3_inv_rslt_valid_o  ;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 缓存输入数据
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            valid_0 <= 0;
            valid_1 <= 0;
            valid_2 <= 0;
            valid_3 <= 0;
            valid_4 <= 0;
            valid_5 <= 0;
            valid_6 <= 0;
        end else begin
            valid_0 <= bit3_valid && ready;
            valid_1 <= valid_0;
            valid_2 <= valid_1;
            valid_3 <= valid_2;
            // valid_4 <= valid_3;
            valid_4 <= pre_data_G_o_v;
            valid_5 <= valid_4;
            valid_6 <= valid_5;
        end
    end

// bit3_valid
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_bit3    <= 0;
            reg_MG_j    <= 0;
            reg_sum_x   <= 0;
            reg_sum_y   <= 0;
            reg_coeff_a <= 0;
            reg_coeff_b <= 0;
        end else if(bit3_valid && ready)begin
            reg_bit3    <= bit3;
            reg_MG_j    <= MG_j;
            reg_sum_x   <= sum_x;
            reg_sum_y   <= sum_y;
            reg_coeff_a <= coeff_a;
            reg_coeff_b <= coeff_b;
        end else begin
            reg_bit3    <= reg_bit3;
            reg_MG_j    <= reg_MG_j;
            reg_sum_x   <= reg_sum_x;
            reg_sum_y   <= reg_sum_y;
            reg_coeff_a <= reg_coeff_a;
            reg_coeff_b <= reg_coeff_b;
        end
    end

    assign     w_bit0     = reg_bit3[2];
    assign     w_bit1     = reg_bit3[1];
    assign     w_bit2     = reg_bit3[0];
    assign     w_bit0and1 = reg_bit3[2] & reg_bit3[1];

// valid_0 valid_1
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            montgomery_x <= 0;
        // end else if(valid_3)begin
        end else if(pre_data_G_o_v)begin
            // montgomery_x: Field<E> = &x_bases[0]
            //             + &bit_0 * (&x_bases[1] - &x_bases[0])
            //             + &bit_1 * (&x_bases[2] - &x_bases[0])
            //             + &bit_0_and_1 * (&x_bases[3] - &x_bases[2] - &x_bases[1] + &x_bases[0]);
            // if     ((w_bit1 == 0) && (w_bit0 == 0)) montgomery_x <= MEM_G123X1_x_douta; // x_bases0;
            // else if((w_bit1 == 0) && (w_bit0 == 1)) montgomery_x <= MEM_G123X2_x_douta; // x_bases1;
            // else if((w_bit1 == 1) && (w_bit0 == 0)) montgomery_x <= MEM_G123X3_x_douta; // x_bases2;
            // else if((w_bit1 == 1) && (w_bit0 == 1)) montgomery_x <= MEM_G123X4_x_douta; // x_bases3;
            if     ((w_bit1 == 0) && (w_bit0 == 0)) montgomery_x <= pre_data_G_X1_x; // x_bases0;
            else if((w_bit1 == 0) && (w_bit0 == 1)) montgomery_x <= pre_data_G_X2_x; // x_bases1;
            else if((w_bit1 == 1) && (w_bit0 == 0)) montgomery_x <= pre_data_G_X3_x; // x_bases2;
            else if((w_bit1 == 1) && (w_bit0 == 1)) montgomery_x <= pre_data_G_X4_x; // x_bases3;
            else                                    montgomery_x <= montgomery_x;
        end else begin
            montgomery_x <= montgomery_x;
        end
    end
// valid_0 valid_1
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            montgomery_y <= 0;
        // end else if(valid_3)begin
        end else if(pre_data_G_o_v)begin
            // montgomery_y: Field<E> = &x_bases[0]
            //             + &bit_0 * (&x_bases[1] - &x_bases[0])
            //             + &bit_1 * (&x_bases[2] - &x_bases[0])
            //             + &bit_0_and_1 * (&x_bases[3] - &x_bases[2] - &x_bases[1] + &x_bases[0]);
            // if     ((w_bit1 == 0) && (w_bit0 == 0)) montgomery_y <= MEM_G123X1_y_douta; // y_bases0;
            // else if((w_bit1 == 0) && (w_bit0 == 1)) montgomery_y <= MEM_G123X2_y_douta; // y_bases1;
            // else if((w_bit1 == 1) && (w_bit0 == 0)) montgomery_y <= MEM_G123X3_y_douta; // y_bases2;
            // else if((w_bit1 == 1) && (w_bit0 == 1)) montgomery_y <= MEM_G123X4_y_douta; // y_bases3;
            if     ((w_bit1 == 0) && (w_bit0 == 0)) montgomery_y <= pre_data_G_X1_y; // y_bases0;
            else if((w_bit1 == 0) && (w_bit0 == 1)) montgomery_y <= pre_data_G_X2_y; // y_bases1;
            else if((w_bit1 == 1) && (w_bit0 == 0)) montgomery_y <= pre_data_G_X3_y; // y_bases2;
            else if((w_bit1 == 1) && (w_bit0 == 1)) montgomery_y <= pre_data_G_X4_y; // y_bases3;
            else                                    montgomery_y <= montgomery_y;
        end else if(valid_4)begin
            if(w_bit2)
                montgomery_y <= fas_rslt_o; // 0 - montgomery_y
            else
                montgomery_y <= montgomery_y;
        end else begin
            montgomery_y <= montgomery_y;
        end
    end

// valid_0
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            fas_a_i         <= 0;
            fas_b_i         <= 0;
            fas_mode_ctrl_i <= 0;
        // end else if(valid_3)begin
        end else if(pre_data_G_o_v)begin
            fas_a_i         <= 0;
            // fas_b_i         <= montgomery_y;
            if     ((w_bit1 == 0) && (w_bit0 == 0)) fas_b_i <= pre_data_G_X1_y; // y_bases0;
            else if((w_bit1 == 0) && (w_bit0 == 1)) fas_b_i <= pre_data_G_X2_y; // y_bases1;
            else if((w_bit1 == 1) && (w_bit0 == 0)) fas_b_i <= pre_data_G_X3_y; // y_bases2;
            else if((w_bit1 == 1) && (w_bit0 == 1)) fas_b_i <= pre_data_G_X4_y; // y_bases3;
            else                                    fas_b_i <= fas_b_i;
            fas_mode_ctrl_i <= 0;
        end else begin
            fas_a_i         <= fas_a_i        ;
            fas_b_i         <= fas_b_i        ;
            fas_mode_ctrl_i <= fas_mode_ctrl_i;
        end
    end

// valid_0
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X1_x_ena <= 0; else MEM_G123X1_x_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X1_y_ena <= 0; else MEM_G123X1_y_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X2_x_ena <= 0; else MEM_G123X2_x_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X2_y_ena <= 0; else MEM_G123X2_y_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X3_x_ena <= 0; else MEM_G123X3_x_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X3_y_ena <= 0; else MEM_G123X3_y_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X4_x_ena <= 0; else MEM_G123X4_x_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X4_y_ena <= 0; else MEM_G123X4_y_ena <= 1; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X1_x_addra <= 0; else if(valid_0) MEM_G123X1_x_addra <= reg_MG_j - 1; else MEM_G123X1_x_addra <= MEM_G123X1_x_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X1_y_addra <= 0; else if(valid_0) MEM_G123X1_y_addra <= reg_MG_j - 1; else MEM_G123X1_y_addra <= MEM_G123X1_y_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X2_x_addra <= 0; else if(valid_0) MEM_G123X2_x_addra <= reg_MG_j - 1; else MEM_G123X2_x_addra <= MEM_G123X2_x_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X2_y_addra <= 0; else if(valid_0) MEM_G123X2_y_addra <= reg_MG_j - 1; else MEM_G123X2_y_addra <= MEM_G123X2_y_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X3_x_addra <= 0; else if(valid_0) MEM_G123X3_x_addra <= reg_MG_j - 1; else MEM_G123X3_x_addra <= MEM_G123X3_x_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X3_y_addra <= 0; else if(valid_0) MEM_G123X3_y_addra <= reg_MG_j - 1; else MEM_G123X3_y_addra <= MEM_G123X3_y_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X4_x_addra <= 0; else if(valid_0) MEM_G123X4_x_addra <= reg_MG_j - 1; else MEM_G123X4_x_addra <= MEM_G123X4_x_addra; end
    // always @(posedge clk or negedge rstn) begin if(~rstn) MEM_G123X4_y_addra <= 0; else if(valid_0) MEM_G123X4_y_addra <= reg_MG_j - 1; else MEM_G123X4_y_addra <= MEM_G123X4_y_addra; end

// MEM
    // MEM_G123X1_x MEM_G123X1_x (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X1_x_ena   ),      // input wire ena
    //   .addra(MEM_G123X1_x_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X1_x_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X1_y MEM_G123X1_y (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X1_y_ena   ),      // input wire ena
    //   .addra(MEM_G123X1_y_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X1_y_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X2_x MEM_G123X2_x (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X2_x_ena   ),      // input wire ena
    //   .addra(MEM_G123X2_x_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X2_x_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X2_y MEM_G123X2_y (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X2_y_ena   ),      // input wire ena
    //   .addra(MEM_G123X2_y_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X2_y_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X3_x MEM_G123X3_x (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X3_x_ena   ),      // input wire ena
    //   .addra(MEM_G123X3_x_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X3_x_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X3_y MEM_G123X3_y (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X3_y_ena   ),      // input wire ena
    //   .addra(MEM_G123X3_y_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X3_y_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X4_x MEM_G123X4_x (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X4_x_ena   ),      // input wire ena
    //   .addra(MEM_G123X4_x_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X4_x_douta )  // output wire [255 : 0] douta
    // );                                                 
    // MEM_G123X4_y MEM_G123X4_y (
    //   .clka (clk                ),    // input wire clka
    //   .ena  (MEM_G123X4_y_ena   ),      // input wire ena
    //   .addra(MEM_G123X4_y_addra ),  // input wire [7 : 0] addra
    //   .douta(MEM_G123X4_y_douta )  // output wire [255 : 0] douta
    // );                                                 


    bhp_field_add_sub_gfp #(
        .P_MOD(P_MOD)
    ) u_field_add_sub_gfp (
        .fas_a_i        (fas_a_i        ),         
        .fas_b_i        (fas_b_i        ),         
        .fas_mode_ctrl_i(fas_mode_ctrl_i),         
        .fas_rslt_o     (fas_rslt_o     )          
    );
// valid_2


// PREDATA
assign pre_data_G_i_j = reg_MG_j;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        pre_data_G_i_v <= 0;
    end else if(valid_3)begin
        pre_data_G_i_v <= 1;
    end else begin
        pre_data_G_i_v <= 0;
    end
end

`ifdef INCLUDE_MODULE_PREDATA
pre_data_3p pre_data_3p(
        .clk    (clk                ),
        .rstn   (rstn               ),
        .G_i_j  (pre_data_G_i_j     ),
        .G_i_v  (pre_data_G_i_v     ),
        .G_X1_x (pre_data_G_X1_x    ),
        .G_X1_y (pre_data_G_X1_y    ),
        .G_X2_x (pre_data_G_X2_x    ),
        .G_X2_y (pre_data_G_X2_y    ),
        .G_X3_x (pre_data_G_X3_x    ),
        .G_X3_y (pre_data_G_X3_y    ),
        .G_X4_x (pre_data_G_X4_x    ),
        .G_X4_y (pre_data_G_X4_y    ),
        .G_o_v  (pre_data_G_o_v     ),
        .top_mul0_a_i                 (t1_mul0_a_i         ),
        .top_mul0_b_i                 (t1_mul0_b_i         ),
        .top_mul0_ab_valid_i          (t1_mul0_ab_valid_i  ),
        .top_mul0_rslt_o              (t1_mul0_rslt_o      ),
        .top_mul0_rslt_valid_o        (t1_mul0_rslt_valid_o),
        .top_inv_a_i                  (t1_inv_a_i          ),
        .top_inv_b_i                  (t1_inv_b_i          ),
        .top_inv_ab_valid_i           (t1_inv_ab_valid_i   ),
        .top_inv_rslt_o               (t1_inv_rslt_o       ),
        .top_inv_rslt_valid_o         (t1_inv_rslt_valid_o)
    );
`elsif INCLUDE_MODULE_BROADCAST
    assign o_need = pre_data_G_i_v;
    assign pre_data_G_X1_x = i_x1;
    assign pre_data_G_X1_y = i_y1;
    assign pre_data_G_X2_x = i_x2;
    assign pre_data_G_X2_y = i_y2;
    assign pre_data_G_X3_x = i_x3;
    assign pre_data_G_X3_y = i_y3;
    assign pre_data_G_X4_x = i_x4;
    assign pre_data_G_X4_y = i_y4;
    assign pre_data_G_o_v  = i_loop_point&&(i_id == (pre_data_G_i_j - 1));
    assign t1_mul0_a_i          = 0;
    assign t1_mul0_b_i          = 0;
    assign t1_mul0_ab_valid_i   = 0;
    // assign t1_mul0_rslt_o       = 0;
    // assign t1_mul0_rslt_valid_o = 0;
    assign t1_inv_a_i           = 0;
    assign t1_inv_b_i           = 0;
    assign t1_inv_ab_valid_i    = 0;
    // assign t1_inv_rslt_o        = 0;
    // assign t1_inv_rslt_valid_o  = 0;
`else
pre_data_3p pre_data_3p(
        .clk    (clk                ),
        .rstn   (rstn               ),
        .G_i_j  (pre_data_G_i_j     ),
        .G_i_v  (pre_data_G_i_v     ),
        .G_X1_x (pre_data_G_X1_x    ),
        .G_X1_y (pre_data_G_X1_y    ),
        .G_X2_x (pre_data_G_X2_x    ),
        .G_X2_y (pre_data_G_X2_y    ),
        .G_X3_x (pre_data_G_X3_x    ),
        .G_X3_y (pre_data_G_X3_y    ),
        .G_X4_x (pre_data_G_X4_x    ),
        .G_X4_y (pre_data_G_X4_y    ),
        .G_o_v  (pre_data_G_o_v     ),
        .top_mul0_a_i                 (t1_mul0_a_i         ),
        .top_mul0_b_i                 (t1_mul0_b_i         ),
        .top_mul0_ab_valid_i          (t1_mul0_ab_valid_i  ),
        .top_mul0_rslt_o              (t1_mul0_rslt_o      ),
        .top_mul0_rslt_valid_o        (t1_mul0_rslt_valid_o),
        .top_inv_a_i                  (t1_inv_a_i          ),
        .top_inv_b_i                  (t1_inv_b_i          ),
        .top_inv_ab_valid_i           (t1_inv_ab_valid_i   ),
        .top_inv_rslt_o               (t1_inv_rslt_o       ),
        .top_inv_rslt_valid_o         (t1_inv_rslt_valid_o)
    );
`endif


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

//             ((reg_MG_j == 10'd1) || (reg_MG_j == 10'd57 + 1) || (reg_MG_j == 10'd114 + 1) || (reg_MG_j == 10'd171 + 1)) ? 1 : 0;
//             ((reg_MG_j == 10'd1) || (reg_MG_j == 10'd58    ) || (reg_MG_j == 10'd115    ) || (reg_MG_j == 10'd172    )) ? 1 : 0;
assign sum_1 = ((reg_MG_j == 10'd1) || (reg_MG_j == 10'd58    ) || (reg_MG_j == 10'd115    ) || (reg_MG_j == 10'd172    )) ? 1 : 0;




// ma_this_xp
// ma_this_yp
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ma_this_xp <= 0;
            ma_this_yp <= 0;
        end else if(valid_6 && sum_1)begin 
            ma_this_xp <= 0;
            ma_this_yp <= 0;
        end else if(valid_6 && (~sum_1))begin 
            ma_this_xp <= reg_sum_x;
            ma_this_yp <= reg_sum_y;
        end else begin
            ma_this_xp <= ma_this_xp;
            ma_this_yp <= ma_this_yp;
        end
    end

// ma_that_xp
// ma_that_yp
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ma_that_xp <= 0;
            ma_that_yp <= 0;
        end else if(valid_6 && sum_1)begin    
            ma_that_xp <= 0;
            ma_that_yp <= 0;
        end else if(valid_6 && (~sum_1))begin 
            ma_that_xp <= montgomery_x;
            ma_that_yp <= montgomery_y;
        end else begin
            ma_that_xp <= ma_that_xp;
            ma_that_yp <= ma_that_yp;
        end
    end

// ma_coeff_a
// ma_coeff_b
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ma_coeff_a <= 0;
            ma_coeff_b <= 0;
        end else if(valid_6 && sum_1)begin    
            ma_coeff_a <= reg_coeff_a;
            ma_coeff_b <= reg_coeff_b;
        end else if(valid_6 && (~sum_1))begin 
            ma_coeff_a <= reg_coeff_a;
            ma_coeff_b <= reg_coeff_b;
        end else begin
            ma_coeff_a <= ma_coeff_a;
            ma_coeff_b <= ma_coeff_b;
        end
    end

// ma_param_valid
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ma_param_valid <= 0;
        end else if(valid_6 && sum_1)begin   
            ma_param_valid <= 0;
        end else if(valid_6 && (~sum_1))begin
            ma_param_valid <= 1;
        end else begin
            ma_param_valid <= 0;
        end
    end

// montgomery_add
    assign  ma_this_xp_i     = ma_this_xp     ;
    assign  ma_this_yp_i     = ma_this_yp     ;
    assign  ma_that_xp_i     = ma_that_xp     ;
    assign  ma_that_yp_i     = ma_that_yp     ;
    assign  ma_coeff_a_i     = ma_coeff_a     ;
    assign  ma_coeff_b_i     = ma_coeff_b     ;
    assign  ma_param_valid_i = ma_param_valid ;
    montgomery_add #(
        .P_MOD(P_MOD)
    ) u_montgomery_add (
        .pm_clk_i               (clk               ),
        .pm_rstn_i              (rstn              ),
        .this_xp_i              (ma_this_xp_i      ),
        .this_yp_i              (ma_this_yp_i      ),
        .that_xp_i              (ma_that_xp_i      ),
        .that_yp_i              (ma_that_yp_i      ),
        .coeff_a_i              (ma_coeff_a_i      ),
        .coeff_b_i              (ma_coeff_b_i      ),
        .pm_param_tvalid_i      (ma_param_valid_i  ),

        .rslt_thaty_o           (rslt_thaty_o           ),
        .rslt_thaty_tvalid_o    (rslt_thaty_tvalid_o    ),
        .rslt_lambda_o          (rslt_lambda_o          ),
        .rslt_lambda_tvalid_o   (rslt_lambda_tvalid_o   ),
        .rslt_sumx_o            (rslt_sumx_o            ),
        .rslt_sumx_tvalid_o     (rslt_sumx_tvalid_o     ),
        .rslt_sumy_o            (rslt_sumy_o            ),
        .rslt_sumy_tvalid_o     (rslt_sumy_tvalid_o     ),
        .rslt_all_tvalid_o      (rslt_all_tvalid_o      ),
        .pm_tready_o            (pm_tready_o            ),


        .top_mul0_a_i                 (t2_mul0_a_i            ),
        .top_mul0_b_i                 (t2_mul0_b_i            ),
        .top_mul0_ab_valid_i          (t2_mul0_ab_valid_i     ),
        .top_mul0_rslt_o              (t2_mul0_rslt_o         ),
        .top_mul0_rslt_valid_o        (t2_mul0_rslt_valid_o   ),
        .top_inv_a_i                  (t2_inv_a_i             ),
        .top_inv_b_i                  (t2_inv_b_i             ),
        .top_inv_ab_valid_i           (t2_inv_ab_valid_i      ),
        .top_inv_rslt_o               (t2_inv_rslt_o          ),
        .top_inv_rslt_valid_o         (t2_inv_rslt_valid_o    )
    );




// assign top_mul0_a_i          = (t1_mul0_ab_valid_i & t1_mul0_a_i)|(t2_mul0_ab_valid_i & t2_mul0_a_i);
// assign top_mul0_b_i          = (t1_mul0_ab_valid_i & t1_mul0_b_i)|(t2_mul0_ab_valid_i & t2_mul0_b_i);
assign top_mul0_a_i          = ({256{t1_mul0_ab_valid_i}} & t1_mul0_a_i)|({256{t2_mul0_ab_valid_i}} & t2_mul0_a_i);
assign top_mul0_b_i          = ({256{t1_mul0_ab_valid_i}} & t1_mul0_b_i)|({256{t2_mul0_ab_valid_i}} & t2_mul0_b_i);
assign top_mul0_ab_valid_i   = t1_mul0_ab_valid_i || t2_mul0_ab_valid_i;
assign t1_mul0_rslt_o        = top_mul0_rslt_o;
assign t2_mul0_rslt_o        = top_mul0_rslt_o;
assign t1_mul0_rslt_valid_o  = top_mul0_rslt_valid_o;
assign t2_mul0_rslt_valid_o  = top_mul0_rslt_valid_o;

// assign top_inv_a_i           = (t1_inv_ab_valid_i & t1_inv_a_i)|(t2_inv_ab_valid_i & t2_inv_a_i);
// assign top_inv_b_i           = (t1_inv_ab_valid_i & t1_inv_b_i)|(t2_inv_ab_valid_i & t2_inv_b_i);
assign top_inv_a_i           = ({256{t1_inv_ab_valid_i}} & t1_inv_a_i)|({256{t2_inv_ab_valid_i}} & t2_inv_a_i);
assign top_inv_b_i           = ({256{t1_inv_ab_valid_i}} & t1_inv_b_i)|({256{t2_inv_ab_valid_i}} & t2_inv_b_i);
assign top_inv_ab_valid_i    = t1_inv_ab_valid_i || t2_inv_ab_valid_i;
assign t1_inv_rslt_o         = top_inv_rslt_o;
assign t2_inv_rslt_o         = top_inv_rslt_o;
assign t3_inv_rslt_o         = top_inv_rslt_o;
assign t1_inv_rslt_valid_o   = top_inv_rslt_valid_o;
assign t2_inv_rslt_valid_o   = top_inv_rslt_valid_o;
assign t3_inv_rslt_valid_o   = top_inv_rslt_valid_o;











/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// result_valid
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            result_valid <= 0;
        end else if(valid_6 && sum_1)begin 
            result_valid <= 1;
        end else if(rslt_all_tvalid_o)begin
            result_valid <= 1;
        end else begin
            result_valid <= 0;
        end
    end

// result_add_x
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            result_add_x <= 0;
        end else if(valid_6 && sum_1)begin   
            result_add_x <= montgomery_x;
        end else if(rslt_sumx_tvalid_o)begin 
            result_add_x <= rslt_sumx_o;//rslt_sumx_o
        end else begin
            result_add_x <= result_add_x;
        end
    end

// result_add_y
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            result_add_y <= 0;
        end else if(valid_6 && sum_1)begin   
            result_add_y <= montgomery_y;
        end else if(rslt_sumy_tvalid_o)begin 
            result_add_y <= rslt_sumy_o;
        end else begin
            result_add_y <= result_add_y;
        end
    end

// lvs_1
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            lvs_1 <= 0;
        end else if(valid_6 && sum_1)begin 
            lvs_1 <= 1;
        end else begin
            lvs_1 <= 0;
        end
    end

// lvs_montgomery_y
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            lvs_montgomery_y <= 0;
        end else if(valid_6 && sum_1)begin 
            lvs_montgomery_y <= montgomery_y;
        end else begin
            lvs_montgomery_y <= lvs_montgomery_y;
        end
    end

// lvs_bit0and1
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            lvs_bit0and1 <= 0;
        end else if(valid_6 && sum_1)begin 
            lvs_bit0and1 <= w_bit0and1;
        end else if(rslt_all_tvalid_o)begin
            lvs_bit0and1 <= w_bit0and1;
        end else begin
            lvs_bit0and1 <= lvs_bit0and1;
        end
    end

// lvs_that_y
    always @(posedge clk or negedge rstn)if(~rstn)lvs_that_y<=0;else if(rslt_thaty_tvalid_o )lvs_that_y<=rslt_thaty_o ;else lvs_that_y<=lvs_that_y;
// lvs_lambda
    always @(posedge clk or negedge rstn)if(~rstn)lvs_lambda<=0;else if(rslt_lambda_tvalid_o)lvs_lambda<=rslt_lambda_o;else lvs_lambda<=lvs_lambda;
// lvs_sum_x
    always @(posedge clk or negedge rstn)if(~rstn)lvs_sum_x <=0;else if(rslt_sumx_tvalid_o  )lvs_sum_x <=rslt_sumx_o  ;else lvs_sum_x <=lvs_sum_x ;
// lvs_sum_y
    always @(posedge clk or negedge rstn)if(~rstn)lvs_sum_y <=0;else if(rslt_sumy_tvalid_o  )lvs_sum_y <=rslt_sumy_o  ;else lvs_sum_y <=lvs_sum_y ;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ready
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign ready = reg_ready;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        reg_ready <= 1;
    end else if(result_valid)begin
        reg_ready <= 1;
    end else if(bit3_valid)begin
        reg_ready <= 0;
    end else begin
        reg_ready <= reg_ready;
    end
end










// pm_tready_o


endmodule










