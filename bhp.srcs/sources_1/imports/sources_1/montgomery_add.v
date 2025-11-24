`timescale 1ns / 1ps 
`define GFP_DATA_WIDTH 256


module montgomery_add#(
    parameter P_MOD = {`GFP_DATA_WIDTH{1'b1}}
    )
    (
    input wire                              pm_clk_i,
    input wire                              pm_rstn_i,
    //domain parameters for an elliptic curve scheme
    //the following input signals must be synchronous to the pm_clk_i
    input wire [`GFP_DATA_WIDTH-1:0]        this_xp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        this_yp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        that_xp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        that_yp_i,
    input wire [`GFP_DATA_WIDTH-1:0]        coeff_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]        coeff_b_i,
    input wire                              pm_param_tvalid_i,
    //point multiplication(PM) results
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_thaty_o,
    output wire                             rslt_thaty_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_lambda_o,
    output wire                             rslt_lambda_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_sumx_o,
    output wire                             rslt_sumx_tvalid_o,
    output wire [`GFP_DATA_WIDTH-1:0]       rslt_sumy_o,
    output wire                             rslt_sumy_tvalid_o,
    output wire                             rslt_all_tvalid_o,
    //ready signal, asserted when PM is idle
    output wire                             pm_tready_o,


    output wire [256 - 1 : 0]   top_mul0_a_i         ,
    output wire [256 - 1 : 0]   top_mul0_b_i         ,
    output wire                 top_mul0_ab_valid_i  ,
    input  wire [256 - 1 : 0]   top_mul0_rslt_o      ,
    input  wire                 top_mul0_rslt_valid_o,
    output wire [256 - 1 : 0]   top_inv_a_i          ,
    output wire [256 - 1 : 0]   top_inv_b_i          ,
    output wire                 top_inv_ab_valid_i   ,
    input  wire [256 - 1 : 0]   top_inv_rslt_o       ,
    input  wire                 top_inv_rslt_valid_o


    
    );

