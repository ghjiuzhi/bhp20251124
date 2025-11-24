`timescale      1ns/1ns

`define GFP_DATA_WIDTH 256

module bhp_field_add_sub_gfp#(
    parameter P_MOD = {`GFP_DATA_WIDTH{1'b1}}
    )
    (
    input wire [`GFP_DATA_WIDTH-1:0]            fas_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]            fas_b_i,
    input wire                                  fas_mode_ctrl_i,//1 --> add, 0 --> sub
    output     [`GFP_DATA_WIDTH-1:0]            fas_rslt_o
    );

reg [`GFP_DATA_WIDTH:0]                 fas_rslt_int;
reg [`GFP_DATA_WIDTH:0]                 fas_rslt_mod_int;
reg [`GFP_DATA_WIDTH-1:0]               r_fas_rslt_o;

assign fas_rslt_o = r_fas_rslt_o;

always @ ( * )
    if(fas_mode_ctrl_i == 1'b1)
        begin
            fas_rslt_int     = fas_a_i + fas_b_i;
            fas_rslt_mod_int = fas_rslt_int - P_MOD;
            if(fas_rslt_mod_int[`GFP_DATA_WIDTH] == 1'b1)
                r_fas_rslt_o = fas_rslt_int[`GFP_DATA_WIDTH-1:0];
            else
                r_fas_rslt_o = fas_rslt_mod_int[`GFP_DATA_WIDTH-1:0];
        end
    else
        begin
            fas_rslt_int = fas_a_i - fas_b_i;
            fas_rslt_mod_int = fas_rslt_int + P_MOD;
            if(fas_rslt_int[`GFP_DATA_WIDTH] == 1'b1)
                r_fas_rslt_o = fas_rslt_mod_int[`GFP_DATA_WIDTH-1:0];
            else
                r_fas_rslt_o = fas_rslt_int[`GFP_DATA_WIDTH-1:0];
        end


endmodule
