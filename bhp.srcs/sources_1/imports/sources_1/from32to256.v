`timescale 1ns/1ps

module from32to256 #(
    parameter [31:0] IN_WIDTH    = 32,
    parameter [31:0] COORD_WIDTH = 256,
    parameter [31:0] WORDS_PER_COORD = 8 // COORD_WIDTH / IN_WIDTH;
)(
    input  wire                   clk,
    input  wire                   rstn,
    input  wire [IN_WIDTH-1:0]    din,
    input  wire                   in_valid,

    output reg  [IN_WIDTH-1:0]    id_out,
    output reg  [COORD_WIDTH-1:0] x1,
    output reg  [COORD_WIDTH-1:0] y1,
    output reg  [COORD_WIDTH-1:0] x2,
    output reg  [COORD_WIDTH-1:0] y2,
    output reg  [COORD_WIDTH-1:0] x3,
    output reg  [COORD_WIDTH-1:0] y3,
    output reg  [COORD_WIDTH-1:0] x4,
    output reg  [COORD_WIDTH-1:0] y4,
    output reg                    out_valid
);

    localparam [7:0] POS_CNT_WIDTH =
        (WORDS_PER_COORD <= 32'd2  ) ? 8'd1 :
        (WORDS_PER_COORD <= 32'd4  ) ? 8'd2 :
        (WORDS_PER_COORD <= 32'd8  ) ? 8'd3 :
        (WORDS_PER_COORD <= 32'd16 ) ? 8'd4 :
        (WORDS_PER_COORD <= 32'd32 ) ? 8'd5 :
        (WORDS_PER_COORD <= 32'd64 ) ? 8'd6 :
        (WORDS_PER_COORD <= 32'd128) ? 8'd7 :
        (WORDS_PER_COORD <= 32'd256) ? 8'd8 : 8'd9;

    localparam [POS_CNT_WIDTH-1:0] POS_ZERO = {POS_CNT_WIDTH{1'b0}};
    localparam [POS_CNT_WIDTH-1:0] POS_ONE  = {{(POS_CNT_WIDTH-1){1'b0}},1'b1};
    localparam [POS_CNT_WIDTH-1:0] WPC_M1   = (WORDS_PER_COORD-1);
    localparam [1:0] S_IDLE = 2'b00;
    localparam [1:0] S_RECV = 2'b01;
    localparam [1:0] S_DROP = 2'b10;

    reg [1:0] state;
    reg [2:0] field_idx;                  // 0..7: x1,y1,x2,y2,x3,y3,x4,y4
    reg [POS_CNT_WIDTH-1:0] pos_in_field; // 0..WPC-1

    reg [IN_WIDTH-1:0] din_q;
    reg                in_valid_q;

    reg [IN_WIDTH-1:0]      w_id;
    reg [COORD_WIDTH-1:0]   w_x1, w_y1, w_x2, w_y2, w_x3, w_y3, w_x4, w_y4;

    wire [COORD_WIDTH-1:0] nx_x1 = (w_x1 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_y1 = (w_y1 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_x2 = (w_x2 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_y2 = (w_y2 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_x3 = (w_x3 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_y3 = (w_y3 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_x4 = (w_x4 << IN_WIDTH) | din_q;
    wire [COORD_WIDTH-1:0] nx_y4 = (w_y4 << IN_WIDTH) | din_q;
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            din_q      <= {IN_WIDTH{1'b0}};
            in_valid_q <= 1'b0;

            state        <= S_IDLE;
            field_idx    <= 3'd0;
            pos_in_field <= POS_ZERO;
            out_valid    <= 1'b0;

            id_out <= {IN_WIDTH{1'b0}};
            w_id   <= {IN_WIDTH{1'b0}};

            x1<=0; y1<=0; x2<=0; y2<=0; x3<=0; y3<=0; x4<=0; y4<=0;
            w_x1<=0; w_y1<=0; w_x2<=0; w_y2<=0; w_x3<=0; w_y3<=0; w_x4<=0; w_y4<=0;
        end else begin
            din_q      <= din;
            in_valid_q <= in_valid;

            out_valid  <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (in_valid_q) begin
                        w_id <= din_q;
                        w_x1<=0; w_y1<=0; w_x2<=0; w_y2<=0; w_x3<=0; w_y3<=0; w_x4<=0; w_y4<=0;
                        field_idx    <= 3'd0;
                        pos_in_field <= POS_ZERO;
                        state        <= S_RECV;
                    end
                end

                S_RECV: begin
                    if (!in_valid_q) begin
                        state <= S_DROP;
                    end else begin
                        case (field_idx)
                            3'd0: w_x1 <= nx_x1;
                            3'd1: w_y1 <= nx_y1;
                            3'd2: w_x2 <= nx_x2;
                            3'd3: w_y2 <= nx_y2;
                            3'd4: w_x3 <= nx_x3;
                            3'd5: w_y3 <= nx_y3;
                            3'd6: w_x4 <= nx_x4;
                            3'd7: w_y4 <= nx_y4;
                        endcase

                        if (pos_in_field == WPC_M1) begin
                            pos_in_field <= POS_ZERO;

                            if (field_idx == 3'd7) begin
                                id_out <= w_id;
                                x1 <= w_x1;  y1 <= w_y1;
                                x2 <= w_x2;  y2 <= w_y2;
                                x3 <= w_x3;  y3 <= w_y3;
                                x4 <= w_x4;  y4 <= nx_y4; 

                                out_valid <= 1'b1;
                                state     <= S_IDLE;     
                            end else begin
                                field_idx <= field_idx + 3'd1;
                            end
                        end else begin
                            pos_in_field <= pos_in_field + POS_ONE;
                        end
                    end
                end

                S_DROP: begin
                    if (!in_valid_q) state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule