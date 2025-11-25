`timescale 1ns / 1ps
module bhp_256_top(
    input  wire                 clk,
    input  wire                 rstn,

    input  wire                 i_vld,
    input  wire [128 - 1 : 0]   i_data,
    input  wire [  6 - 1 : 0]   i_mode,
    input  wire [256 - 1 : 0]   i_sp_x,
    input  wire [256 - 1 : 0]   i_sp_y,
    input  wire [ 10 - 1 : 0]   i_sp_i,

    output wire [256 - 1 : 0]   o_bhp256_rslt,
    output wire                 o_bhp256_rslt_vld,

    // output wire [256 - 1 : 0]   o_lvs,
    // output wire                 o_vld,
    output wire [ 12 - 1 : 0]   o_length,
    output wire                 o_field_ena,
    // output wire                 o_last,
    output wire                 o_rdy,

    output wire [255 : 0]   lvs_fifo_din   ,
    output wire             lvs_fifo_wr_en ,

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

//     input  wire [32-1:0]        i_id,
    input  wire                 i_loop_point,
    input  wire [256 - 1 : 0]   i_x1        ,
    input  wire [256 - 1 : 0]   i_y1        ,
    // input  wire [256 - 1 : 0]   i_x2        ,
    // input  wire [256 - 1 : 0]   i_y2        ,
    // input  wire [256 - 1 : 0]   i_x3        ,
    // input  wire [256 - 1 : 0]   i_y3        ,
    // input  wire [256 - 1 : 0]   i_x4        ,
    // input  wire [256 - 1 : 0]   i_y4        ,
    output wire o_need,
    output wire [9:0] pd_addr,
    output wire mal_result_valid


    );

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg                 r_vld;
reg [128 - 1 : 0]   r_data;
reg [  6 - 1 : 0]   r_mode;
reg [256 - 1 : 0]   r_sp_x;
reg [256 - 1 : 0]   r_sp_y;
reg [ 10 - 1 : 0]   r_sp_i;

localparam ST_IDLE    = 1;
localparam ST_CIRCUIT = 2;
localparam ST_OUTPUT  = 3;
localparam ST_FINISH  = 4;
reg  [  5 - 1 : 0]      cur_state;
reg  [  5 - 1 : 0]      next_state;
reg  [ 11 - 1 : 0]      cnt_state;

reg                 r_msg_vld          ;
reg  [128 - 1 : 0]  r_msg              ;
reg  [  6 - 1 : 0]  r_msg_mode         ;
reg  [256 - 1 : 0]  r_START_POINT_X    ;
reg  [256 - 1 : 0]  r_START_POINT_Y    ;
reg  [ 10 - 1 : 0]  r_START_POINT      ;
wire                i_msg_vld          ;
wire [128 - 1 : 0]  i_msg              ;
wire [  6 - 1 : 0]  i_msg_mode         ;
wire [256 - 1 : 0]  i_START_POINT_X    ;
wire [256 - 1 : 0]  i_START_POINT_Y    ;
wire [ 10 - 1 : 0]  i_START_POINT      ;

// wire [256 - 1 : 0]   o_bhp256_rslt      ;
// wire                 o_bhp256_rslt_vld  ;
wire                 o_bhp256_rdy       ;

wire                 lvs_fifo_rd_en     ;
// wire [255 : 0]       lvs_fifo_dout      ;
wire                 lvs_fifo_full      ;
wire                 lvs_fifo_empty     ;
wire [8 : 0]         lvs_fifo_data_count;

// reg r_fifo_rd_en;

// reg ro_vld;

// reg ro_vld_1;

// reg ro_last;

reg ro_rdy;

// wire   [255 : 0] lvs_fifo_din       ;
// wire             lvs_fifo_wr_en     ;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_vld  <= 0;
        r_data <= 0;
        r_mode <= 0;
        r_sp_x <= 0;
        r_sp_y <= 0;
        r_sp_i <= 0;
    end else if(i_vld)begin
        r_vld  <= 1;
        r_data <= i_data;
        r_mode <= i_mode;
        r_sp_x <= i_sp_x;
        r_sp_y <= i_sp_y;
        r_sp_i <= i_sp_i;
    end else begin
        r_vld  <= 0;
        r_data <= r_data;
        r_mode <= r_mode;
        r_sp_x <= r_sp_x;
        r_sp_y <= r_sp_y;
        r_sp_i <= r_sp_i;
    end
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// STATE
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


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

    // always @(*) begin
    //     case (cur_state)
    //         ST_IDLE    : if(r_vld && o_bhp256_rdy && lvs_fifo_empty    ) next_state = ST_CIRCUIT; else next_state = ST_IDLE    ;
    //         ST_CIRCUIT : if(o_bhp256_rslt_vld                          ) next_state = ST_OUTPUT ; else next_state = ST_CIRCUIT ;
    //         ST_OUTPUT  : if(lvs_fifo_data_count == 1                   ) next_state = ST_FINISH ; else next_state = ST_OUTPUT  ;
    //         ST_FINISH  : if(cnt_state == 3                             ) next_state = ST_IDLE   ; else next_state = ST_FINISH  ;
    //         default    :                                                 next_state = ST_IDLE   ;
    //     endcase
    // end
    always @(*) begin
        case (cur_state)
            ST_IDLE    : if(r_vld && o_bhp256_rdy                      ) next_state = ST_CIRCUIT; else next_state = ST_IDLE    ;
            ST_CIRCUIT : if(o_bhp256_rslt_vld                          ) next_state = ST_FINISH ; else next_state = ST_CIRCUIT ;
            ST_FINISH  : if(cnt_state == 3                             ) next_state = ST_IDLE   ; else next_state = ST_FINISH  ;
            default    :                                                 next_state = ST_IDLE   ;
        endcase
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ST_CIRCUIT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign i_msg_vld  = r_msg_vld  ;
assign i_msg      = r_msg      ;
assign i_msg_mode = r_msg_mode ;
assign i_START_POINT_X = r_START_POINT_X;
assign i_START_POINT_Y = r_START_POINT_Y;
assign i_START_POINT   = r_START_POINT  ;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_msg_vld  <= 0;
        r_msg      <= 0;
        r_msg_mode <= 0;
        r_START_POINT_X <= 0;
        r_START_POINT_Y <= 0;
        r_START_POINT   <= 0;
    end else if(cur_state == ST_IDLE && next_state == ST_CIRCUIT)begin
        r_msg_vld  <= 1;
        r_msg      <= r_data;
        r_msg_mode <= r_mode;
        r_START_POINT_X <= r_sp_x;
        r_START_POINT_Y <= r_sp_y;
        r_START_POINT   <= r_sp_i;
    end else begin
        r_msg_vld  <= 0;
        r_msg      <= 0;
        r_msg_mode <= 0;
        r_START_POINT_X <= 0;
        r_START_POINT_Y <= 0;
        r_START_POINT   <= 0;
    end
end


bhp_256 u_bhp_256 (
    .clk                    (clk                         ),
    .rstn                   (rstn                        ),

    .i_msg_vld              (i_msg_vld                   ),
    .i_msg                  (i_msg                       ),
    .i_msg_mode             (i_msg_mode                  ),

    .i_START_POINT_X        (i_START_POINT_X             ),
    .i_START_POINT_Y        (i_START_POINT_Y             ),
    .i_START_POINT          (i_START_POINT               ),

    .o_bhp256_rslt          (o_bhp256_rslt               ),
    .o_bhp256_rslt_vld      (o_bhp256_rslt_vld           ),
    .o_bhp256_rdy           (o_bhp256_rdy                ),

    .lvs_fifo_din           (lvs_fifo_din                ),
    .lvs_fifo_wr_en         (lvs_fifo_wr_en              ),
    // .lvs_fifo_rd_en         (lvs_fifo_rd_en              ),
    // .lvs_fifo_dout          (lvs_fifo_dout               ),
    // .lvs_fifo_full          (lvs_fifo_full               ),
    // .lvs_fifo_empty         (lvs_fifo_empty              ),
    // .lvs_fifo_data_count    (lvs_fifo_data_count         ),
    .pause(pause),

        .top_mul0_a_i                 (top_mul0_a_i         ),
        .top_mul0_b_i                 (top_mul0_b_i         ),
        .top_mul0_ab_valid_i          (top_mul0_ab_valid_i  ),
        .top_mul0_rslt_o              (top_mul0_rslt_o      ),
        .top_mul0_rslt_valid_o        (top_mul0_rslt_valid_o),
        .top_inv_a_i                  (top_inv_a_i          ),
        .top_inv_b_i                  (top_inv_b_i          ),
        .top_inv_ab_valid_i           (top_inv_ab_valid_i   ),
        .top_inv_rslt_o               (top_inv_rslt_o       ),
        .top_inv_rslt_valid_o         (top_inv_rslt_valid_o),

//         .i_id                (i_id               ),
        .i_loop_point        (i_loop_point       ),
        .i_x1                (i_x1               ),
        .i_y1                (i_y1               ),
        // .i_x2                (i_x2               ),
        // .i_y2                (i_y2               ),
        // .i_x3                (i_x3               ),
        // .i_y3                (i_y3               ),
        // .i_x4                (i_x4               ),
        // .i_y4                (i_y4               ),
        .o_need              (o_need             ),
        .pd_addr             (pd_addr            ),
        .mal_result_valid    (mal_result_valid   )

);

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ST_OUTPUT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// assign lvs_fifo_rd_en = r_fifo_rd_en;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         r_fifo_rd_en <= 0;
//     end else if(cur_state == ST_OUTPUT)begin
//         r_fifo_rd_en <= 1;
//     end else begin
//         r_fifo_rd_en <= 0;
//     end
// end

// assign o_lvs = lvs_fifo_dout;
assign o_length = 256;

// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         r_fifo_rd_en <= 0;
//     end else if((lvs_fifo_data_count == 1) && (cur_state == ST_OUTPUT))begin
//         r_fifo_rd_en <= 0;
//     end else if((cur_state == ST_OUTPUT) && (next_state != ST_FINISH))begin
//         r_fifo_rd_en <= 1;
//     end else begin
//         r_fifo_rd_en <= 0;
//     end
// end

// assign o_vld = ro_vld && ro_vld_1;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_vld <= 0;
//     end else begin
//         ro_vld <= r_fifo_rd_en;
//     end
// end
// always @(posedge clk or negedge rstn) begin
    // if(~rstn) begin
        // ro_vld_1 <= 0;
    // end else begin
        // ro_vld_1 <= ro_vld;
    // end
// end

assign o_field_ena = 1;

// assign o_last = ro_last;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_last <= 0;
//     end else if((lvs_fifo_data_count == 1) && (cur_state == ST_OUTPUT))begin
//         ro_last <= 1;
//     end else begin
//         ro_last <= 0;
//     end
// end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// o_rdy
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
assign o_rdy = ro_rdy;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ro_rdy <= 0;
    end else if(cur_state == ST_IDLE)begin
        ro_rdy <= 1;
    end else begin
        ro_rdy <= 0;
    end
end




// lvs_fifo u_lvs_fifo (
//   .clk          (clk                 ),                 // input  wire clk
//   .srst         (~rstn               ),                 // input  wire srst
//   .din          (lvs_fifo_din        ),                 // input  wire [255 : 0]    din
//   .wr_en        (lvs_fifo_wr_en      ),                 // input  wire              wr_en
//   .rd_en        (lvs_fifo_rd_en      ),                 // input  wire              rd_en
//   .dout         (lvs_fifo_dout       ),                 // output wire [255 : 0]    dout
//   .full         (lvs_fifo_full       ),                 // output wire              full
//   .empty        (lvs_fifo_empty      ),                 // output wire              empty
//   .data_count   (lvs_fifo_data_count )                  // output wire [8 : 0]      data_count
// );




endmodule
