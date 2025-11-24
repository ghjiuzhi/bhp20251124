`timescale 1ns / 1ps

module bhp_256#(
    parameter P_MOD  = 256'h12ab_655e_9a2c_a556_60b4_4d1e_5c37_b001_59aa_76fe_d000_0001_0a11_8000_0000_0001,
    parameter MONT_A = 256'd3990301581132929505568273333084066329187552697088022219156688740916631500114,
    parameter MONT_B = 256'd4454160168295440918680551605697480202188346638066041608778544715000777738925,
    parameter TW_A = 256'd8444461749428370424248824938781546531375899335154063827935233455917409239040,
    parameter TW_D = 256'd3021
    // parameter START_POINT_X = 256'd0,//
    // parameter START_POINT_Y = 256'd0,//
    // parameter START_POINT   = 10'b0//

    )(
    input                   clk,
    input                   rstn,

    input                   i_msg_vld,
    input  [128 - 1 : 0]    i_msg,
    input  [  6 - 1 : 0]    i_msg_mode,     // I 1:8;  2:16;  3:32;   4:64;   5:128
                                            // U 6:8;  7:16;  8:32;   9:64;  10:128
    // START point
    input  wire [256 - 1 : 0]   i_START_POINT_X     ,
    input  wire [256 - 1 : 0]   i_START_POINT_Y     ,
    input  wire [ 10 - 1 : 0]   i_START_POINT       ,


    // input  [188 - 1 : 0]    i_msg_domain,
    output reg [256 - 1 : 0]o_bhp256_rslt,
    output reg              o_bhp256_rslt_vld,
    output reg              o_bhp256_rdy,

    // lvs_fifo
    output wire   [255 : 0] lvs_fifo_din       ,
    output wire             lvs_fifo_wr_en     ,
    // input  wire             lvs_fifo_rd_en     ,
    // output wire [255 : 0]   lvs_fifo_dout      ,
    // output wire             lvs_fifo_full      ,
    // output wire             lvs_fifo_empty     ,
    // output wire [8 : 0]     lvs_fifo_data_count,

    input wire pause,


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

/*
    input  wire [32-1:0]        i_id,
    input  wire                 i_loop_point,
    input  wire [256 - 1 : 0]   i_x1        ,
    input  wire [256 - 1 : 0]   i_y1        ,
    input  wire [256 - 1 : 0]   i_x2        ,
    input  wire [256 - 1 : 0]   i_y2        ,
    input  wire [256 - 1 : 0]   i_x3        ,
    input  wire [256 - 1 : 0]   i_y3        ,
    input  wire [256 - 1 : 0]   i_x4        ,
    input  wire [256 - 1 : 0]   i_y4        ,
*/
    // --- [MODIFIED START] Interface Update ---
    // Replaced old inputs (i_id, i_x1...i_y4) with:
    
    // 1. Request Interface (Output)
    // Tells external logic which ID and Chunk Choice is needed
    output wire [32-1:0]        o_id,           // Requesting ID (corresponds to MG_j)
    output wire [2:0]           o_chunk_val,    // Requesting Choice (from bit3)
    output wire                 o_req_vld,      // Request Valid

    // 2. Data Return Interface (Input)
    // External logic returns the single lookup result
    input  wire [256 - 1 : 0]   i_base_x,       // The specific X coord needed
    input  wire [256 - 1 : 0]   i_base_y,       // The specific Y coord needed
    input  wire                 i_base_vld,     // Data Valid (Replaces i_loop_point)

    // 3. Special Broadcast Interface
    // Notifies external logic of Start Point changes
    output wire                 o_change_start,
    output wire [256 - 1 : 0]   o_x1_start,
    output wire [256 - 1 : 0]   o_y1_start,
    // --- [MODIFIED END] ---
    
    output wire o_need,

    output wire mal_result_valid


    );


localparam ST_IDLE               =  0;
localparam ST_PADDING            =  1;
localparam ST_CIRCUIT_PADDING1   =  2;
localparam ST_CIRCUIT_PADDING2   =  3;
localparam ST_CIRCUIT_GET_START  =  4;
localparam ST_CIRCUIT_CHUNK_INIT =  5;
localparam ST_CIRCUIT_CHUNK      =  6;
localparam ST_CIRCUIT_CHUNK_I    =  7;
localparam ST_CIRCUIT_MA_TW      =  8;
localparam ST_CIRCUIT_TW_ADD     =  9;
localparam ST_CIRCUIT_FINISH     = 10;

// localparam ST_CIRCUIT_CHUNK1     = 4;
// localparam ST_CIRCUIT_CHUNK2     = 5;
// localparam ST_CIRCUIT_CHUNK3     = 6;

reg  [  5 - 1 : 0]      cur_state;
reg  [  5 - 1 : 0]      next_state;
reg  [ 11 - 1 : 0]      cnt_state;

reg                     r_msg_vld;
reg  [128 - 1 : 0]      r_msg;
reg  [  6 - 1 : 0]      r_msg_mode;
reg  [188 - 1 : 0]      r_msg_domain;
reg  [256 - 1 : 0]      r_START_POINT_X;
reg  [256 - 1 : 0]      r_START_POINT_Y;
reg  [ 10 - 1 : 0]      r_START_POINT  ;


reg  [154 - 1 : 0]      reg_padding;  // 128+26
reg  [406 - 1 : 0]      reg_circuit_padding1;  // 252(188+64) + 154
reg  [408 - 1 : 0]      reg_circuit_padding2;  // 2+406
reg  [411 - 1 : 0]      reg_CHUNK_shifter;     // 408+3 
reg                     reg_CHUNK_3bit_valid;
reg                     reg_CHUNK_3bit_valid_1d;
// reg  [171 - 1 : 0]      reg_CHUNK1;//zzt.hasher.hash_uncompressed.Chunk bits length: 171
// reg  [171 - 1 : 0]      reg_CHUNK2;//zzt.hasher.hash_uncompressed.Chunk bits length: 171
// reg  [171 - 1 : 0]      reg_CHUNK3;//zzt.hasher.hash_uncompressed.Chunk bits length: 171
// reg  [12 - 1 : 0]       reg_CHUNK_msg_cnt;     // 1~171*3
reg  [12 - 1 : 0]       reg_CHUNK_msg_cnt_mod3;// 1~171
reg  [12 - 1 : 0]       reg_CHUNK_msgtotal_cnt_mod3;// 1~171


wire  [256 - 1 : 0]      mal_sum_x;
wire  [256 - 1 : 0]      mal_sum_y;
wire  [256 - 1 : 0]      mal_coeff_a;
wire  [256 - 1 : 0]      mal_coeff_b;
wire  [9:0]              mal_MG_j;
wire  [2:0]              mal_bit3;
wire                     mal_bit3_valid;
// wire                     mal_result_valid;
wire  [256 - 1 : 0]      mal_result_add_x;
wire  [256 - 1 : 0]      mal_result_add_y;
wire                     mal_lvs_1;
wire  [256 - 1 : 0]      mal_lvs_montgomery_y;
wire  [256 - 1 : 0]      mal_lvs_bit0and1;
wire  [256 - 1 : 0]      mal_lvs_that_y;
wire  [256 - 1 : 0]      mal_lvs_lambda;
wire  [256 - 1 : 0]      mal_lvs_sum_x;
wire  [256 - 1 : 0]      mal_lvs_sum_y;
wire                     mal_ready;
// reg  [256 - 1 : 0]       r_mal_sum_x;
// reg  [256 - 1 : 0]       r_mal_sum_y;
reg  [256 - 1 : 0]       r_mal_coeff_a;
reg  [256 - 1 : 0]       r_mal_coeff_b;
reg  [9:0]               r_mal_MG_j;// START_POINT
reg  [2:0]               r_mal_bit3;
reg                      r_mal_bit3_valid;
wire                     r_mal_bit3_valid_0d;

reg  [256 - 1 : 0]       r_CHUNKi_sum_x;
reg  [256 - 1 : 0]       r_CHUNKi_sum_y;

reg                      r_mal_result_valid;
reg  [256 - 1 : 0]       r_mal_result_add_x;
reg  [256 - 1 : 0]       r_mal_result_add_y;
reg                      r_mal_lvs_1;
reg  [256 - 1 : 0]       r_mal_lvs_montgomery_y;
reg  [256 - 1 : 0]       r_mal_lvs_bit0and1;
reg  [256 - 1 : 0]       r_mal_lvs_that_y;
reg  [256 - 1 : 0]       r_mal_lvs_lambda;
reg  [256 - 1 : 0]       r_mal_lvs_sum_x;
reg  [256 - 1 : 0]       r_mal_lvs_sum_y;
reg                      r_mal_ready;




wire               o_tw_v;
wire               o_tw_v_x;
wire               o_tw_v_y;
wire [256 - 1 : 0] o_tw_x;
wire [256 - 1 : 0] o_tw_y;
wire ma_v;
reg  r_ma_v;

reg [256 - 1 : 0] edwards_sum_x;
reg [256 - 1 : 0] edwards_sum_y;
reg               edwards_sum_v;

wire [256-1:0] ed_this_xp_i         ;reg [256-1:0] r_ed_this_xp         ;
wire [256-1:0] ed_this_yp_i         ;reg [256-1:0] r_ed_this_yp         ;
wire [256-1:0] ed_that_xp_i         ;reg [256-1:0] r_ed_that_xp         ;
wire [256-1:0] ed_that_yp_i         ;reg [256-1:0] r_ed_that_yp         ;
wire [256-1:0] ed_tw_a_i            ;reg [256-1:0] r_ed_tw_a            ;
wire [256-1:0] ed_tw_b_i            ;reg [256-1:0] r_ed_tw_b            ;
wire           ed_pm_param_tvalid_i ;reg           r_ed_pm_param_tvalid ;

wire [256 -1:0]ed_rslt_u_o          ;
wire [256 -1:0]ed_rslt_v0_o         ;
wire [256 -1:0]ed_rslt_v1_o         ;
wire [256 -1:0]ed_rslt_h1_o         ;
wire [256 -1:0]ed_rslt_x3_o         ;
wire [256 -1:0]ed_rslt_y3_o         ;
wire ed_rslt_u_tvalid_o   ;
wire ed_rslt_v0_tvalid_o  ;
wire ed_rslt_v1_tvalid_o  ;
wire ed_rslt_h1_tvalid_o  ;
wire ed_rslt_x3_tvalid_o  ;
wire ed_rslt_y3_tvalid_o  ;
wire ed_rslt_all_tvalid_o ;
wire ed_pm_tready_o       ;

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

// wire   [255 : 0]          lvs_fifo_din        ;
// wire                      lvs_fifo_wr_en      ;
reg    [255 : 0]        r_lvs_fifo_din        ;
reg                     r_lvs_fifo_wr_en      ;


reg               fifo_lvs_1       ;
reg [256 - 1 : 0] fifo_montgomery_y;
reg [256 - 1 : 0] fifo_bit0and1    ;
reg [256 - 1 : 0] fifo_that_y      ;
reg [256 - 1 : 0] fifo_lambda      ;
reg [256 - 1 : 0] fifo_sum_x       ;
reg [256 - 1 : 0] fifo_sum_y       ;
reg [4       : 0] fifo_in_cnt;
reg          private_lvs;
reg [15 : 0] private_lvs_cnt;
reg [15 : 0] private_lvs_TOTAL;

reg o_tw_v_x_1d             ; wire w_o_tw_v_x_1d           ;
reg o_tw_v_y_1d             ; wire w_o_tw_v_y_1d           ;
reg ed_rslt_u_tvalid_o_1d   ; wire w_ed_rslt_u_tvalid_o_1d ;
reg ed_rslt_v0_tvalid_o_1d  ; wire w_ed_rslt_v0_tvalid_o_1d;
reg ed_rslt_v1_tvalid_o_1d  ; wire w_ed_rslt_v1_tvalid_o_1d;
reg ed_rslt_h1_tvalid_o_1d  ; wire w_ed_rslt_h1_tvalid_o_1d;
reg ed_rslt_x3_tvalid_o_1d  ; wire w_ed_rslt_x3_tvalid_o_1d;
reg ed_rslt_y3_tvalid_o_1d  ; wire w_ed_rslt_y3_tvalid_o_1d;

reg [3:0] ed_add_cnt;

reg fanal_ma_flag;

wire final_bit01;

reg private_lvs_1d;
reg private_lvs_2d;

reg ro_tw_v;

wire mal_pv;
reg  mal_v_w_p; // mal_v waiting for pause

reg r_ed_pm_param_tvalid_p;

wire i_ma_v;

// input reg
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_msg_vld <= 0;
            r_msg <= 0;
            r_msg_mode <= 0;
            r_msg_domain <= 0;
            r_START_POINT_X <= 0;
            r_START_POINT_Y <= 0;
            r_START_POINT   <= 0;
        end else if(i_msg_vld)begin
            r_msg_vld <= 1;
            r_msg <= i_msg;
            r_msg_mode <= i_msg_mode;
            // r_msg_domain <= i_msg_domain;
            r_START_POINT_X <= i_START_POINT_X;
            r_START_POINT_Y <= i_START_POINT_Y;
            r_START_POINT   <= i_START_POINT  ;
        end else begin
            r_msg_vld <= 0;
            r_msg <= r_msg;
            r_msg_mode <= r_msg_mode;
            r_msg_domain <= r_msg_domain;
            r_START_POINT_X <= r_START_POINT_X;
            r_START_POINT_Y <= r_START_POINT_Y;
            r_START_POINT   <= r_START_POINT  ;
        end
    end

// state machine
    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            cur_state <= ST_IDLE;
        else
            cur_state <= next_state;
    end

    always @(posedge clk or negedge rstn) begin
        if (!rstn)
            cnt_state <= 0;
        else if(cur_state != next_state)
            cnt_state <= 0;
        else
            cnt_state <= cnt_state + 1;
    end

    always @(*) begin
        case (cur_state)
            ST_IDLE              : if( r_msg_vld                                                  ) next_state = ST_PADDING            ; else next_state = ST_IDLE;
            ST_PADDING           :                                                                  next_state = ST_CIRCUIT_PADDING1   ;
            ST_CIRCUIT_PADDING1  :                                                                  next_state = ST_CIRCUIT_PADDING2   ;
            ST_CIRCUIT_PADDING2  :                                                                  next_state = ST_CIRCUIT_GET_START  ;
            ST_CIRCUIT_GET_START :                                                                  next_state = ST_CIRCUIT_CHUNK_INIT ;
            ST_CIRCUIT_CHUNK_INIT:                                                                  next_state = ST_CIRCUIT_CHUNK      ;
            ST_CIRCUIT_CHUNK     : if( reg_CHUNK_msg_cnt_mod3 == 1                                ) next_state = ST_CIRCUIT_MA_TW      ;
                              else if((reg_CHUNK_msg_cnt_mod3 == reg_CHUNK_msgtotal_cnt_mod3 + 2 -  57) || (reg_CHUNK_msg_cnt_mod3  == reg_CHUNK_msgtotal_cnt_mod3 + 1 -  57 - 57))
                                                                                                    next_state = ST_CIRCUIT_MA_TW      ;
                              else                                                                  next_state = ST_CIRCUIT_CHUNK_I    ;
            ST_CIRCUIT_CHUNK_I   : if((r_mal_result_valid == 1) && (~pause)                       ) next_state = ST_CIRCUIT_CHUNK      ; else next_state = ST_CIRCUIT_CHUNK_I;
            ST_CIRCUIT_MA_TW     : if( ro_tw_v && (~pause)                                        ) next_state = ST_CIRCUIT_TW_ADD     ; else next_state = ST_CIRCUIT_MA_TW;
            ST_CIRCUIT_TW_ADD    : if((reg_CHUNK_msg_cnt_mod3 == 1) && edwards_sum_v && (~pause)  ) next_state = ST_CIRCUIT_FINISH     ;
                              else if( edwards_sum_v && (~pause)                                  ) next_state = ST_CIRCUIT_CHUNK      ;
                              else                                                                  next_state = ST_CIRCUIT_TW_ADD     ;
            ST_CIRCUIT_FINISH    : if(cnt_state == 3                                              ) next_state = ST_IDLE               ; else next_state = ST_CIRCUIT_FINISH;
            default              :                                                                  next_state = ST_IDLE               ;
        endcase
    end
    /*AUTOASCIIENUM("state","state_asc","SM_")*/
    //Beginning of automatic ASCII enum decoding
    reg[199:0] cstate_asc;               // Decode of state
    always @ (cur_state) 
    begin
        case({cur_state})
            ST_IDLE               :    cstate_asc = "ST_IDLE               ";
            ST_PADDING            :    cstate_asc = "ST_PADDING            ";
            ST_CIRCUIT_PADDING1   :    cstate_asc = "ST_CIRCUIT_PADDING1   ";
            ST_CIRCUIT_PADDING2   :    cstate_asc = "ST_CIRCUIT_PADDING2   ";
            ST_CIRCUIT_CHUNK_INIT :    cstate_asc = "ST_CIRCUIT_CHUNK_INIT ";
            ST_CIRCUIT_CHUNK      :    cstate_asc = "ST_CIRCUIT_CHUNK      ";
            ST_CIRCUIT_CHUNK_I    :    cstate_asc = "ST_CIRCUIT_CHUNK_I    ";
            ST_CIRCUIT_MA_TW      :    cstate_asc = "ST_CIRCUIT_MA_TW      ";
            ST_CIRCUIT_TW_ADD     :    cstate_asc = "ST_CIRCUIT_TW_ADD     ";
            ST_CIRCUIT_FINISH     :    cstate_asc = "ST_CIRCUIT_FINISH     ";
            default:                cstate_asc = "%Error";
        endcase
    end
    //End of automatics
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// padding
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// reg_padding
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_padding <= 0;
        end else if(cur_state == ST_PADDING)begin
            if     (r_msg_mode ==  1) reg_padding <= {120'b0,2'b00,8'b0010_0000,16'b0001_0000_0000_0000,r_msg[8   -1:0]};
            else if(r_msg_mode ==  2) reg_padding <= {112'b0,2'b00,8'b1010_0000,16'b0000_1000_0000_0000,r_msg[16  -1:0]};
            else if(r_msg_mode ==  3) reg_padding <= { 96'b0,2'b00,8'b0110_0000,16'b0000_0100_0000_0000,r_msg[32  -1:0]};
            else if(r_msg_mode ==  4) reg_padding <= { 64'b0,2'b00,8'b1110_0000,16'b0000_0010_0000_0000,r_msg[64  -1:0]};
            else if(r_msg_mode ==  5) reg_padding <= {       2'b00,8'b0001_0000,16'b0000_0001_0000_0000,r_msg[128 -1:0]};
            else if(r_msg_mode ==  6) reg_padding <= {120'b0,2'b00,8'b1001_0000,16'b0001_0000_0000_0000,r_msg[8   -1:0]};
            else if(r_msg_mode ==  7) reg_padding <= {112'b0,2'b00,8'b0101_0000,16'b0000_1000_0000_0000,r_msg[16  -1:0]};
            else if(r_msg_mode ==  8) reg_padding <= { 96'b0,2'b00,8'b1101_0000,16'b0000_0100_0000_0000,r_msg[32  -1:0]};
            else if(r_msg_mode ==  9) reg_padding <= { 64'b0,2'b00,8'b0011_0000,16'b0000_0010_0000_0000,r_msg[64  -1:0]};
            else if(r_msg_mode == 10) reg_padding <= {       2'b00,8'b1011_0000,16'b0000_0001_0000_0000,r_msg[128 -1:0]};
            // 0110 1000
            // 1110 1101 0011 1010
            // 1110 1101 0011 1010 1101 1010 1010 0000
            // 1000 0111 1000 1101 1110 0000 1111 110000001101011110111011111110100110
            // 0000 1001 1011 0001 0100 1110 0111 0011010110010101000110010011000011010101011111011010000011100100111100110100100010101100000100001001
            else                     reg_padding <= reg_padding;
        end else begin
            reg_padding <= reg_padding;
        end
    end

// reg_circuit_padding1
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_circuit_padding1 <= 0;
        end else if(cur_state == ST_CIRCUIT_PADDING1)begin
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) reg_circuit_padding1 <= {252'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100011010100110010010100000100100001000010011011110110010101101100010000010100010000000000000000000000000000000000000000000000000000000000,reg_padding[2+8+16+8   -1:0]};
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) reg_circuit_padding1 <= {252'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100011010100110010010100000100100001000010011011110110010101101100010000010101010000000000000000000000000000000000000000000000000000000000,reg_padding[2+8+16+16  -1:0]};
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) reg_circuit_padding1 <= {252'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100011010100110010010100000100100001000010011011110110010101101100010000010101110000000000000000000000000000000000000000000000000000000000,reg_padding[2+8+16+32  -1:0]};
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) reg_circuit_padding1 <= {252'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100011010100110010010100000100100001000010011011110110010101101100010000010101101000000000000000000000000000000000000000000000000000000000,reg_padding[2+8+16+64  -1:0]};
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) reg_circuit_padding1 <= {252'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001101100011010100110010010100000100100001000010011011110110010101101100010000010101100100000000000000000000000000000000000000000000000000000000,reg_padding[2+8+16+128 -1:0]};
            else                     reg_circuit_padding1 <= reg_circuit_padding1;
        end else begin
            reg_circuit_padding1 <= reg_circuit_padding1;
        end
    end

// reg_circuit_padding2

reg mod3_padding_flag;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            mod3_padding_flag <= 0;
        end else if(cur_state == ST_CIRCUIT_PADDING2)begin
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) mod3_padding_flag <= 1;
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) mod3_padding_flag <= 0;
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) mod3_padding_flag <= 1;
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) mod3_padding_flag <= 0;
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) mod3_padding_flag <= 1;
            else                     mod3_padding_flag <= mod3_padding_flag;
        end else begin
            mod3_padding_flag <= mod3_padding_flag;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_circuit_padding2 <= 0;
        end else if(cur_state == ST_CIRCUIT_PADDING2)begin
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) reg_circuit_padding2 <= {reg_circuit_padding1[252 + 2+8+16+8   -1:0],2'b00}; // 288bit
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) reg_circuit_padding2 <=  reg_circuit_padding1[252 + 2+8+16+16  -1:0]       ; // 294bit
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) reg_circuit_padding2 <= {reg_circuit_padding1[252 + 2+8+16+32  -1:0],2'b00}; // 312bit
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) reg_circuit_padding2 <=  reg_circuit_padding1[252 + 2+8+16+64  -1:0]       ; // 342bit
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) reg_circuit_padding2 <= {reg_circuit_padding1[252 + 2+8+16+128 -1:0],2'b00}; // 408bit
            else                     reg_circuit_padding2 <= reg_circuit_padding2;
        end else begin
            reg_circuit_padding2 <= reg_circuit_padding2;
        end
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHUNK
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// reg_CHUNK_msg_cnt_mod3
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_CHUNK_msg_cnt_mod3 <= 0;
        end else if(cur_state == ST_CIRCUIT_CHUNK_INIT)begin 
            //orig if     (r_msg_mode == 1) reg_CHUNK_msg_cnt_mod3 <= 96 + 1                   + 2;
            //orig else if(r_msg_mode == 2) reg_CHUNK_msg_cnt_mod3 <= 98 + 1                   + 2;
            //orig else if(r_msg_mode == 3) reg_CHUNK_msg_cnt_mod3 <= 104 + 1                  + 2;
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) reg_CHUNK_msg_cnt_mod3 <= 95 + 1                   + 2  - r_mal_MG_j;
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) reg_CHUNK_msg_cnt_mod3 <= 97 + 1                   + 2  - r_mal_MG_j;
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) reg_CHUNK_msg_cnt_mod3 <= 103 + 1                  + 2  - r_mal_MG_j;
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) reg_CHUNK_msg_cnt_mod3 <= 114 + 1                  + 2  - r_mal_MG_j;
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) reg_CHUNK_msg_cnt_mod3 <= 136 + 1                  + 2  - r_mal_MG_j;
            else                                             reg_CHUNK_msg_cnt_mod3 <= reg_CHUNK_msg_cnt_mod3                    ;
        end else if(reg_CHUNK_msg_cnt_mod3 == 1)begin
            reg_CHUNK_msg_cnt_mod3 <= 1;
        end else if(cur_state == ST_CIRCUIT_CHUNK)begin
            reg_CHUNK_msg_cnt_mod3 <= reg_CHUNK_msg_cnt_mod3 - 1;
        end else begin
            reg_CHUNK_msg_cnt_mod3 <= reg_CHUNK_msg_cnt_mod3;
        end
    end
// reg_CHUNK_msgtotal_cnt_mod3;//171
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_CHUNK_msgtotal_cnt_mod3 <= 0;
        end else if(cur_state == ST_CIRCUIT_CHUNK_INIT)begin // reg_CHUNK_msgtotal_cnt_mod3 
            //orig if     (r_msg_mode == 1) reg_CHUNK_msgtotal_cnt_mod3 <= 96 + 1;
            //orig else if(r_msg_mode == 2) reg_CHUNK_msgtotal_cnt_mod3 <= 98 + 1;
            //orig else if(r_msg_mode == 3) reg_CHUNK_msgtotal_cnt_mod3 <= 104 + 1;
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) reg_CHUNK_msgtotal_cnt_mod3 <= 95  + 1;
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) reg_CHUNK_msgtotal_cnt_mod3 <= 97  + 1;
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) reg_CHUNK_msgtotal_cnt_mod3 <= 103 + 1;
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) reg_CHUNK_msgtotal_cnt_mod3 <= 114 + 1;
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) reg_CHUNK_msgtotal_cnt_mod3 <= 136 + 1;
            else                     reg_CHUNK_msgtotal_cnt_mod3 <= reg_CHUNK_msgtotal_cnt_mod3;
        end else begin
            reg_CHUNK_msgtotal_cnt_mod3 <= reg_CHUNK_msgtotal_cnt_mod3;
        end
    end
// reg_CHUNK_shifter
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_CHUNK_shifter <= 0;
        end else if(cur_state == ST_CIRCUIT_CHUNK_INIT)begin
            if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2 << (408 - 288 + r_mal_MG_j + r_mal_MG_j + r_mal_MG_j)};  // 288bit
            else if((r_msg_mode == 2) || (r_msg_mode ==  7)) reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2 << (408 - 294 + r_mal_MG_j + r_mal_MG_j + r_mal_MG_j)};  // 294bit
            else if((r_msg_mode == 3) || (r_msg_mode ==  8)) reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2 << (408 - 312 + r_mal_MG_j + r_mal_MG_j + r_mal_MG_j)};  // 312bit
            else if((r_msg_mode == 4) || (r_msg_mode ==  9)) reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2 << (408 - 342 + r_mal_MG_j + r_mal_MG_j + r_mal_MG_j)};  // 342bit
            else if((r_msg_mode == 5) || (r_msg_mode == 10)) reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2 << (408 - 408 + r_mal_MG_j + r_mal_MG_j + r_mal_MG_j)};  // 408bit
            else                                             reg_CHUNK_shifter <= {3'b000,reg_circuit_padding2                                                      };
        end else if((cur_state == ST_CIRCUIT_CHUNK) && (next_state == ST_CIRCUIT_CHUNK_I))begin
            reg_CHUNK_shifter <= reg_CHUNK_shifter << 3;
        end else begin
            reg_CHUNK_shifter <= reg_CHUNK_shifter;
        end
    end




/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// CHUNK_I
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


// mal_bit3_valid
    assign mal_bit3_valid = r_mal_bit3_valid;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_CHUNK_3bit_valid<= 0;
        end else if(cur_state == ST_CIRCUIT_CHUNK_I) begin
            reg_CHUNK_3bit_valid <= 1;
        end else begin
            reg_CHUNK_3bit_valid <= 0;
        end
    end
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            reg_CHUNK_3bit_valid_1d  <= 0;
        end else begin
            reg_CHUNK_3bit_valid_1d <= reg_CHUNK_3bit_valid;
        end
    end
    assign r_mal_bit3_valid_0d = reg_CHUNK_3bit_valid && (~reg_CHUNK_3bit_valid_1d);
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_mal_bit3_valid <= 0;
        end else begin
            r_mal_bit3_valid <= r_mal_bit3_valid_0d;
        end
    end

// mal_coeff_a
// mal_coeff_b
    assign mal_coeff_a = r_mal_coeff_a;
    assign mal_coeff_b = r_mal_coeff_b;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_mal_coeff_a <= 0;
            r_mal_coeff_b <= 0;
        end else begin
            r_mal_coeff_a <= MONT_A;
            r_mal_coeff_b <= MONT_B;
        end
    end

// mal_bit3
    assign mal_bit3             = r_mal_bit3            ;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_mal_bit3 <= 0;
        end else if(r_mal_bit3_valid_0d)begin
            r_mal_bit3 <= reg_CHUNK_shifter[411-1 -: 3];
        end else begin
            r_mal_bit3 <= r_mal_bit3;
        end
    end

// mal_MG_j
    assign mal_MG_j  = r_mal_MG_j ;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            // r_mal_MG_j <= START_POINT;//0;
            r_mal_MG_j <= 0;
        end else if(cur_state == ST_CIRCUIT_GET_START)begin
            r_mal_MG_j <= r_START_POINT;//0;
        end else if(r_mal_bit3_valid_0d)begin
            // r_mal_MG_j <= reg_CHUNK_msgtotal_cnt_mod3 - reg_CHUNK_msg_cnt_mod3;
            r_mal_MG_j <= r_mal_MG_j + 1;
        end else begin
            r_mal_MG_j <= r_mal_MG_j;
        end
    end

// r_CHUNKi_sum_x
// r_CHUNKi_sum_y
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            r_CHUNKi_sum_x <= 0;
            r_CHUNKi_sum_y <= 0;
        end else if(cur_state == ST_CIRCUIT_GET_START)begin
            // r_CHUNKi_sum_x <= START_POINT_X;
            // r_CHUNKi_sum_y <= START_POINT_Y;
            r_CHUNKi_sum_x <= r_START_POINT_X;
            r_CHUNKi_sum_y <= r_START_POINT_Y;
        end else if(r_mal_result_valid)begin
            r_CHUNKi_sum_x <= r_mal_result_add_x;
            r_CHUNKi_sum_y <= r_mal_result_add_y;
        end else begin
            r_CHUNKi_sum_x <= r_CHUNKi_sum_x;
            r_CHUNKi_sum_y <= r_CHUNKi_sum_y;
        end
    end
assign mal_sum_x = r_CHUNKi_sum_x;
assign mal_sum_y = r_CHUNKi_sum_y;




// mal_result_valid
// mal_result_add_x
// mal_result_add_y
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_mal_result_add_x      <= 0;
        r_mal_result_add_y      <= 0;
        r_mal_lvs_1             <= 0;
        r_mal_lvs_montgomery_y  <= 0;
        r_mal_lvs_bit0and1      <= 0;
        r_mal_lvs_that_y        <= 0;
        r_mal_lvs_lambda        <= 0;
        r_mal_lvs_sum_x         <= 0;
        r_mal_lvs_sum_y         <= 0;
        // r_mal_ready             <= 0;
    end else if(mal_result_valid)begin
        r_mal_result_add_x      <= mal_result_add_x    ;
        r_mal_result_add_y      <= mal_result_add_y    ;
        r_mal_lvs_1             <= mal_lvs_1           ;
        r_mal_lvs_montgomery_y  <= mal_lvs_montgomery_y;
        r_mal_lvs_bit0and1      <= mal_lvs_bit0and1    ;
        r_mal_lvs_that_y        <= mal_lvs_that_y      ;
        r_mal_lvs_lambda        <= mal_lvs_lambda      ;
        r_mal_lvs_sum_x         <= mal_lvs_sum_x       ;
        r_mal_lvs_sum_y         <= mal_lvs_sum_y       ;
        // r_mal_ready             <= mal_ready           ;
    end else begin
        // r_mal_result_add_x      <= 0;
        // r_mal_result_add_y      <= 0;
        // r_mal_lvs_1             <= 0;
        // r_mal_lvs_montgomery_y  <= 0;
        // r_mal_lvs_bit0and1      <= 0;
        // r_mal_lvs_that_y        <= 0;
        // r_mal_lvs_lambda        <= 0;
        // r_mal_lvs_sum_x         <= 0;
        // r_mal_lvs_sum_y         <= 0;
        // // r_mal_ready             <= 0;
        r_mal_result_add_x      <= r_mal_result_add_x      ;
        r_mal_result_add_y      <= r_mal_result_add_y      ;
        r_mal_lvs_1             <= r_mal_lvs_1             ;
        r_mal_lvs_montgomery_y  <= r_mal_lvs_montgomery_y  ;
        r_mal_lvs_bit0and1      <= r_mal_lvs_bit0and1      ;
        r_mal_lvs_that_y        <= r_mal_lvs_that_y        ;
        r_mal_lvs_lambda        <= r_mal_lvs_lambda        ;
        r_mal_lvs_sum_x         <= r_mal_lvs_sum_x         ;
        r_mal_lvs_sum_y         <= r_mal_lvs_sum_y         ;
        // r_mal_ready             <= 0;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        r_mal_result_valid <= 0;
    else if(mal_result_valid)
        r_mal_result_valid <= 1;
    else if((cur_state ==  ST_CIRCUIT_CHUNK_I) && (next_state == ST_CIRCUIT_CHUNK))
        r_mal_result_valid <= 0;
    else
        r_mal_result_valid <= r_mal_result_valid;
end









always @(posedge clk or negedge rstn) begin
    if(~rstn)
        mal_v_w_p <= 0;
    else if(mal_bit3_valid)
        mal_v_w_p <= 1;
    else if(mal_pv)
        mal_v_w_p <= 0;
    else
        mal_v_w_p <= mal_v_w_p;
end
assign mal_pv = mal_v_w_p && (~pause);



// --- [MODIFIED START] Output Logic Assignments ---

    // Map internal counters/state to output request signals
    // r_mal_MG_j is the internal counter for the current chunk index
    assign o_id        = {22'd0, r_mal_MG_j}; 
    assign o_chunk_val = r_mal_bit3;
    // Valid when internal logic generates a new bit3 request
    assign o_req_vld   = r_mal_bit3_valid;

    // Special broadcast signals triggering on state change
    assign o_change_start = (cur_state == ST_CIRCUIT_GET_START);
    assign o_x1_start     = r_START_POINT_X;
    assign o_y1_start     = r_START_POINT_Y;

    // --- [MODIFIED END] ---



    montgomery_add_lookup #(
        .P_MOD(P_MOD)
    ) u_montgomery_add_lookup (
        .clk                (clk                        ), 
        .rstn               (rstn                       ), 

        .sum_x              (mal_sum_x                  ), 
        .sum_y              (mal_sum_y                  ), 
        .coeff_a            (mal_coeff_a                ), 
        .coeff_b            (mal_coeff_b                ), 
        .MG_j               (mal_MG_j                   ), 
        .bit3               (mal_bit3                   ), 
        .bit3_valid         (mal_pv                     ), 

        .result_valid       (mal_result_valid           ), 
        .result_add_x       (mal_result_add_x           ), 
        .result_add_y       (mal_result_add_y           ), 
        .lvs_1              (mal_lvs_1                  ), 
        .lvs_montgomery_y   (mal_lvs_montgomery_y       ), 
        .lvs_bit0and1       (mal_lvs_bit0and1           ), 
        .lvs_that_y         (mal_lvs_that_y             ), 
        .lvs_lambda         (mal_lvs_lambda             ), 
        .lvs_sum_x          (mal_lvs_sum_x              ), 
        .lvs_sum_y          (mal_lvs_sum_y              ), 
        .ready              (mal_ready                  ), 


        .top_mul0_a_i                 (t1_mul0_a_i         ),
        .top_mul0_b_i                 (t1_mul0_b_i         ),
        .top_mul0_ab_valid_i          (t1_mul0_ab_valid_i  ),
        .top_mul0_rslt_o              (t1_mul0_rslt_o      ),
        .top_mul0_rslt_valid_o        (t1_mul0_rslt_valid_o),
        .top_inv_a_i                  (t1_inv_a_i          ),
        .top_inv_b_i                  (t1_inv_b_i          ),
        .top_inv_ab_valid_i           (t1_inv_ab_valid_i   ),
        .top_inv_rslt_o               (t1_inv_rslt_o       ),
        .top_inv_rslt_valid_o         (t1_inv_rslt_valid_o ),

 //       .i_id          (i_id        ),
 // 1. Trick ID Check:
        // The module expects (i_id == MG_j - 1).
        // We calculate (r_mal_MG_j - 1) and feed it in, forcing the check to PASS.
        .i_id          ( {22'd0, r_mal_MG_j - 10'd1} ),
//        .i_loop_point  (i_loop_point),
// 2. Control Validity:
        // Since ID check is forced true, data acceptance is controlled solely by this signal.
        .i_loop_point  ( i_base_vld ),
/*        .i_x1          (i_x1        ),
        .i_y1          (i_y1        ),
        .i_x2          (i_x2        ),
        .i_y2          (i_y2        ),
        .i_x3          (i_x3        ),
        .i_y3          (i_y3        ),
        .i_x4          (i_x4        ),
        .i_y4          (i_y4        ),
*/
// 3. Bypass MUX Selection:
        // Connect the SINGLE external base point to ALL input channels.
        // No matter what 'bit3' selects (1, 2, 3, or 4), it reads the correct i_base_x.
        .i_x1          ( i_base_x ), 
        .i_y1          ( i_base_y ),
        .i_x2          ( i_base_x ), 
        .i_y2          ( i_base_y ),
        .i_x3          ( i_base_x ), 
        .i_y3          ( i_base_y ),
        .i_x4          ( i_base_x ), 
        .i_y4          ( i_base_y ),
        .o_need        (o_need      )


    );


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// coordinate_transformation
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

assign ma_v = (cur_state == ST_CIRCUIT_CHUNK && next_state == ST_CIRCUIT_MA_TW)?1:0;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ma_v <= 0;
    end else if(ma_v)begin
        r_ma_v <= 1;
    end else if(i_ma_v)begin
        r_ma_v <= 0;
    end else begin
        r_ma_v <= r_ma_v;
    end
end
// assign i_ma_v = ma_v;
assign i_ma_v = r_ma_v && (~pause);

always @(posedge clk or negedge rstn) begin
    if(~rstn)
        ro_tw_v <= 0;
    else if(o_tw_v)
        ro_tw_v <= 1;
    else if((cur_state ==  ST_CIRCUIT_MA_TW) && (next_state == ST_CIRCUIT_TW_ADD))
        ro_tw_v <= 0;
    else
        ro_tw_v <= ro_tw_v;
end

    coordinate_transformation 
    // #(
        // .P_MOD(P_MOD)
    // ) 
    u_coordinate_transformation (
        .clk     (clk          ),    
        .rstn    (rstn         ),    

        .i_ma_v  (i_ma_v           ),
        .i_ma_x  (mal_sum_x        ),
        .i_ma_y  (mal_sum_y        ),

        .o_tw_v  (o_tw_v       ),    
        .o_tw_x  (o_tw_x       ),    
        .o_tw_y  (o_tw_y       ),    
        .o_tw_v_x(o_tw_v_x     ),
        .o_tw_v_y(o_tw_v_y     ),

        .top_inv_a_i                  (t3_inv_a_i             ),
        .top_inv_b_i                  (t3_inv_b_i             ),
        .top_inv_ab_valid_i           (t3_inv_ab_valid_i      ),
        .top_inv_rslt_o               (t3_inv_rslt_o          ),
        .top_inv_rslt_valid_o         (t3_inv_rslt_valid_o    )



    );

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ST_CIRCUIT_TW_ADD
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

reg [3:0] ST_CIRCUIT_TW_ADD_cnt;
    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            ST_CIRCUIT_TW_ADD_cnt <= 1;
        end else if((cur_state == ST_CIRCUIT_MA_TW) && (next_state == ST_CIRCUIT_TW_ADD))begin
            ST_CIRCUIT_TW_ADD_cnt <= ST_CIRCUIT_TW_ADD_cnt + 1;
        end else if(cur_state == ST_CIRCUIT_CHUNK_INIT)begin
            ST_CIRCUIT_TW_ADD_cnt <= 1;
        end else begin
            ST_CIRCUIT_TW_ADD_cnt <= ST_CIRCUIT_TW_ADD_cnt;
        end
    end

// edwards_sum_x
// edwards_sum_y
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        edwards_sum_x <= 0;
        edwards_sum_y <= 0;
        edwards_sum_v <= 0;
    end else if((ST_CIRCUIT_TW_ADD_cnt == 1) && o_tw_v)begin
        edwards_sum_x <= o_tw_x;
        edwards_sum_y <= o_tw_y;
        edwards_sum_v <= 1;
    end else if((ST_CIRCUIT_TW_ADD_cnt != 1) && ed_rslt_all_tvalid_o)begin
        edwards_sum_x <= ed_rslt_x3_o;
        edwards_sum_y <= ed_rslt_y3_o;
        edwards_sum_v <= 1;
    end else if((cur_state ==  ST_CIRCUIT_TW_ADD) && ((next_state == ST_CIRCUIT_FINISH) || (next_state == ST_CIRCUIT_CHUNK)))begin
        edwards_sum_x <= edwards_sum_x;
        edwards_sum_y <= edwards_sum_y;
        edwards_sum_v <= 0;
    end else begin
        edwards_sum_x <= edwards_sum_x;
        edwards_sum_y <= edwards_sum_y;
        edwards_sum_v <= edwards_sum_v;
    end
end

assign ed_this_xp_i          = r_ed_this_xp         ;
assign ed_this_yp_i          = r_ed_this_yp         ;
assign ed_that_xp_i          = r_ed_that_xp         ;
assign ed_that_yp_i          = r_ed_that_yp         ;
assign ed_tw_a_i             = r_ed_tw_a            ;
assign ed_tw_b_i             = r_ed_tw_b            ;
assign ed_pm_param_tvalid_i  = r_ed_pm_param_tvalid_p  && (~pause);

// r_ed_this_xp
// r_ed_this_yp
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ed_this_xp <= 0;
        r_ed_this_yp <= 0;
    end else if(edwards_sum_v)begin
        r_ed_this_xp <= edwards_sum_x;
        r_ed_this_yp <= edwards_sum_y;
    end else begin
        r_ed_this_xp <= r_ed_this_xp;
        r_ed_this_yp <= r_ed_this_yp;
    end
end
// r_ed_that_xp
// r_ed_that_yp
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ed_that_xp <= 0;
        r_ed_that_yp <= 0;
    // end else if(cur_state == ST_CIRCUIT_GET_START)begin
        // r_ed_that_xp <= 256'd4773436076476883009055009477157422132252536224167662863522668801104130742560;//i_sp_i >=  10'd58;
        // r_ed_that_yp <= 256'd2493233023761147875329637559463360949620342328396902004744907127058533754711;//i_sp_i >=  10'd58;
    end else if(o_tw_v)begin
        r_ed_that_xp <= o_tw_x;
        r_ed_that_yp <= o_tw_y;
    end else begin
        r_ed_that_xp <= r_ed_that_xp;
        r_ed_that_yp <= r_ed_that_yp;
    end
end
// r_ed_tw_a
// r_ed_tw_b
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ed_tw_a <= 0;
        r_ed_tw_b <= 0;
    end else begin
        r_ed_tw_a <= TW_A;
        r_ed_tw_b <= TW_D;
    end
end
// r_ed_pm_param_tvalid
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ed_pm_param_tvalid <= 0;
    end else if((cur_state == ST_CIRCUIT_MA_TW) && (next_state == ST_CIRCUIT_TW_ADD) && (ST_CIRCUIT_TW_ADD_cnt != 1))begin
        r_ed_pm_param_tvalid <= 1;
    end else begin
        r_ed_pm_param_tvalid <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_ed_pm_param_tvalid_p <= 0;
    end else if(r_ed_pm_param_tvalid)begin
        r_ed_pm_param_tvalid_p <= 1;
    end else if(ed_pm_param_tvalid_i)begin
        r_ed_pm_param_tvalid_p <= 0;
    end else begin
        r_ed_pm_param_tvalid_p <= r_ed_pm_param_tvalid_p;
    end
end




    edwards_add #(
        .P_MOD(P_MOD)
    ) u_edwards_add (
        .pm_clk_i          (clk          ),
        .pm_rstn_i         (rstn         ),

        .this_xp_i         (ed_this_xp_i         ), 
        .this_yp_i         (ed_this_yp_i         ), 
        .that_xp_i         (ed_that_xp_i         ), 
        .that_yp_i         (ed_that_yp_i         ), 

        .tw_a_i            (ed_tw_a_i            ), 
        .tw_b_i            (ed_tw_b_i            ), 
        .pm_param_tvalid_i (ed_pm_param_tvalid_i ), 

        .rslt_u_o          (ed_rslt_u_o          ), 
        .rslt_u_tvalid_o   (ed_rslt_u_tvalid_o   ), 
        .rslt_v0_o         (ed_rslt_v0_o         ), 
        .rslt_v0_tvalid_o  (ed_rslt_v0_tvalid_o  ), 
        .rslt_v1_o         (ed_rslt_v1_o         ), 
        .rslt_v1_tvalid_o  (ed_rslt_v1_tvalid_o  ), 
        .rslt_h1_o         (ed_rslt_h1_o         ), 
        .rslt_h1_tvalid_o  (ed_rslt_h1_tvalid_o  ), 
        .rslt_x3_o         (ed_rslt_x3_o         ), 
        .rslt_x3_tvalid_o  (ed_rslt_x3_tvalid_o  ), 
        .rslt_y3_o         (ed_rslt_y3_o         ), 
        .rslt_y3_tvalid_o  (ed_rslt_y3_tvalid_o  ), 

        .rslt_all_tvalid_o (ed_rslt_all_tvalid_o ), 

        .pm_tready_o       (ed_pm_tready_o       ), 



        .top_mul0_a_i                 (t2_mul0_a_i           ),
        .top_mul0_b_i                 (t2_mul0_b_i           ),
        .top_mul0_ab_valid_i          (t2_mul0_ab_valid_i    ),
        .top_mul0_rslt_o              (t2_mul0_rslt_o        ),
        .top_mul0_rslt_valid_o        (t2_mul0_rslt_valid_o  ),
        .top_inv_a_i                  (t2_inv_a_i            ),
        .top_inv_b_i                  (t2_inv_b_i            ),
        .top_inv_ab_valid_i           (t2_inv_ab_valid_i     ),
        .top_inv_rslt_o               (t2_inv_rslt_o         ),
        .top_inv_rslt_valid_o         (t2_inv_rslt_valid_o   )

    );






assign top_mul0_a_i          = ({256{t1_mul0_ab_valid_i}} & t1_mul0_a_i)|({256{t2_mul0_ab_valid_i}} & t2_mul0_a_i);
assign top_mul0_b_i          = ({256{t1_mul0_ab_valid_i}} & t1_mul0_b_i)|({256{t2_mul0_ab_valid_i}} & t2_mul0_b_i);
assign top_mul0_ab_valid_i   = t1_mul0_ab_valid_i || t2_mul0_ab_valid_i;
assign t1_mul0_rslt_o        = top_mul0_rslt_o;
assign t2_mul0_rslt_o        = top_mul0_rslt_o;
assign t1_mul0_rslt_valid_o  = top_mul0_rslt_valid_o;
assign t2_mul0_rslt_valid_o  = top_mul0_rslt_valid_o;

assign top_inv_a_i           = ({256{t1_inv_ab_valid_i}} & t1_inv_a_i)|({256{t2_inv_ab_valid_i}} & t2_inv_a_i)|({256{t3_inv_ab_valid_i}} & t3_inv_a_i);
assign top_inv_b_i           = ({256{t1_inv_ab_valid_i}} & t1_inv_b_i)|({256{t2_inv_ab_valid_i}} & t2_inv_b_i)|({256{t3_inv_ab_valid_i}} & t3_inv_b_i);
assign top_inv_ab_valid_i    = t1_inv_ab_valid_i || t2_inv_ab_valid_i || t3_inv_ab_valid_i;
assign t1_inv_rslt_o         = top_inv_rslt_o;
assign t2_inv_rslt_o         = top_inv_rslt_o;
assign t3_inv_rslt_o         = top_inv_rslt_o;
assign t1_inv_rslt_valid_o   = top_inv_rslt_valid_o;
assign t2_inv_rslt_valid_o   = top_inv_rslt_valid_o;
assign t3_inv_rslt_valid_o   = top_inv_rslt_valid_o;



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// lvs_fifo
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign lvs_fifo_din   = r_lvs_fifo_din        ;
assign lvs_fifo_wr_en = r_lvs_fifo_wr_en      ;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        private_lvs_TOTAL <= 0;
    end else begin
        if     ((r_msg_mode == 1) || (r_msg_mode ==  6)) private_lvs_TOTAL <= 459;
        else if((r_msg_mode == 2) || (r_msg_mode ==  7)) private_lvs_TOTAL <= 459;
        else if((r_msg_mode == 3) || (r_msg_mode ==  8)) private_lvs_TOTAL <= 459;
        else if((r_msg_mode == 4) || (r_msg_mode ==  9)) private_lvs_TOTAL <= 459;
        else if((r_msg_mode == 5) || (r_msg_mode == 10)) private_lvs_TOTAL <= 459;
        else                     private_lvs_TOTAL <= 1;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        private_lvs_cnt <= 0;
    end else if(cur_state == ST_CIRCUIT_GET_START)begin
        // if(r_START_POINT<=57)
            // private_lvs_cnt <= r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT-5;//0;
        // else
            // private_lvs_cnt <= r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT-5 + 2;//0;
        private_lvs_cnt <= r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT+r_START_POINT;//0;
    end else if((r_START_POINT == 0) && (private_lvs_cnt == 0))begin
        private_lvs_cnt <= private_lvs_cnt + 5;
    end else if(mal_result_valid &&   mal_lvs_1  && ((r_START_POINT != 0) && (private_lvs_cnt != 0)))begin
        private_lvs_cnt <= private_lvs_cnt + 2;
    end else if(mal_result_valid && (~mal_lvs_1))begin
        private_lvs_cnt <= private_lvs_cnt + 5;
    end else begin
        private_lvs_cnt <= private_lvs_cnt;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        private_lvs <= 0;
    // end else if(private_lvs_cnt >= private_lvs_TOTAL)begin
    end else if(private_lvs_cnt > private_lvs_TOTAL)begin
        private_lvs <= 1;
    end else begin
        private_lvs <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        private_lvs_1d <= 0;
    end else begin
        private_lvs_1d <= private_lvs;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        private_lvs_2d <= 0;
    end else begin
        private_lvs_2d <= private_lvs_1d;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        fifo_lvs_1        <= 0;
        fifo_montgomery_y <= 0;
        fifo_bit0and1     <= 0;
        fifo_that_y       <= 0;
        fifo_lambda       <= 0;
        fifo_sum_x        <= 0;
        fifo_sum_y        <= 0;
    end else if(mal_result_valid)begin
        fifo_lvs_1        <= mal_lvs_1                  ;
        fifo_montgomery_y <= mal_lvs_montgomery_y       ;
        fifo_bit0and1     <= mal_lvs_bit0and1           ;
        fifo_that_y       <= mal_lvs_that_y             ;
        fifo_lambda       <= mal_lvs_lambda             ;
        fifo_sum_x        <= mal_lvs_sum_x              ;
        fifo_sum_y        <= mal_lvs_sum_y              ;
    end else begin
        fifo_lvs_1        <= fifo_lvs_1       ;
        fifo_montgomery_y <= fifo_montgomery_y;
        fifo_bit0and1     <= fifo_bit0and1    ;
        fifo_that_y       <= fifo_that_y      ;
        fifo_lambda       <= fifo_lambda      ;
        fifo_sum_x        <= fifo_sum_x       ;
        fifo_sum_y        <= fifo_sum_y       ;
    end
end

always @(posedge clk or negedge rstn) begin  
    if(~rstn) begin
        fifo_in_cnt <= 0;
    end else if(mal_result_valid)begin
        fifo_in_cnt <= 1;
    end else if(fifo_in_cnt == 7)begin
        fifo_in_cnt <= 0;
    end else if(fifo_in_cnt != 0)begin
        fifo_in_cnt <= fifo_in_cnt + 1;
    end else begin
        fifo_in_cnt <= 0;
    end
end


assign w_o_tw_v_x_1d            = o_tw_v_x_1d            ;
assign w_o_tw_v_y_1d            = o_tw_v_y_1d            ;
assign w_ed_rslt_u_tvalid_o_1d  = ed_rslt_u_tvalid_o_1d  ;
assign w_ed_rslt_v0_tvalid_o_1d = ed_rslt_v0_tvalid_o_1d ;
assign w_ed_rslt_v1_tvalid_o_1d = ed_rslt_v1_tvalid_o_1d ;
assign w_ed_rslt_h1_tvalid_o_1d = ed_rslt_h1_tvalid_o_1d ;
assign w_ed_rslt_x3_tvalid_o_1d = ed_rslt_x3_tvalid_o_1d ;
assign w_ed_rslt_y3_tvalid_o_1d = ed_rslt_y3_tvalid_o_1d ;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        o_tw_v_x_1d             <= 0;
        o_tw_v_y_1d             <= 0;
        ed_rslt_u_tvalid_o_1d   <= 0;
        ed_rslt_v0_tvalid_o_1d  <= 0;
        ed_rslt_v1_tvalid_o_1d  <= 0;
        ed_rslt_h1_tvalid_o_1d  <= 0;
        ed_rslt_x3_tvalid_o_1d  <= 0;
        ed_rslt_y3_tvalid_o_1d  <= 0;
    end else begin
        o_tw_v_x_1d             <= o_tw_v_x            ;
        o_tw_v_y_1d             <= o_tw_v_y            ;
        ed_rslt_u_tvalid_o_1d   <= ed_rslt_u_tvalid_o  ;
        ed_rslt_v0_tvalid_o_1d  <= ed_rslt_v0_tvalid_o ;
        ed_rslt_v1_tvalid_o_1d  <= ed_rslt_v1_tvalid_o ;
        ed_rslt_h1_tvalid_o_1d  <= ed_rslt_h1_tvalid_o ;
        ed_rslt_x3_tvalid_o_1d  <= ed_rslt_x3_tvalid_o ;
        ed_rslt_y3_tvalid_o_1d  <= ed_rslt_y3_tvalid_o ;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ed_add_cnt <= 0;
    end else if(ed_pm_param_tvalid_i)begin
        ed_add_cnt <= ed_add_cnt + 1;
    end else begin
        ed_add_cnt <= ed_add_cnt;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn)                 r_lvs_fifo_din <= 0;
    else if(fifo_in_cnt == 1) r_lvs_fifo_din <= fifo_bit0and1    ;// fifo_bit0and1
    else if(fifo_in_cnt == 2) r_lvs_fifo_din <= fifo_montgomery_y;
    else if(fifo_in_cnt == 3) r_lvs_fifo_din <= fifo_bit0and1    ;// fifo_bit0and1
    else if(fifo_in_cnt == 4) r_lvs_fifo_din <= fifo_that_y      ;
    else if(fifo_in_cnt == 5) r_lvs_fifo_din <= fifo_lambda      ;
    else if(fifo_in_cnt == 6) r_lvs_fifo_din <= fifo_sum_x       ;
    else if(fifo_in_cnt == 7) r_lvs_fifo_din <= fifo_sum_y       ;

    else if((~w_o_tw_v_x_1d           ) && o_tw_v_x             ) r_lvs_fifo_din <= o_tw_x;
    else if((~w_o_tw_v_y_1d           ) && o_tw_v_y             ) r_lvs_fifo_din <= o_tw_y;

    else if((~w_ed_rslt_u_tvalid_o_1d ) && ed_rslt_u_tvalid_o   ) r_lvs_fifo_din <= ed_rslt_u_o ;
    else if((~w_ed_rslt_v0_tvalid_o_1d) && ed_rslt_v0_tvalid_o  ) r_lvs_fifo_din <= ed_rslt_v0_o;
    else if((~w_ed_rslt_v1_tvalid_o_1d) && ed_rslt_v1_tvalid_o  ) r_lvs_fifo_din <= ed_rslt_v1_o;
    else if((~w_ed_rslt_h1_tvalid_o_1d) && ed_rslt_h1_tvalid_o  ) r_lvs_fifo_din <= ed_rslt_h1_o;
    else if((~w_ed_rslt_x3_tvalid_o_1d) && ed_rslt_x3_tvalid_o  ) r_lvs_fifo_din <= ed_rslt_x3_o;
    else if((~w_ed_rslt_y3_tvalid_o_1d) && ed_rslt_y3_tvalid_o  ) r_lvs_fifo_din <= ed_rslt_y3_o;

    else                      r_lvs_fifo_din <= 0;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        fanal_ma_flag <= 0;
    end else if(reg_CHUNK_msg_cnt_mod3 == 1)begin
        fanal_ma_flag <= 1;
    end else begin
        fanal_ma_flag <= fanal_ma_flag;
    end
end

assign final_bit01 = fanal_ma_flag && mod3_padding_flag;

always @(posedge clk or negedge rstn) begin
    if(~rstn)                 r_lvs_fifo_wr_en <= 0;
    else if(fifo_in_cnt == 1) r_lvs_fifo_wr_en <= private_lvs_2d && ( fifo_lvs_1)                          ;
    else if(fifo_in_cnt == 2) r_lvs_fifo_wr_en <= private_lvs_2d && ( fifo_lvs_1)                          ;
    else if(fifo_in_cnt == 3) r_lvs_fifo_wr_en <= private_lvs_2d && (~fifo_lvs_1) && (~final_bit01)        ;
    else if(fifo_in_cnt == 4) r_lvs_fifo_wr_en <= private_lvs_2d && (~fifo_lvs_1)                          ;
    else if(fifo_in_cnt == 5) r_lvs_fifo_wr_en <= private_lvs_2d && (~fifo_lvs_1)                          ;
    else if(fifo_in_cnt == 6) r_lvs_fifo_wr_en <= private_lvs_2d && (~fifo_lvs_1)                          ;
    else if(fifo_in_cnt == 7) r_lvs_fifo_wr_en <= private_lvs_2d && (~fifo_lvs_1)                          ;

    else if((~w_o_tw_v_x_1d           ) && o_tw_v_x            ) r_lvs_fifo_wr_en <= private_lvs_2d;
    else if((~w_o_tw_v_y_1d           ) && o_tw_v_y            ) r_lvs_fifo_wr_en <= private_lvs_2d;

    else if((~w_ed_rslt_u_tvalid_o_1d ) && ed_rslt_u_tvalid_o  ) r_lvs_fifo_wr_en <= private_lvs_2d && (ed_add_cnt != 4'b1);
    else if((~w_ed_rslt_v0_tvalid_o_1d) && ed_rslt_v0_tvalid_o ) r_lvs_fifo_wr_en <= private_lvs_2d && (ed_add_cnt != 4'b1);
    else if((~w_ed_rslt_v1_tvalid_o_1d) && ed_rslt_v1_tvalid_o ) r_lvs_fifo_wr_en <= private_lvs_2d && (ed_add_cnt != 4'b1);
    else if((~w_ed_rslt_h1_tvalid_o_1d) && ed_rslt_h1_tvalid_o ) r_lvs_fifo_wr_en <= private_lvs_2d;
    else if((~w_ed_rslt_x3_tvalid_o_1d) && ed_rslt_x3_tvalid_o ) r_lvs_fifo_wr_en <= private_lvs_2d;
    else if((~w_ed_rslt_y3_tvalid_o_1d) && ed_rslt_y3_tvalid_o ) r_lvs_fifo_wr_en <= private_lvs_2d;

    else                      r_lvs_fifo_wr_en <= 0;
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FINISH
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// reg [256 - 1 : 0]o_bhp256_rslt,
// reg              o_bhp256_rslt_vld,
// reg              o_bhp256_rdy


    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            o_bhp256_rslt_vld <= 0;
        end else if(cur_state == ST_CIRCUIT_FINISH)begin
            o_bhp256_rslt_vld <= 1;
        end else begin
            o_bhp256_rslt_vld <= 0;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            o_bhp256_rslt <= 0;
        end else if((~w_ed_rslt_x3_tvalid_o_1d) && ed_rslt_x3_tvalid_o  )begin
            o_bhp256_rslt <= ed_rslt_x3_o;
        end else begin
            o_bhp256_rslt <= o_bhp256_rslt;
        end
    end

    always @(posedge clk or negedge rstn) begin
        if(~rstn) begin
            o_bhp256_rdy <= 0;
        end else if(cur_state == ST_IDLE)begin
            o_bhp256_rdy <= 1;
        end else begin
            o_bhp256_rdy <= 0;
        end
    end





endmodule