//-----------------------------------------------------------------------------------------------------
// Signal Declaration
//-----------------------------------------------------------------------------------------------------
    //Field Multiplier
    wire [`GFP_DATA_WIDTH-1:0]              pm_mul0_rslt;
    wire                                    pm_mul0_rslt_valid;
    wire [`GFP_DATA_WIDTH-1:0]              pm_mul0_a;
    wire [`GFP_DATA_WIDTH-1:0]              pm_mul0_b;
    wire                                    pm_mul0_ab_valid;

    //Field Adder-Subtractor 
    wire [`GFP_DATA_WIDTH-1:0]              pm_as_rslt;
    wire [`GFP_DATA_WIDTH-1:0]              pm_as_a;
    wire [`GFP_DATA_WIDTH-1:0]              pm_as_b;
    wire                                    pm_as_mode_ctrl;



    //Field Inverter
    wire [`GFP_DATA_WIDTH-1:0]              pm_inv_rslt;
    wire                                    pm_inv_rslt_valid;
    wire [`GFP_DATA_WIDTH-1:0]              pm_inv_a;
    wire [`GFP_DATA_WIDTH-1:0]              pm_inv_b;
    wire                                    pm_inv_ab_valid;


//-----------------------------------------------------------------------------------------------------
// Instantiate the Control Unit of montgomery_add
//-----------------------------------------------------------------------------------------------------
    montgomery_add_core #(
        .P_MOD                      (P_MOD)
    )
    u_montgomery_add_core(
        .pm_clk_i                   (pm_clk_i),
        .pm_rstn_i                  (pm_rstn_i),

        .this_xp_i                  (this_xp_i            ),
        .this_yp_i                  (this_yp_i            ),
        .that_xp_i                  (that_xp_i            ),
        .that_yp_i                  (that_yp_i            ),
        .coeff_a_i                  (coeff_a_i            ),
        .coeff_b_i                  (coeff_b_i            ),
        .pm_param_tvalid_i          (pm_param_tvalid_i    ),
        .rslt_thaty_o               (rslt_thaty_o         ),
        .rslt_thaty_tvalid_o        (rslt_thaty_tvalid_o  ),
        .rslt_lambda_o              (rslt_lambda_o        ),
        .rslt_lambda_tvalid_o       (rslt_lambda_tvalid_o ),
        .rslt_sumx_o                (rslt_sumx_o          ),
        .rslt_sumx_tvalid_o         (rslt_sumx_tvalid_o   ),
        .rslt_sumy_o                (rslt_sumy_o          ),
        .rslt_sumy_tvalid_o         (rslt_sumy_tvalid_o   ),
        .rslt_all_tvalid_o          (rslt_all_tvalid_o    ),

        .pm_tready_o                (pm_tready_o),
        //------Field Multiplier Interface------
        .pm_mul0_rslt_i             (pm_mul0_rslt),
        .pm_mul0_rslt_valid_i       (pm_mul0_rslt_valid),
        .pm_mul0_a_o                (pm_mul0_a),
        .pm_mul0_b_o                (pm_mul0_b),
        .pm_mul0_ab_valid_o         (pm_mul0_ab_valid),

        //------Field Adder-Subtractor Interface------
        .pm_as_rslt_i               (pm_as_rslt),
        .pm_as_a_o                  (pm_as_a),
        .pm_as_b_o                  (pm_as_b),
        .pm_as_mode_ctrl_o          (pm_as_mode_ctrl),

        //------Field Inverter Interface------
        .pm_inv_rslt_i              (pm_inv_rslt),
        .pm_inv_rslt_valid_i        (pm_inv_rslt_valid),
        .pm_inv_a_o                 (pm_inv_a),
        .pm_inv_b_o                 (pm_inv_b),
        .pm_inv_ab_valid_o          (pm_inv_ab_valid)

    );

//-----------------------------------------------------------------------------------------------------
// Instantiate the Field Multiplier for field multiplication
//-----------------------------------------------------------------------------------------------------
    // field_mul_gfp #(
    //     .P_MOD                  (P_MOD)
    // )
    // u0_field_mul_gfp(
    //     .fm_clk_i               (pm_clk_i),
    //     .fm_rstn_i              (pm_rstn_i),
    //     .fm_a_i                 (pm_mul0_a                       ),
    //     .fm_b_i                 (pm_mul0_b                       ),
    //     .fm_ab_valid_i          (pm_mul0_ab_valid                        ),
    //     .fm_rslt_o              (pm_mul0_rslt                        ),
    //     .fm_rslt_valid_o        (pm_mul0_rslt_valid                      )
    // );

assign  top_mul0_a_i           = pm_mul0_a          ;
assign  top_mul0_b_i           = pm_mul0_b          ;
assign  top_mul0_ab_valid_i    = pm_mul0_ab_valid   ;
assign  pm_mul0_rslt           = top_mul0_rslt_o      ;
assign  pm_mul0_rslt_valid     = top_mul0_rslt_valid_o;
assign  top_inv_a_i            = pm_inv_a           ;
assign  top_inv_b_i            = pm_inv_b           ;
assign  top_inv_ab_valid_i     = pm_inv_ab_valid    ;
assign  pm_inv_rslt            = top_inv_rslt_o       ;
assign  pm_inv_rslt_valid      = top_inv_rslt_valid_o ;



//-----------------------------------------------------------------------------------------------------
// Instantiate the Field Adder-Subtractor for field addition and subtraction
//-----------------------------------------------------------------------------------------------------
    bhp_field_add_sub_gfp #(
        .P_MOD                  (P_MOD)
    )
    u_field_add_sub_gfp(
        .fas_a_i                (pm_as_a),
        .fas_b_i                (pm_as_b),
        .fas_mode_ctrl_i        (pm_as_mode_ctrl),
        .fas_rslt_o             (pm_as_rslt)
    );

//-----------------------------------------------------------------------------------------------------
// Instantiate the Field Inverter for field inversion
//-----------------------------------------------------------------------------------------------------
    // field_inv_gfp #(
    //     .P_MOD                  (P_MOD)
    // )
    // u_field_inv_gfp(
    //     .fi_clk_i               (pm_clk_i),
    //     .fi_rstn_i              (pm_rstn_i),
    //     .fi_a_i                 (pm_inv_a),
    //     .fi_b_i                 (pm_inv_b),
    //     .fi_ab_valid_i          (pm_inv_ab_valid),
    //     .fi_rslt_o              (pm_inv_rslt),
    //     .fi_rslt_valid_o        (pm_inv_rslt_valid)
    // );


















endmodule
