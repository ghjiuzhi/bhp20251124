`timescale 1ns/1ps

module fromrxto256 #(
    parameter [31:0] IN_WIDTH    = 32,
    parameter [31:0] COORD_WIDTH = 256,
    parameter [31:0] WORDS_PER_COORD = 8 // COORD_WIDTH / IN_WIDTH;
)(
    input  wire                   clk,
    input  wire                   rstn,
    input  wire [IN_WIDTH-1:0]    din,
    input  wire                   in_valid,

    output wire [IN_WIDTH-1:0]    o_id,
    output wire                   o_loop_point,
    output wire [COORD_WIDTH-1:0] o_x1,
    output wire [COORD_WIDTH-1:0] o_y1,
    output wire [COORD_WIDTH-1:0] o_x2,
    output wire [COORD_WIDTH-1:0] o_y2,
    output wire [COORD_WIDTH-1:0] o_x3,
    output wire [COORD_WIDTH-1:0] o_y3,
    output wire [COORD_WIDTH-1:0] o_x4,
    output wire [COORD_WIDTH-1:0] o_y4,

    output wire                   o_change_start,//pluse
    output wire [COORD_WIDTH-1:0] o_x1_start,
    output wire [COORD_WIDTH-1:0] o_y1_start,

    input  wire                   i_need,
    output wire                   top_request //pluse
);
// wire                   clk      ;
// wire                   rstn     ;
// wire [IN_WIDTH-1:0]    din      ;
// wire                   in_valid ;

wire  [IN_WIDTH-1:0]    w_id_out   ;
wire  [COORD_WIDTH-1:0] w_x1       ;
wire  [COORD_WIDTH-1:0] w_y1       ;
wire  [COORD_WIDTH-1:0] w_x2       ;
wire  [COORD_WIDTH-1:0] w_y2       ;
wire  [COORD_WIDTH-1:0] w_x3       ;
wire  [COORD_WIDTH-1:0] w_y3       ;
wire  [COORD_WIDTH-1:0] w_x4       ;
wire  [COORD_WIDTH-1:0] w_y4       ;
wire                    w_out_valid;
reg   [IN_WIDTH-1:0]    r_id_out   ;
reg   [COORD_WIDTH-1:0] r_x1       ;
reg   [COORD_WIDTH-1:0] r_y1       ;
reg   [COORD_WIDTH-1:0] r_x2       ;
reg   [COORD_WIDTH-1:0] r_y2       ;
reg   [COORD_WIDTH-1:0] r_x3       ;
reg   [COORD_WIDTH-1:0] r_y3       ;
reg   [COORD_WIDTH-1:0] r_x4       ;
reg   [COORD_WIDTH-1:0] r_y4       ;
reg                     r_out_valid;

reg change_start;
reg loop_point;

assign o_loop_point = loop_point;
assign o_x1 = r_x1;
assign o_y1 = r_y1;
assign o_x2 = r_x2;
assign o_y2 = r_y2;
assign o_x3 = r_x3;
assign o_y3 = r_y3;
assign o_x4 = r_x4;
assign o_y4 = r_y4;
assign o_change_start = change_start;
assign o_x1_start = r_x1;
assign o_y1_start = r_y1;

assign top_request = (~in_valid) && i_need;

assign o_id = w_id_out;


from32to256 u_from32to256(
    .clk        (clk      ),
    .rstn       (rstn     ),
    .din        (din      ),
    .in_valid   (in_valid ),

    .id_out     (w_id_out    ),
    .x1         (w_x1        ),
    .y1         (w_y1        ),
    .x2         (w_x2        ),
    .y2         (w_y2        ),
    .x3         (w_x3        ),
    .y3         (w_y3        ),
    .x4         (w_x4        ),
    .y4         (w_y4        ),
    .out_valid  (w_out_valid )
);

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        r_id_out    <= 0;
        r_x1        <= 0;
        r_y1        <= 0;
        r_x2        <= 0;
        r_y2        <= 0;
        r_x3        <= 0;
        r_y3        <= 0;
        r_x4        <= 0;
        r_y4        <= 0;
        r_out_valid <= 0;
    end else if(w_out_valid) begin
        r_id_out    <= {1'b0,w_id_out[IN_WIDTH-2:0]};
        r_x1        <= w_x1    ;
        r_y1        <= w_y1    ;
        r_x2        <= w_x2    ;
        r_y2        <= w_y2    ;
        r_x3        <= w_x3    ;
        r_y3        <= w_y3    ;
        r_x4        <= w_x4    ;
        r_y4        <= w_y4    ;
        r_out_valid <= 1;
    end else begin
        r_id_out    <= r_id_out;
        r_x1        <= r_x1    ;
        r_y1        <= r_y1    ;
        r_x2        <= r_x2    ;
        r_y2        <= r_y2    ;
        r_x3        <= r_x3    ;
        r_y3        <= r_y3    ;
        r_x4        <= r_x4    ;
        r_y4        <= r_y4    ;
        r_out_valid <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        change_start <= 0;
    end else if(w_out_valid && (w_id_out[23:16] == 0))begin
        change_start <= w_id_out[IN_WIDTH-1];
    end else begin
        change_start <= 0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        loop_point <= 0;
    end else if(w_out_valid && (w_id_out[IN_WIDTH-1] == 0)  && (w_id_out[23:16] == 0))begin
        loop_point <= 1;
    end else begin
        loop_point <= 0;
    end
end


endmodule













