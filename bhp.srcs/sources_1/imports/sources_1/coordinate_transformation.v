`timescale 1ns / 1ps
`define GFP_DATA_WIDTH                  256
/*
// Convert the accumulating sum into the twisted Edwards point.
match &sum {
    Some((sum_x, sum_y)) => {
        println!("map completed, sum start!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!zzt");
        // Convert the accumulated sum into a point on the twisted Edwards curve.
        let edwards_x = sum_x.div_unchecked(sum_y); // 1 constraint (`sum_y` is never 0)
        println!("zzt.hasher.hash_uncompressed.map.sum_x: {:?}", sum_x);
        println!("zzt.hasher.hash_uncompressed.map.sum_y: {:?}", sum_y);
        println!("zzt.hasher.hash_uncompressed.map.edwards_x is sum_x / sum_y");
        println!("[[[leaves]]]zzt.hasher.hash_uncompressed.map.edwards_x: {:?}", edwards_x);
        let edwards_y = (sum_x - &one).div_unchecked(&(sum_x + &one)); // 1 constraint (numerator & denominator are never both 0)
        println!("zzt.hasher.hash_uncompressed.map.edwards_y.fenzi: {:?}", sum_x - &one);
        println!("zzt.hasher.hash_uncompressed.map.edwards_y.&one: {:?}", &one);
        println!("zzt.hasher.hash_uncompressed.map.edwards_y.fenmu: {:?}", &(sum_x + &one));
        println!("[[[leaves]]]zzt.hasher.hash_uncompressed.map.edwards_y: {:?}", edwards_y);
        Group::from_xy_coordinates_unchecked(edwards_x, edwards_y)
        // 0 constraints (this is safe)
    }
    None => E::halt("Invalid iteration of BHP detected, a window was not evaluated"),
}
*/

module coordinate_transformation
#(
    parameter P_MOD = {`GFP_DATA_WIDTH{1'b1}}
    )
    (
    input                   clk,
    input                   rstn,

    input  wire             i_ma_v,
    input  wire [255 : 0]   i_ma_x,
    input  wire [255 : 0]   i_ma_y,

    output wire             o_tw_v,
    output wire             o_tw_v_x,
    output wire [255 : 0]   o_tw_x,
    output wire             o_tw_v_y,
    output wire [255 : 0]   o_tw_y,


    output wire [256 - 1 : 0]   top_inv_a_i          ,
    output wire [256 - 1 : 0]   top_inv_b_i          ,
    output wire                 top_inv_ab_valid_i   ,
    input  wire [256 - 1 : 0]   top_inv_rslt_o       ,
    input  wire                 top_inv_rslt_valid_o






    );

reg             r_ma_v;
reg [255 : 0]   r_ma_x;
reg [255 : 0]   r_ma_y;

localparam ST_IDLE               = 0;
localparam ST_TW_X               = 1;
localparam ST_TW_Y               = 2;
localparam ST_FINISH             = 3;
reg  [  5 - 1 : 0]      cur_state;
reg  [  5 - 1 : 0]      next_state;

reg r_fi_ab_valid_i_0d;

reg             r_tw_v;
reg             r_tw_v_x;
reg             r_tw_v_y;
reg [255 : 0]   r_tw_x;
reg [255 : 0]   r_tw_y;

reg             r_fi_rslt_valid_o;

wire [`GFP_DATA_WIDTH-1:0]  fi_a_i             ;
wire [`GFP_DATA_WIDTH-1:0]  fi_b_i             ;
wire                        fi_ab_valid_i      ;
wire [`GFP_DATA_WIDTH-1:0]  fi_rslt_o          ;
wire                        fi_rslt_valid_o    ;

