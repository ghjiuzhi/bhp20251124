`timescale 1ns / 1ps

// `define BOOL  3'b000
// `define IU8   3'b001
// `define IU16  3'b010
// `define IU32  3'b011
// `define IU64  3'b100
// `define IU128 3'b101
// `define FIELD 3'b110

// `define VIVADO_IP
`define REG_IP

module bhp_with_lossy #(
    parameter QID_WIDTH = 8
)(
    input  wire                 clk,
    input  wire                 rstn,

    // input channel
    input  wire           i_vld,
    output wire           o_rdy,
    input  wire [127:0]   i_a,
    input  wire [  2:0]   i_size,       // in alu_defs.vh
    input  wire           i_signed,     // signed is 1, unsigned is 0
    input  wire [256-1:0] i_sp_x,
    input  wire [256-1:0] i_sp_y,
    input  wire [ 10-1:0] i_sp_i,

    // output lvs channel
    input  wire         i_lvs_rdy,    // indicate if downstream is ready
    output wire         o_lvs_vld,    // indicate if leaves is valid
    output wire [255:0] o_lvs,        // leaves
    output wire         o_field_ena,  // indicate if is a 253-bit field
    output wire         o_last,       // last leaf
    output wire [  7:0] o_length,     // leaves num in o_lvs

    // Output result channel
    // input  wire         i_res_rdy   ,
    output wire         o_res_vld   ,
    output wire [127:0] o_res       ,
    output wire [  2:0] o_size      ,
    output wire         o_signed    ,


    // input  wire [256-1:0] i_sp_x,
    // input  wire [256-1:0] i_sp_y,
    // input  wire [ 10-1:0] i_sp_i,
    output wire           top_request,//pluse
    // input  wire [31:0]    bc_din     ,
    // input  wire           bc_in_valid,
    input  wire           rx_o_v ,
    input  wire [256-1:0] rx_o_x1,
    input  wire [256-1:0] rx_o_y1,
    output wire [9:0]     pd_addr,

    output reg    [4:0] cur_state,      //todo // to delete //just for test
    output wire   [2:0] ft_data_count,   //todo // to delete //just for test
    
     //QID Interface
    input wire [QID_WIDTH-1:0]  i_qid,
    output reg [QID_WIDTH-1:0]  o_qid,
	
    // [New] Cast Lossy Interface (Externalized to TB)
    // Data sent to TB (Originally inputs to cast_lossy)
    output wire         top_los_i_vld,
    output wire [252:0] top_los_i_a,
    output wire [2:0]   top_los_i_size,
    output wire         top_los_i_signed,
    
    // Data received from TB (Originally outputs from cast_lossy)
    input  wire         top_los_o_rdy,
    input  wire         top_los_o_res_vld,
    input  wire [127:0] top_los_o_res,
    input  wire [2:0]   top_los_o_size,
    input  wire         top_los_o_signed,
    
    input  wire         top_los_o_lvs_vld,
    input  wire [255:0] top_los_o_lvs,
    input  wire         top_los_o_field_ena,
    input  wire         top_los_o_last,
    input  wire [7:0]   top_los_o_length,
    
    // External multiplier interface
    // Data sent to TB (Output)
    output wire [255:0] top_mul0_a_i,        // Multiplier A
    output wire [255:0] top_mul0_b_i,        // Multiplier B
    output wire         top_mul0_ab_valid_i, // Input valid signal
    
    // Data received from TB (Input)
    input  wire [255:0] top_mul0_rslt_o,       // Calculation result
    input  wire         top_mul0_rslt_valid_o,  // Result valid signal

    output wire [256-1:0] top_inv_a             ,
    output wire [256-1:0] top_inv_b             ,
    output wire           top_inv_ab_valid      ,
    input  wire [256-1:0] top_inv_rslt          ,
    input  wire           top_inv_rslt_valid    



    );

// wire         i_vld      ;
// wire         o_rdy      ;
// wire [127:0] i_data     ;
// wire [  2:0] i_size     ;
// wire         i_signed   ;

reg          ri_vld      ;
reg  [255:0] ri_data     ;
reg  [  2:0] ri_size     ;
reg          ri_signed   ;

localparam ST_IDLE      = 1;
localparam ST_INIT      = 2;
localparam ST_BHP       = 3;
localparam ST_LOSSY     = 4;
localparam ST_LOSSY_BUF = 5;
localparam ST_OUTPUT    = 6;
localparam ST_RST       = 7;
localparam ST_FINISH    = 8;

    localparam B8   = 3'b001;
    localparam B16  = 3'b010;
    localparam B32  = 3'b011;
    localparam B64  = 3'b100;
    localparam B128 = 3'b101;

// reg  [  5 - 1 : 0]      cur_state;
reg  [  5 - 1 : 0]      next_state;
reg  [ 11 - 1 : 0]      cnt_state;

wire                bhp_i_vld  ;
wire [128 - 1 : 0]  bhp_i_data ;
wire [  6 - 1 : 0]  bhp_i_mode ;
reg                 bhp_ri_vld ;
reg  [128 - 1 : 0]  bhp_ri_data;
reg  [  6 - 1 : 0]  bhp_ri_mode;

wire [256 - 1 : 0]   bhp_o_bhp256_rslt      ;
wire                 bhp_o_bhp256_rslt_vld  ;
wire [ 12 - 1 : 0]   bhp_o_length           ;
wire                 bhp_o_field_ena        ;
wire                 bhp_o_last             ;
wire                 bhp_o_rdy              ;

reg  [256 - 1 : 0]   bhp_ro_bhp256_rslt     ;
reg                  bhp_ro_bhp256_rslt_vld ;

wire         los_i_vld       ;
wire         los_o_rdy       ;
wire [252:0] los_i_a         ;
wire [  2:0] los_i_size      ;
wire         los_i_signed    ;

reg          los_ri_vld       ;
reg  [252:0] los_ri_a         ;
reg  [  2:0] los_ri_size      ;
reg          los_ri_signed    ;

// reg          los_i_res_rdy   ;
wire         los_o_res_vld   ;
wire [127:0] los_o_res       ;
wire [  2:0] los_o_size      ;
wire         los_o_signed    ;
// Output LVS channel
// reg          los_i_lvs_rdy   ;
wire         los_o_lvs_vld   ;
wire [255:0] los_o_lvs       ;
wire         los_o_field_ena ;
wire         los_o_last      ;
wire [  7:0] los_o_length    ;

parameter P_MOD  = 256'h12ab_655e_9a2c_a556_60b4_4d1e_5c37_b001_59aa_76fe_d000_0001_0a11_8000_0000_0001;
wire [256-1:0] top_mul0_a             ;
wire [256-1:0] top_mul0_b             ;
wire           top_mul0_ab_valid      ;
wire [256-1:0] top_mul0_rslt          ;
wire           top_mul0_rslt_valid    ;

// wire [256-1:0] top_inv_a             ;
// wire [256-1:0] top_inv_b             ;
// wire           top_inv_ab_valid      ;
// wire [256-1:0] top_inv_rslt          ;
// wire           top_inv_rslt_valid    ;

wire [255 : 0]  fifo_i_din        ;
wire            fifo_i_wr_en      ;
wire            fifo_i_rd_en      ;
wire [255 : 0]  fifo_o_dout       ;
wire            fifo_o_full       ;
wire            fifo_o_empty      ;
wire [8 : 0]    fifo_o_data_count ;

reg  [255 : 0]  fifo_ri_din        ;
reg             fifo_ri_wr_en      ;
// reg             fifo_ri_rd_en      ;
// reg  [255 : 0]  fifo_o_dout       ;
// reg             fifo_o_full       ;
// reg             fifo_o_empty      ;
// reg  [8 : 0]    fifo_o_data_count ;

reg [8 : 0] total_lvs_cnt;

// wire         i_lvs_rdy  ;
// wire         o_lvs_vld  ;
// wire [255:0] o_lvs      ;
// wire         o_field_ena;
// wire         o_last     ;
// wire [  8:0] o_length   ;

reg          ro_lvs_vld  ;
reg [255:0]  ro_lvs      ;
reg          ro_field_ena;
// reg          ro_last     ;
reg [  7:0]  ro_length   ;

reg [8:0] left_lvs_cnt;

// reg fifo_ri_rd_en_1d;

wire o_lvs_vld_1;
reg  o_lvs_vld_2;

// wire         i_res_rdy   ;
// wire         o_res_vld   ;
// wire [127:0] o_res       ;
// wire [  2:0] o_size      ;
// wire         o_signed    ;

reg          ro_res_vld   ;
reg  [127:0] ro_res       ;
reg  [  2:0] ro_size      ;
reg          ro_signed    ;

reg if_res_out;

reg ro_res_vld_0d;

reg ro_rdy;

wire [32 -1:0] bc_o_id          ;
wire           bc_o_loop_point  ;
wire [256-1:0] bc_o_x1          ;
wire [256-1:0] bc_o_y1          ;
wire [256-1:0] bc_o_x2          ;
wire [256-1:0] bc_o_y2          ;
wire [256-1:0] bc_o_x3          ;
wire [256-1:0] bc_o_y3          ;
wire [256-1:0] bc_o_x4          ;
wire [256-1:0] bc_o_y4          ;
wire           bc_o_change_start;
wire [256-1:0] bc_o_x1_start    ;
wire [256-1:0] bc_o_y1_start    ;
wire           bc_o_need        ;

wire top_request_bc;

reg            bc_ro_change_start   ;
reg  [256-1:0] bc_ro_x1_start       ;
reg  [256-1:0] bc_ro_y1_start       ;

wire [255 : 0]   lvs_fifo_din   ;
wire             lvs_fifo_wr_en ;

wire [255 : 0] ft_din       ;
wire           ft_wr_en     ;
wire           ft_rd_en     ;
wire [255 : 0] ft_dout      ;
wire           ft_full      ;
wire           ft_empty     ;
// wire [2 : 0]   ft_data_count;
reg ft_rd_en_1d;

wire pause;// fifo not empty <=> output valid
reg  r_pause;
reg  [4:0] cnt_pause;

reg  no_rdy_lvs_out_flag;
reg  no_rdy_lvs_out_flag_1d;
wire no_rdy_lvs_out_flag_posedge;

wire lvs_temp_out;
reg  lvs_temp_out_r;

wire mal_result_valid;
reg  r_mal_result_valid;

wire [255 : 0] test_dout      ;
wire           test_full      ;
wire           test_empty     ;
wire [3 : 0]   test_data_count;

wire top_request_temp;
reg  top_request_temp_1d;
wire top_request_temp_posedge;
reg  top_request_r;

reg  [10:0] lvs_cnt    ;
wire [10:0] lvs_max    ;

wire [127:0] i_data;

reg         top_mul0_ab_valid_r;
reg  [255:0]top_mul0_a_r;
reg  [255:0]top_mul0_b_r;

wire        KBM_ab_v ;
wire [255:0]KBM_a    ;
wire [255:0]KBM_b    ;

wire         i_res_rdy;

reg [256-1:0] ri_sp_x;
reg [256-1:0] ri_sp_y;
reg [ 10-1:0] ri_sp_i;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// INPUT
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Add QID Latching Logic
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
    o_qid <= {QID_WIDTH{1'b0}};
    end else begin
        if (i_vld && o_rdy) begin
            o_qid <= i_qid;
        end
    end
end
    
assign i_data = i_a;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ri_vld    <= 0;
        ri_data   <= 0;
        ri_size   <= 0;
        ri_signed <= 0;
        ri_sp_x   <= 0;
        ri_sp_y   <= 0;
        ri_sp_i   <= 0;
    end else if(i_vld && o_rdy)begin
        ri_vld    <= 1;
        // ri_data   <= i_data  ;
        if      (i_size == B8  )  ri_data <= { i_data[127:8],  {
                                                                i_data[0], i_data[1], i_data[2], i_data[3],
                                                                i_data[4], i_data[5], i_data[6], i_data[7] } };

        else if (i_size == B16 )  ri_data <= { i_data[127:16], {
                                                                i_data[0],  i_data[1],  i_data[2],  i_data[3],
                                                                i_data[4],  i_data[5],  i_data[6],  i_data[7],
                                                                i_data[8],  i_data[9],  i_data[10], i_data[11],
                                                                i_data[12], i_data[13], i_data[14], i_data[15] } };

        else if (i_size == B32 )  ri_data <= { i_data[127:32], {
                                                                i_data[0],  i_data[1],  i_data[2],  i_data[3],
                                                                i_data[4],  i_data[5],  i_data[6],  i_data[7],
                                                                i_data[8],  i_data[9],  i_data[10], i_data[11],
                                                                i_data[12], i_data[13], i_data[14], i_data[15],
                                                                i_data[16], i_data[17], i_data[18], i_data[19],
                                                                i_data[20], i_data[21], i_data[22], i_data[23],
                                                                i_data[24], i_data[25], i_data[26], i_data[27],
                                                                i_data[28], i_data[29], i_data[30], i_data[31] } };

        else if (i_size == B64 )  ri_data <= { i_data[127:64], {
                                                                i_data[0],  i_data[1],  i_data[2],  i_data[3],
                                                                i_data[4],  i_data[5],  i_data[6],  i_data[7],
                                                                i_data[8],  i_data[9],  i_data[10], i_data[11],
                                                                i_data[12], i_data[13], i_data[14], i_data[15],
                                                                i_data[16], i_data[17], i_data[18], i_data[19],
                                                                i_data[20], i_data[21], i_data[22], i_data[23],
                                                                i_data[24], i_data[25], i_data[26], i_data[27],
                                                                i_data[28], i_data[29], i_data[30], i_data[31],
                                                                i_data[32], i_data[33], i_data[34], i_data[35],
                                                                i_data[36], i_data[37], i_data[38], i_data[39],
                                                                i_data[40], i_data[41], i_data[42], i_data[43],
                                                                i_data[44], i_data[45], i_data[46], i_data[47],
                                                                i_data[48], i_data[49], i_data[50], i_data[51],
                                                                i_data[52], i_data[53], i_data[54], i_data[55],
                                                                i_data[56], i_data[57], i_data[58], i_data[59],
                                                                i_data[60], i_data[61], i_data[62], i_data[63] } };

        else if (i_size == B128)  ri_data <= {
                                                                i_data[0],   i_data[1],   i_data[2],   i_data[3],
                                                                i_data[4],   i_data[5],   i_data[6],   i_data[7],
                                                                i_data[8],   i_data[9],   i_data[10],  i_data[11],
                                                                i_data[12],  i_data[13],  i_data[14],  i_data[15],
                                                                i_data[16],  i_data[17],  i_data[18],  i_data[19],
                                                                i_data[20],  i_data[21],  i_data[22],  i_data[23],
                                                                i_data[24],  i_data[25],  i_data[26],  i_data[27],
                                                                i_data[28],  i_data[29],  i_data[30],  i_data[31],
                                                                i_data[32],  i_data[33],  i_data[34],  i_data[35],
                                                                i_data[36],  i_data[37],  i_data[38],  i_data[39],
                                                                i_data[40],  i_data[41],  i_data[42],  i_data[43],
                                                                i_data[44],  i_data[45],  i_data[46],  i_data[47],
                                                                i_data[48],  i_data[49],  i_data[50],  i_data[51],
                                                                i_data[52],  i_data[53],  i_data[54],  i_data[55],
                                                                i_data[56],  i_data[57],  i_data[58],  i_data[59],
                                                                i_data[60],  i_data[61],  i_data[62],  i_data[63],
                                                                i_data[64],  i_data[65],  i_data[66],  i_data[67],
                                                                i_data[68],  i_data[69],  i_data[70],  i_data[71],
                                                                i_data[72],  i_data[73],  i_data[74],  i_data[75],
                                                                i_data[76],  i_data[77],  i_data[78],  i_data[79],
                                                                i_data[80],  i_data[81],  i_data[82],  i_data[83],
                                                                i_data[84],  i_data[85],  i_data[86],  i_data[87],
                                                                i_data[88],  i_data[89],  i_data[90],  i_data[91],
                                                                i_data[92],  i_data[93],  i_data[94],  i_data[95],
                                                                i_data[96],  i_data[97],  i_data[98],  i_data[99],
                                                                i_data[100], i_data[101], i_data[102], i_data[103],
                                                                i_data[104], i_data[105], i_data[106], i_data[107],
                                                                i_data[108], i_data[109], i_data[110], i_data[111],
                                                                i_data[112], i_data[113], i_data[114], i_data[115],
                                                                i_data[116], i_data[117], i_data[118], i_data[119],
                                                                i_data[120], i_data[121], i_data[122], i_data[123],
                                                                i_data[124], i_data[125], i_data[126], i_data[127] };
        else  ri_data <= i_data;
        ri_size   <= i_size  ;
        ri_signed <= i_signed;
        ri_sp_x   <= i_sp_x;
        ri_sp_y   <= i_sp_y;
        ri_sp_i   <= i_sp_i;
    end else begin
        ri_vld    <= 0;
        ri_data   <= ri_data  ;
        ri_size   <= ri_size  ;
        ri_signed <= ri_signed;
        ri_sp_x   <= ri_sp_x;
        ri_sp_y   <= ri_sp_y;
        ri_sp_i   <= ri_sp_i;
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

    always @(*) begin
        case (cur_state)
            ST_IDLE     : if(ri_vld                            ) next_state = ST_INIT       ; else next_state = ST_IDLE         ;
            ST_INIT     : if(bc_ro_change_start                ) next_state = ST_BHP        ; else next_state = ST_INIT         ;
            ST_BHP      : if(bhp_ro_bhp256_rslt_vld            ) next_state = ST_LOSSY      ; else next_state = ST_BHP          ;
            ST_LOSSY    : if(los_o_rdy                         ) next_state = ST_LOSSY_BUF  ; else next_state = ST_LOSSY        ;
            ST_LOSSY_BUF: if(cnt_state == 5                    ) next_state = ST_OUTPUT     ; else next_state = ST_LOSSY_BUF    ;//todo
            // ST_OUTPUT   : if((left_lvs_cnt == 0) && if_res_out ) next_state = ST_RST        ; else next_state = ST_OUTPUT       ;
            ST_OUTPUT   : if(ft_empty && if_res_out            ) next_state = ST_RST        ; else next_state = ST_OUTPUT       ;
            ST_RST      : if(cnt_state == 3                    ) next_state = ST_FINISH     ; else next_state = ST_RST          ;
            ST_FINISH   : if(cnt_state == 2                    ) next_state = ST_IDLE       ; else next_state = ST_FINISH       ;
            default     :                                        next_state = ST_IDLE       ;
        endcase
    end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// bhp_256_top
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

assign bhp_i_vld  = bhp_ri_vld ;
assign bhp_i_data = bhp_ri_data;
assign bhp_i_mode = bhp_ri_mode;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        // bhp_ri_vld  <= 0;
        bhp_ri_data <= 0;
        bhp_ri_mode <= 0;
    end else if(ri_vld)begin
        // bhp_ri_vld  <= 1;
        bhp_ri_data <= ri_data;
        if(ri_signed)
            bhp_ri_mode <= ri_size;
        else
            bhp_ri_mode <= ri_size + 5;
        // I 1:8;  2:16;  3:32;   4:64;   5:128
        // U 6:8;  7:16;  8:32;   9:64;  10:128
    end else begin
        // bhp_ri_vld  <= 0;
        bhp_ri_data <= bhp_ri_data;
        bhp_ri_mode <= bhp_ri_mode;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        bhp_ri_vld <= 0;
    end else if((next_state == ST_BHP) && (cur_state == ST_INIT))begin
        bhp_ri_vld <= 1;
    end else begin
        bhp_ri_vld <= 0;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        bhp_ro_bhp256_rslt     <= 0;
        bhp_ro_bhp256_rslt_vld <= 0;
    end else if(bhp_o_bhp256_rslt_vld)begin
        bhp_ro_bhp256_rslt <= bhp_o_bhp256_rslt;
        bhp_ro_bhp256_rslt_vld <= 1;
    end else begin
        bhp_ro_bhp256_rslt <= bhp_ro_bhp256_rslt;
        bhp_ro_bhp256_rslt_vld <= 0;
    end
end

reg bhp_rst;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        bhp_rst <= 0;
    end else if(cur_state == ST_RST)begin
        bhp_rst <= 0;
    end else begin
        bhp_rst <= rstn;
    end
end

    bhp_256_top uut_bhp_256_top (
        .clk                (clk                    ),
        .rstn               (bhp_rst                ),
        .i_vld              (bhp_i_vld              ),
        .i_data             (bhp_i_data             ),
        .i_mode             (bhp_i_mode             ),
        // .i_sp_x             (256'b0                 ),
        // .i_sp_y             (256'b0                 ),
        // .i_sp_i             ( 10'b0                 ),
        // .i_sp_x             (256'd4405413365422220568237000915304400287543352561343753572223565637763382054477                 ),
        // .i_sp_y             (256'd2204662042624091946242497476583881364078081899192253257555670568450074315326                 ),
        // .i_sp_i             ( 10'd1                                                                                            ),
        // .i_sp_x             (i_sp_x     ),
        // .i_sp_y             (i_sp_y     ),
        // .i_sp_i             (i_sp_i     ),
        .i_sp_x             (bc_ro_x1_start        ),
        .i_sp_y             (bc_ro_y1_start        ),
        //.i_sp_i             (bc_o_id[10-1:0]       ),
        .i_sp_i             (ri_sp_i            ),

        .o_bhp256_rslt      (bhp_o_bhp256_rslt      ),
        .o_bhp256_rslt_vld  (bhp_o_bhp256_rslt_vld  ),

        .o_length           (bhp_o_length           ),
        .o_field_ena        (bhp_o_field_ena        ),
        .o_rdy              (bhp_o_rdy              ),
        .lvs_fifo_din       (lvs_fifo_din           ),
        .lvs_fifo_wr_en     (lvs_fifo_wr_en         ),

        .pause(pause),

        .top_mul0_a_i                 (top_mul0_a             ),
        .top_mul0_b_i                 (top_mul0_b             ),
        .top_mul0_ab_valid_i          (top_mul0_ab_valid      ),
        .top_mul0_rslt_o              (top_mul0_rslt          ),
        .top_mul0_rslt_valid_o        (top_mul0_rslt_valid    ),
        .top_inv_a_i                  (top_inv_a              ),
        .top_inv_b_i                  (top_inv_b              ),
        .top_inv_ab_valid_i           (top_inv_ab_valid       ),
        .top_inv_rslt_o               (top_inv_rslt           ),
        .top_inv_rslt_valid_o         (top_inv_rslt_valid     ),

//         .i_id(bc_o_id),
        .i_loop_point        (bc_o_loop_point  ),
        .i_x1                (bc_o_x1          ),
        .i_y1                (bc_o_y1          ),
        // .i_x2                (bc_o_x2          ),
        // .i_y2                (bc_o_y2          ),
        // .i_x3                (bc_o_x3          ),
        // .i_y3                (bc_o_y3          ),
        // .i_x4                (bc_o_x4          ),
        // .i_y4                (bc_o_y4          ),
        .o_need              (bc_o_need        ),
        .pd_addr             (pd_addr          ),
        .mal_result_valid    (mal_result_valid )



    );

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// cast_lossy
/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Input channel


assign los_i_vld     = los_ri_vld    ;
assign los_i_a       = los_ri_a      ;
assign los_i_size    = los_ri_size   ;
assign los_i_signed  = los_ri_signed ;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        los_ri_a <= 0;
    end else if(bhp_ro_bhp256_rslt_vld && (~bhp_o_bhp256_rslt_vld))begin
        los_ri_a <= bhp_ro_bhp256_rslt;// [252:0] <= [256 - 1 : 0]
    end else begin
        los_ri_a <= los_ri_a;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        los_ri_size   <= 0;
        los_ri_signed <= 0;
    end else if(ri_vld)begin
        los_ri_size   <= ri_size  ;
        los_ri_signed <= ri_signed;
    end else begin
        los_ri_size   <= los_ri_size  ;
        los_ri_signed <= los_ri_signed;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        los_ri_vld <= 0;
    // end else if((next_state == ST_LOSSY) && (cur_state == ST_BHP))begin
    end else if(bhp_ro_bhp256_rslt_vld && (~bhp_o_bhp256_rslt_vld))begin
        los_ri_vld <= 1;
    end else begin
        los_ri_vld <= 0;
    end
end

// Output result channel


    // Instantiate DUT
    cast_lossy uut_cast_lossy (
        .i_clk       (clk                   ),
        .i_rst_n     (rstn                  ),
        .i_vld       (los_i_vld             ),
        .o_rdy       (los_o_rdy             ),
        .i_a         (los_i_a               ),
        .i_size      (los_i_size            ),
        .i_signed    (los_i_signed          ),

        .i_res_rdy   (1'b1                  ),
        .o_res_vld   (los_o_res_vld         ),
        .o_res       (los_o_res             ),
        .o_size      (los_o_size            ),
        .o_signed    (los_o_signed          ),

        .i_lvs_rdy   (1'b1                  ),
        .o_lvs_vld   (los_o_lvs_vld         ),
        .o_lvs       (los_o_lvs             ),
        .o_field_ena (los_o_field_ena       ),
        .o_last      (los_o_last            ),
        .o_length    (los_o_length          )
    );




/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// field_mul_gfp
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // field_mul_gfp #(
    //     .P_MOD                  (P_MOD)
    // )
    // u0_field_mul_top(
    //     .fm_clk_i               (clk                    ),
    //     .fm_rstn_i              (rstn                   ),
    //     .fm_a_i                 (top_mul0_a             ),
    //     .fm_b_i                 (top_mul0_b             ),
    //     .fm_ab_valid_i          (top_mul0_ab_valid      ),
    //     .fm_rslt_o              (top_mul0_rslt          ),
    //     .fm_rslt_valid_o        (top_mul0_rslt_valid    )
    // );




assign KBM_ab_v  = top_mul0_ab_valid_r;
assign KBM_a     = top_mul0_a_r;
assign KBM_b     = top_mul0_b_r;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        top_mul0_ab_valid_r <= 0;
        top_mul0_a_r <= 0;
        top_mul0_b_r <= 0;
    end else if(top_mul0_ab_valid)begin
        top_mul0_ab_valid_r <= 1;
        top_mul0_a_r <= top_mul0_a;
        top_mul0_b_r <= top_mul0_b;
    end else begin
        top_mul0_ab_valid_r <= 0;
        top_mul0_a_r <= top_mul0_a_r;
        top_mul0_b_r <= top_mul0_b_r;
    end
end

/*
    KOM_Bar_MM_15cc u_KOM_Bar_MM_15cc
    (
        .clk            (clk),
        .rstn           (rstn),
        .i_vld          (KBM_ab_v    ),
        .i_a            (KBM_a       ),
        .i_b            (KBM_b       ),
        .o_rslt_vld     (top_mul0_rslt_valid),
        .o_rslt         (top_mul0_rslt[256-4:0])
    );
    assign top_mul0_rslt[256-1:256-3] = 3'b0;

// -------------------------------------------------------------------------
// Revised to fullpipe fp_KOM_Bar_MM
// -------------------------------------------------------------------------
fp_KOM_Bar_MM #(
        .MUL_WIDTH  ( 256 ),
        .CID_WIDTH  ( 6   ), // Default value is sufficient, Stream ID is unused
        .PIPE_DEPTH ( 11  )  // Use default pipeline depth
    ) u_fp_KOM_Bar_MM (
        .clk        ( clk  ),
        .rstn       ( rstn ),
        
        // Data input
        .i_vld      ( KBM_ab_v ), 
        .i_a        ( KBM_a    ),
        .i_b        ( KBM_b    ),
        
        // New port i_cid: Context ID is not involved in upper logic, connected to 0
        .i_cid      ( 6'd0     ), 

        // Result output
        .o_rslt_vld ( top_mul0_rslt_valid ),
        
        // Result data: Output width is [252:0] (i.e., 253 bits), consistent with the old module
        .o_rslt     ( top_mul0_rslt[256-4:0] ),
        
        // New port o_cid: Output Stream ID, logic does not need it, leave unconnected
        .o_cid      (          )
    );

    // Retain this zero-padding line, as o_rslt is only 253 bits wide
    assign top_mul0_rslt[256-1:256-3] = 3'b0;


    KOM_Bar_MM #(
        .MUL_WIDTH  ( 256 )
    ) u_KOM_Bar_MM_fullpipe1 (  // Instance name can be this for easy identification
        .clk        ( clk  ),
        .rstn       ( rstn ),
        
        // Data inputs
        .i_vld      ( KBM_ab_v ), 
        .i_a        ( KBM_a    ),
        .i_b        ( KBM_b    ),
        
        // Result output
        .o_rslt_vld ( top_mul0_rslt_valid ),
        
        // Result data: The output width of this module is [252:0]
        .o_rslt     ( top_mul0_rslt[256-4:0] )
    );

    // High-bit zero-padding logic
    assign top_mul0_rslt[256-1:256-3] = 3'b0;
	
*/	

    // DUT Internal Signals <==> Top-Level Ports

    // 1. Output Direction: Send internally prepared operands to the ports
    // KBM_a/b/v are stable signals after register pipelining, ideal for direct output
    assign top_mul0_a_i        = KBM_a;       
    assign top_mul0_b_i        = KBM_b;       
    assign top_mul0_ab_valid_i = KBM_ab_v;    

    // 2. Input Direction: Connect results from the ports back to internal logic
    // The internal state machine waits for top_mul0_rslt_valid and reads top_mul0_rslt
    assign top_mul0_rslt       = top_mul0_rslt_o;        
    assign top_mul0_rslt_valid = top_mul0_rslt_valid_o;  



/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// field_inv_gfp
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


    // field_inv_gfp #(
    //     .P_MOD                  (P_MOD)
    // )
    // u_field_inv_gfp(
    //     .fi_clk_i               (clk                    ),
    //     .fi_rstn_i              (rstn                   ),
    //     .fi_a_i                 (top_inv_a              ),
    //     .fi_b_i                 (top_inv_b              ),
    //     .fi_ab_valid_i          (top_inv_ab_valid       ),
    //     .fi_rslt_o              (top_inv_rslt           ),
    //     .fi_rslt_valid_o        (top_inv_rslt_valid     )
    // );




















/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// fifo_bhplossy_lvs
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


assign fifo_i_din   = fifo_ri_din  ;
assign fifo_i_wr_en = fifo_ri_wr_en;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        fifo_ri_din   <= 0;
        fifo_ri_wr_en <= 0;
        total_lvs_cnt <= 0;
    end else if(cur_state == ST_IDLE)begin
        fifo_ri_din   <= 0;
        fifo_ri_wr_en <= 0;
        total_lvs_cnt <= 0;
    end else if(lvs_fifo_wr_en)begin
        fifo_ri_din   <= lvs_fifo_din;
        fifo_ri_wr_en <= 1;
        total_lvs_cnt <= total_lvs_cnt + 1;
    end else if(los_o_lvs_vld)begin
        fifo_ri_din   <= los_o_lvs;
        fifo_ri_wr_en <= 1;
        total_lvs_cnt <= total_lvs_cnt + 1;
    end else begin
        fifo_ri_din   <= fifo_ri_din;
        fifo_ri_wr_en <= 0;
        total_lvs_cnt <= total_lvs_cnt;
    end
end



// fifo_bhplossy_lvs u_fifo_bhplossy_lvs (
//   .clk              (clk               ),            // input  wire clk
//   .srst             (~rstn             ),            // input  wire srst
//   .din              (fifo_i_din        ),            // input  wire [255 : 0] din
//   .wr_en            (fifo_i_wr_en      ),            // input  wire wr_en
//   .rd_en            (fifo_i_rd_en      ),            // input  wire rd_en
//   .dout             (fifo_o_dout       ),            // output wire [255 : 0] dout
//   .full             (fifo_o_full       ),            // output wire full
//   .empty            (fifo_o_empty      ),            // output wire empty
//   .data_count       (fifo_o_data_count )             // output wire [8 : 0] data_count
// );
assign fifo_o_dout = fifo_i_din;
// assign fifo_i_rd_en = fifo_i_wr_en;


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ST_OUTPUT lvs
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


// assign o_field_ena = ro_field_ena;
// assign o_last      = ro_last     ;
// assign o_length    = ro_length   ;
assign o_length    = (~o_lvs_vld) ? 0 :
                     (lvs_cnt == lvs_max - 1) ? 8'hf8 :
                     (lvs_cnt == lvs_max - 2) ? 8'hff :
                     0;



always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        left_lvs_cnt <= 0;
    end else if(cur_state == ST_IDLE)begin
        left_lvs_cnt <= 0;
    end else if((cur_state != ST_OUTPUT) && (next_state == ST_OUTPUT))begin
        left_lvs_cnt <= total_lvs_cnt;
    end else if(left_lvs_cnt == 0)begin
        left_lvs_cnt <= 0;
    end else if(i_lvs_rdy)begin
        left_lvs_cnt <= left_lvs_cnt - 1;
    end else begin
        left_lvs_cnt <= left_lvs_cnt;
    end
end

// assign fifo_i_rd_en = fifo_ri_rd_en;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         fifo_ri_rd_en <= 0;
//     end else if((cur_state != ST_OUTPUT) && (next_state == ST_OUTPUT))begin
//         fifo_ri_rd_en <= 1;
//     end else if((cur_state == ST_OUTPUT) && (i_lvs_rdy) && (left_lvs_cnt != 0))begin
//         fifo_ri_rd_en <= 1;
//     end else begin
//         fifo_ri_rd_en <= 0;
//     end
// end
assign fifo_i_rd_en = ((cur_state != ST_LOSSY ) && (next_state == ST_LOSSY )) ? 1 :
                      ((cur_state != ST_OUTPUT) && (next_state == ST_OUTPUT)) ? 1 :
                      ((cur_state == ST_OUTPUT) && (i_lvs_rdy) && (left_lvs_cnt != 0)) ? 1 : 0;



// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         fifo_ri_rd_en_1d <= 0;
//     end else begin
//         fifo_ri_rd_en_1d <= fifo_ri_rd_en;
//     end
// end

// assign o_lvs       = ro_lvs      ;
// assign o_lvs_vld   = ro_lvs_vld  ;
// assign o_field_ena = ro_lvs_vld  ;
// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_lvs     <= 0;
//         ro_lvs_vld <= 0;
//     end else if(left_lvs_cnt != 0)begin
//         ro_lvs     <= fifo_o_dout;
//         ro_lvs_vld <= 1;
//     end else begin
//         ro_lvs     <= ro_lvs;
//         ro_lvs_vld <= 0;
//     end
// end
// assign o_lvs = fifo_o_dout;
assign o_lvs_vld_1 = (left_lvs_cnt != 0)?1:0;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        o_lvs_vld_2 <= 0;
    end else begin
        o_lvs_vld_2 <= o_lvs_vld_1;
    end
end
// assign o_lvs_vld = o_lvs_vld_1 && o_lvs_vld_2;
// assign o_lvs_vld = fifo_i_wr_en;
// assign o_field_ena = o_lvs_vld && (o_lvs != 1) && (o_lvs != 0);
assign o_field_ena = o_lvs_vld && (lvs_cnt != lvs_max - 1) && (lvs_cnt != lvs_max - 2);

// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_length <= 0;
//     end else begin
//         ro_length <= 252;
//     end
// end

// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_last <= 0;
//     end else if((left_lvs_cnt == 2) && i_lvs_rdy)begin
//         ro_last <= 1;
//     end else if(i_lvs_rdy)begin
//         ro_last <= 0;
//     end else begin
//         ro_last <= ro_last;
//     end
// end

assign lvs_max = (ri_size == B8  ) ? 23  + 2 :
                 (ri_size == B16 ) ? 34  + 2 :
                 (ri_size == B32 ) ? 63  + 2 :
                 (ri_size == B64 ) ? 114 + 2 :
                 (ri_size == B128) ? 228 + 2 :
                 0;
assign o_last  = o_lvs_vld && ((lvs_cnt == lvs_max - 1) ? 1 : 0);

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        lvs_cnt <= 0;
    end else if(lvs_cnt == lvs_max)begin
        lvs_cnt <= 0;
    end else if(o_lvs_vld && i_lvs_rdy)begin
        lvs_cnt <= lvs_cnt + 1;
    end else begin
        lvs_cnt <= lvs_cnt;
    end
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// ST_OUTPUT res
/////////////////////////////////////////////////////////////////////////////////////////////////////////////


assign o_res_vld   = ro_res_vld ;
assign o_res       = ro_res     ;
assign o_size      = ro_size    ;
assign o_signed    = ro_signed  ;

assign i_res_rdy = 1;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        if_res_out <= 0;
    end else if((cur_state == ST_OUTPUT) && i_res_rdy)begin
        if_res_out <= 1;
    end else if(los_o_res_vld)begin
        if_res_out <= 0;
    end else if(cur_state == ST_IDLE)begin
        if_res_out <= 0;
    end else begin
        if_res_out <= if_res_out;
    end
end

// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_res_vld_0d <= 0;
//     end else if((cur_state == ST_OUTPUT) && (~if_res_out))begin
//         ro_res_vld_0d <= 1;
//     end else begin
//         ro_res_vld_0d <= 0;
//     end
// end
// always @(posedge clk or negedge rstn)
    // if(~rstn) ro_res_vld <= 0;
    // else      ro_res_vld <= ro_res_vld_0d;


// always @(posedge clk or negedge rstn) begin
//     if(~rstn) begin
//         ro_res_vld <= 0;
//     end else if(los_o_res_vld)begin
//         ro_res_vld <= 1;
//     end else if(if_res_out || ((cur_state == ST_OUTPUT) && i_res_rdy))begin
//         ro_res_vld <= 0;
//     end else begin
//         ro_res_vld <= ro_res_vld;
//     end
// end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ro_res_vld <= 0;
    end else if(los_o_res_vld)begin
        ro_res_vld <= 1;
    end else if(ro_res_vld)begin
        ro_res_vld <= 0;
    end else begin
        ro_res_vld <= ro_res_vld;
    end
end



always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ro_res <= 0;
    end else if(los_o_res_vld)begin
        ro_res <= los_o_res;
    end else if(if_res_out || ((cur_state == ST_OUTPUT) && i_res_rdy))begin
        ro_res <= 0;
    end else begin
        ro_res <= ro_res;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ro_size   <= 0;
        ro_signed <= 0;
    end else if(cur_state == ST_IDLE)begin
        ro_size   <= 0;
        ro_signed <= 0;
    end else if(cur_state == ST_BHP)begin
        ro_size   <= ri_size    ;
        ro_signed <= ri_signed  ;
    end else begin
        ro_size   <= ro_size  ;
        ro_signed <= ro_signed;
    end
end


/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// o_rdy
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

assign o_rdy = ro_rdy;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        // ro_rdy <= 1;
        ro_rdy <= 0;
    end else if((cur_state == ST_IDLE) && (next_state == ST_IDLE) && los_o_rdy && bhp_o_rdy)begin
        ro_rdy <= 1;
    end else begin
        ro_rdy <= 0;
    end
end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////
// broadcast
/////////////////////////////////////////////////////////////////////////////////////////////////////////////

// fromrxto256 u_fromrxto256(

assign top_request_bc = bc_o_need;
assign bc_o_loop_point = rx_o_v;
assign bc_o_x1 = rx_o_x1;
assign bc_o_y1 = rx_o_y1;

// assign top_request = top_request_bc || (cur_state == ST_INIT);
// assign top_request_temp = top_request_bc || (cur_state == ST_INIT);
assign top_request_temp = top_request_bc;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        top_request_temp_1d <= 0;
    end else begin
        top_request_temp_1d <= top_request_temp;
    end
end

assign top_request_temp_posedge = top_request_temp && (~top_request_temp_1d);

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        top_request_r <= 0;
    end else if(top_request_temp_posedge)begin
        top_request_r <= 1;
		
		/*
    // end else if(bc_o_loop_point || bc_o_change_start)begin
    end else if(bc_o_loop_point)begin
        top_request_r <= 0;
    end else begin
        top_request_r <= top_request_r;
    end
end

*/
    end else if(bhp_ro_bhp256_rslt_vld) begin
        // 当最终计算结果有效时，强制停止请求发送。
        // 如果没有这一行，下面的 ST_BHP 判断可能会导致请求永远停不下来。
        top_request_r <= 0;
	end else if(bc_o_loop_point)begin	
		if(cur_state == ST_BHP)
            top_request_r <= 1;
        else
            top_request_r <= 0; // 在非计算状态下，维持“收完即停”的原逻辑
            
    end else begin
        top_request_r <= top_request_r;
    end
end
		
	/*	
    // end else if(bc_o_loop_point || bc_o_change_start)begin
    end else if(bc_o_loop_point)begin
        // 【修改点】：收到回复后，不直接置0，而是检查是否还需要数据
        // 如果 top_request_temp 为 1 (表示内部还需要数据)，则保持 top_request_r 为 1
        // 这样当 bc_o_loop_point 变回 0 时，top_request 会立即拉高，发起下一次请求
        top_request_r <= top_request_temp; 
    end else begin
        top_request_r <= top_request_r;
    end
end	
*/

// assign top_request = top_request_r && (~(bc_o_loop_point || bc_o_change_start));
assign top_request = top_request_r && (~(bc_o_loop_point));

/*
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        bc_ro_change_start  <= 0;
        bc_ro_x1_start      <= 0;
        bc_ro_y1_start      <= 0;
    end else if(bc_o_change_start) begin
        bc_ro_change_start  <= 1;
        bc_ro_x1_start      <= bc_o_x1_start;
        bc_ro_y1_start      <= bc_o_y1_start;
    end else begin
        bc_ro_change_start  <= 0;
        bc_ro_x1_start      <= bc_ro_x1_start;
        bc_ro_y1_start      <= bc_ro_y1_start;
    end
end
*/



always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        bc_ro_change_start  <= 0;
        bc_ro_x1_start      <= 0;
        bc_ro_y1_start      <= 0;
    end else if(ri_vld)begin
        bc_ro_change_start  <= 1;
        bc_ro_x1_start      <= ri_sp_x;
        bc_ro_y1_start      <= ri_sp_y;
    end else begin
        bc_ro_change_start  <= bc_ro_change_start;
        bc_ro_x1_start      <= ri_sp_x;
        bc_ro_y1_start      <= ri_sp_y;
    end
end





`ifdef VIVADO_IP
fifo_256_temp u_fifo_256_temp (
  .clk          (clk               ),       // input  wire clk
  .srst         (~rstn             ),       // input  wire srst
  .din          (ft_din            ),       // input  wire [255 : 0] ft_din       ;
  .wr_en        (ft_wr_en          ),       // input  wire           ft_wr_en     ;
  .rd_en        (ft_rd_en          ),       // input  wire           ft_rd_en     ;
  .dout         (ft_dout           ),       // output wire [255 : 0] ft_dout      ;
  .full         (ft_full           ),       // output wire           ft_full      ;
  .empty        (ft_empty          ),       // output wire           ft_empty     ;
  .data_count   (ft_data_count     )        // output wire [8 : 0]   ft_data_count;  // 位宽不准硿
);
`elsif REG_IP
sync_fifo_ptr
#(
    .DATA_WIDTH ( 256 ),
    .DATA_DEPTH ( 5   ) // goal : 5
)
u_sync_fifo_ptr (
    .i_clk      ( clk           ),
    .i_rstn     ( rstn          ),
    .wr_en      ( ft_wr_en      ),
    .wr_data    ( ft_din        ),
    .rd_en      ( ft_rd_en      ),
    .rd_data    ( ft_dout       ),
    .empty      ( ft_empty      ),
    .full       ( ft_full       ),
    .data_count ( ft_data_count )
);
`else // comp
sync_fifo_ptr
#(
    .DATA_WIDTH ( 256 ),
    .DATA_DEPTH ( 5   )
)
u_sync_fifo_ptr (
    .i_clk      ( clk           ),
    .i_rstn     ( rstn          ),
    .wr_en      ( ft_wr_en      ),
    .wr_data    ( ft_din        ),
    .rd_en      ( ft_rd_en      ),
    .rd_data    ( ft_dout       ),
    .empty      ( ft_empty      ),
    .full       ( ft_full       ),
    .data_count ( ft_data_count )
);
fifo_256_temp u_fifo_256_temp (
  .clk          (clk                 ),       // input  wire clk
  .srst         (~rstn               ),       // input  wire srst
  .din          (ft_din              ),       // input  wire [255 : 0] ft_din       ;
  .wr_en        (ft_wr_en            ),       // input  wire           ft_wr_en     ;
  .rd_en        (ft_rd_en            ),       // input  wire           ft_rd_en     ;
  .dout         (test_dout           ),       // output wire [255 : 0] ft_dout      ;
  .full         (test_full           ),       // output wire           ft_full      ;
  .empty        (test_empty          ),       // output wire           ft_empty     ;
  .data_count   (test_data_count     )        // output wire [8 : 0]   ft_data_count;  // 位宽不准硿
);
`endif


// reg  r_pause;
// reg  [4:0] cnt_pause;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        cnt_pause <= 0;
    end else if(cnt_pause == 12)begin
        cnt_pause <= 0;
    end else if(cnt_pause != 0)begin
        cnt_pause <= cnt_pause + 1;
    end else if((~ft_empty) || mal_result_valid)begin
    // end else if(~ft_empty)begin
        cnt_pause <= 1;
    end else begin
        cnt_pause <= 0;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_pause <= 0;
    // end else if(mal_result_valid)begin
        // r_pause <= 1;
    end else if(cnt_pause != 0)begin
        r_pause <= 1;
    end else begin
        r_pause <= 0;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_mal_result_valid <= 0;
    end else begin
        r_mal_result_valid <= mal_result_valid;
    end
end

// assign pause     = ~ft_empty;
// assign pause     = (~ft_empty) || r_pause || mal_result_valid || r_mal_result_valid;
// assign pause     = (~ft_empty) || r_pause || r_mal_result_valid
assign pause     = (~ft_empty) || r_pause;
assign ft_din    = fifo_o_dout;
assign ft_wr_en  = fifo_i_wr_en;
// assign ft_rd_en  = (i_lvs_rdy && (~ft_empty)) || (no_rdy_lvs_out_flag_posedge && (~lvs_temp_out_r));
assign o_lvs     = ft_dout;

assign lvs_temp_out = i_lvs_rdy && o_lvs_vld && ft_rd_en;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        lvs_temp_out_r <= 0;
    end else if(lvs_temp_out)begin
        lvs_temp_out_r <= 1;
    end else if(i_lvs_rdy)begin
        lvs_temp_out_r <= 0;
    end else begin
        lvs_temp_out_r <= lvs_temp_out_r;
    end
end


// while not i_lvs_rdy, 1 lvs need.
assign no_rdy_lvs_out_flag_posedge = no_rdy_lvs_out_flag && (~no_rdy_lvs_out_flag_1d);
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        no_rdy_lvs_out_flag <= 0;
    end else if((~i_lvs_rdy) && (~ft_empty))begin
        no_rdy_lvs_out_flag <= 1;
    end else if(i_lvs_rdy)begin
        no_rdy_lvs_out_flag <= 0;
    end else begin
        no_rdy_lvs_out_flag <= no_rdy_lvs_out_flag;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        no_rdy_lvs_out_flag_1d <= 0;
    end else begin
        no_rdy_lvs_out_flag_1d <= no_rdy_lvs_out_flag;
    end
end



always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        ft_rd_en_1d <= 0;
    end else begin
        ft_rd_en_1d <= (~ft_empty);
    end
end

// ft_empty but not i_lvs_rdy;
// assign o_lvs_vld = ft_rd_en_1d;



// sync_fifo_ptr
// #(
//     .DATA_WIDTH ( 256 ),
//     .DATA_DEPTH ( 5   ) // goal : 5
// )
// u_sync_fifo_ptr (
//     .i_clk      ( clk           ),
//     .i_rstn     ( rstn          ),
//     .wr_en      ( ft_wr_en      ),
//     .wr_data    ( ft_din        ),
//     .rd_en      ( ft_rd_en      ),
//     .rd_data    ( ft_dout       ),
//     .empty      ( ft_empty      ),
//     .full       ( ft_full       ),
//     .data_count ( ft_data_count )
// );



reg       temp_ft_rd_en;
reg       temp_ft_rd_en_1d;
reg       temp_out_flag;
reg       temp_lvs_vld;
reg [4:0] temp_out_cnt ;

assign o_lvs_vld = temp_lvs_vld;

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        temp_lvs_vld <= 0;
    end else if(ft_rd_en) begin
        temp_lvs_vld <= 1;
    end else if(i_lvs_rdy) begin
        temp_lvs_vld <= 0;
    end else begin
        temp_lvs_vld <= temp_lvs_vld;
    end
end

assign ft_rd_en = temp_ft_rd_en && temp_ft_rd_en_1d;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        temp_out_flag <= 1;
    end else if(temp_ft_rd_en) begin
        temp_out_flag <= 0;
    end else if(i_lvs_rdy) begin
        temp_out_flag <= 1;
    end else begin
        temp_out_flag <= temp_out_flag;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        temp_ft_rd_en <= 0;
    else if((~ft_empty) && temp_out_flag && (temp_out_cnt == 0))
        temp_ft_rd_en <= 1;
    else if(~temp_out_flag)
        temp_ft_rd_en <= 0;
    else
        temp_ft_rd_en <= temp_ft_rd_en;
end

always @(posedge clk or negedge rstn) begin : proc_temp_ft_rd_en_1d
    if(~rstn) begin
        temp_ft_rd_en_1d <= 0;
    end else begin
        temp_ft_rd_en_1d <= temp_ft_rd_en;
    end
end
always @(posedge clk or negedge rstn) begin : proc_temp_out_cnt
    if(~rstn) begin
        temp_out_cnt <= 0;
    end else if(temp_ft_rd_en)begin
        temp_out_cnt <= 1;
    end else if(temp_out_cnt == 10)begin
        temp_out_cnt <= 0;
    end else if(temp_out_cnt != 0)begin
        temp_out_cnt <= temp_out_cnt + 1;
    end else begin
        temp_out_cnt <= temp_out_cnt;
    end
end


endmodule