reg  [`GFP_DATA_WIDTH-1:0]  r_fi_a_i             ;
reg  [`GFP_DATA_WIDTH-1:0]  r_fi_b_i             ;
reg                         r_fi_ab_valid_i      ;
// reg  [`GFP_DATA_WIDTH-1:0]  r_fi_rslt_o          ;
// reg                         r_fi_rslt_valid_o    ;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// 缓存
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_ma_x <= 0;
            r_ma_y <= 0;
            r_ma_v <= 0;
        end else if(i_ma_v)begin
            r_ma_v <= 1;
            r_ma_x <= i_ma_x;
            r_ma_y <= i_ma_y;
        end else begin
            r_ma_v <= 0;
            r_ma_x <= r_ma_x;
            r_ma_y <= r_ma_y;
        end
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// State
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            cur_state <= ST_IDLE;
        else
            cur_state <= next_state;
    end
    always @(*) begin
        case (cur_state)
            ST_IDLE    : if (r_ma_v           ) next_state = ST_TW_X   ; else next_state = ST_IDLE;
            ST_TW_X    : if (r_fi_rslt_valid_o) next_state = ST_TW_Y   ; else next_state = ST_TW_X;
            ST_TW_Y    : if (r_fi_rslt_valid_o) next_state = ST_FINISH ; else next_state = ST_TW_Y;
            ST_FINISH  :                        next_state = ST_IDLE   ;
            default    :                        next_state = ST_IDLE   ;
        endcase
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// field_inv_gfp input
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_fi_a_i <= 0;
            r_fi_b_i <= 0;
        end else if(cur_state == ST_TW_X)begin
            r_fi_a_i <= r_ma_y;
            r_fi_b_i <= r_ma_x;
        end else if(cur_state == ST_TW_Y)begin
            r_fi_a_i <= r_ma_x + 1;
            r_fi_b_i <= r_ma_x - 1;
        end else begin
            r_fi_a_i <= r_fi_a_i;
            r_fi_b_i <= r_fi_b_i;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_fi_ab_valid_i_0d <= 0;
        end else if((cur_state == ST_IDLE) && (next_state == ST_TW_X))begin
            r_fi_ab_valid_i_0d <= 1;
        end else if((cur_state == ST_TW_X) && (next_state == ST_TW_Y))begin
            r_fi_ab_valid_i_0d <= 1;
        end else begin
            r_fi_ab_valid_i_0d <= 0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_fi_ab_valid_i <= 0;
        end else begin
            r_fi_ab_valid_i <= r_fi_ab_valid_i_0d;
        end
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// field_inv_gfp output
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign o_tw_v   = r_tw_v;
assign o_tw_v_x = r_tw_v_x;
assign o_tw_v_y = r_tw_v_y;
assign o_tw_x   = r_tw_x;
assign o_tw_y   = r_tw_y;


    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_tw_x <= 0;
        end else if(fi_rslt_valid_o && (cur_state == ST_TW_X))begin
            r_tw_x <= fi_rslt_o;
        end else begin
            r_tw_x <= r_tw_x;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_tw_y <= 0;
        end else if(fi_rslt_valid_o && (cur_state == ST_TW_Y))begin
            r_tw_y <= fi_rslt_o;
        end else begin
            r_tw_y <= r_tw_y;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_fi_rslt_valid_o <= 0;
        end else begin
            r_fi_rslt_valid_o <= fi_rslt_valid_o;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_tw_v <= 0;
        end else if(cur_state == ST_FINISH)begin
            r_tw_v <= 1;
        end else begin
            r_tw_v <= 0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_tw_v_x <= 0;
        end else if(cur_state == ST_TW_Y)begin
            r_tw_v_x <= 1;
        end else begin
            r_tw_v_x <= 0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_tw_v_y <= 0;
        end else if(cur_state == ST_FINISH)begin
            r_tw_v_y <= 1;
        end else begin
            r_tw_v_y <= 0;
        end
    end
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// field_inv_gfp
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign fi_a_i          = r_fi_a_i         ;
assign fi_b_i          = r_fi_b_i         ;
assign fi_ab_valid_i   = r_fi_ab_valid_i  ;
// assign fi_rslt_o       = r_fi_rslt_o      ;
// assign fi_rslt_valid_o = r_fi_rslt_valid_o;

    // field_inv_gfp #(
    //     .P_MOD                      (P_MOD)
    // )
    // uut(
    //     .fi_clk_i                   (clk                ),
    //     .fi_rstn_i                  (rstn               ),
    //     .fi_a_i                     (fi_a_i             ),
    //     .fi_b_i                     (fi_b_i             ),
    //     .fi_ab_valid_i              (fi_ab_valid_i      ),
    //     .fi_rslt_o                  (fi_rslt_o          ),
    //     .fi_rslt_valid_o            (fi_rslt_valid_o    )
    // );



assign top_inv_a_i            = fi_a_i                    ;
assign top_inv_b_i            = fi_b_i                    ;
assign top_inv_ab_valid_i     = fi_ab_valid_i             ;
assign fi_rslt_o              = top_inv_rslt_o            ;
assign fi_rslt_valid_o        = top_inv_rslt_valid_o      ;






endmodule
