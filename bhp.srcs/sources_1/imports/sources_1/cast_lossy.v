//`include "/home/Fei.Ma/r1cs_prj/alu_defs.vh"
// `include "../alu_defs.vh"

`define BOOL  3'b000 
`define IU8   3'b001
`define IU16  3'b010
`define IU32  3'b011
`define IU64  3'b100
`define IU128 3'b101
`define FIELD 3'b110

module cast_lossy (
    input          i_clk,
    input          i_rst_n,
    // input channel
    input          i_vld,
    output         o_rdy,
    input  [252:0] i_a,          // input operand
    input  [  2:0] i_size,       // in alu_defs.vh
    input          i_signed,     // signed is 1, unsigned is 0
    // output res channel
    input          i_res_rdy,    // indicate if downstream is ready
    output         o_res_vld,    // indicate if res is valid
    output [127:0] o_res,        // calculation result
    output [  2:0] o_size,       // in alu_defs.vh
    output         o_signed,     // signed is 1, unsigned is 0
    // output lvs channel
    input          i_lvs_rdy,    // indicate if downstream is ready
    output         o_lvs_vld,    // indicate if leaves is valid
    output [255:0] o_lvs,        // leaves
    output         o_field_ena,  // indicate if is a 253-bit field
    output         o_last,       // last leaf
    output [  7:0] o_length      // leaves num in o_lvs
);

    wire         core_vld_i;
    wire         core_rdy_i;
    wire         core_rdy_o;
    wire         core_res_vld_o;
    wire [127:0] core_res;
    wire [  2:0] core_size;
    wire         core_signed;
    wire [504:0] core_lvs;
    wire         core_lvs_vld_o;
    wire         res_trans_done;
    wire         lvs_trans_done;
    wire         trans_rdy;

    reg          res_vld_r;
    reg  [  7:0] lvs_num_r;
    reg  [  7:0] lvs_index_r;
    reg  [255:0] lvs_r;
    reg          lvs_vld_r;
    reg          field_ena_r;
    reg  [  7:0] length_r;
    reg          last_r;
    reg          start_r;

    //-------------------------- arith ------------------------------
    // pipeline 1 cycle
    cast_lossy_core u_cast_lossy_core (
        .i_clk    (i_clk),
        .i_rst_n  (i_rst_n),
        .i_vld    (core_vld_i),
        .i_rdy    (core_rdy_i),
        .i_a      (i_a),
        .i_size   (i_size),
        .i_signed (i_signed),
        .o_rdy    (core_rdy_o),
        .o_res_vld(core_res_vld_o),
        .o_size   (core_size),
        .o_signed (core_signed),
        .o_res    (core_res),
        .o_lvs_vld(core_lvs_vld_o),
        .o_lvs    (core_lvs)
    );

    //-------------------------- handshake --------------------------
    assign core_vld_i = i_vld;
    assign res_trans_done = ~res_vld_r |
                            (res_vld_r & i_res_rdy);
    assign lvs_trans_done = ~lvs_vld_r |
                            (lvs_vld_r & 
                                (lvs_index_r == lvs_num_r) &
                                i_lvs_rdy);
    assign trans_rdy = res_trans_done & lvs_trans_done;
    assign core_rdy_i = (~core_res_vld_o & trans_rdy) |
                        (core_res_vld_o & trans_rdy & start_r);

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            start_r <= 1'b0;
        end else begin
            if (core_res_vld_o & ~start_r) begin
                start_r <= 1'b1;
            end else if (core_rdy_i) begin
                start_r <= 1'b0;
            end
        end
    end

    // calculate total lvs num
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            lvs_num_r <= 'd0;
        end else if (core_res_vld_o) begin
            lvs_num_r <= 'd1;  // always 2 lvs
        end
    end

    // handshake with downstream and count lvs has been output
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            lvs_index_r <= 'd0;
        end else begin
            if (lvs_vld_r & i_lvs_rdy) begin
                if (lvs_index_r == lvs_num_r) lvs_index_r <= 'd0;
                else lvs_index_r <= lvs_index_r + 1'd1;
            end
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            lvs_vld_r <= 1'b0;
        end else begin
            if (core_lvs_vld_o & ~lvs_vld_r & ~start_r) begin
                lvs_vld_r <= 1'b1;
            end else if (i_lvs_rdy & (lvs_index_r == lvs_num_r)) begin
                lvs_vld_r <= 1'b0;
            end
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            res_vld_r <= 1'b0;
        end else begin
            if (core_res_vld_o & ~res_vld_r & ~start_r) begin
                res_vld_r <= 1'b1;
            end else if (i_res_rdy) begin
                res_vld_r <= 1'b0;
            end
        end
    end

    // lvs data and flags
    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            lvs_r <= 'b0;
            field_ena_r <= 'b0;
            length_r <= 'b0;
            last_r <= 'b0;
        end else begin
            if (core_lvs_vld_o & ~lvs_vld_r) begin // first leaf
                case (core_size)
                    `IU8, `IU16, `IU32, `IU64, `IU128: begin
                        lvs_r <= core_lvs[255:0];
                        field_ena_r <= 1'b0;
                        length_r <= 8'd255;
                        last_r <= 1'b0;
                    end

                    default: begin
                        lvs_r <= lvs_r;
                        field_ena_r <= field_ena_r;
                        length_r <= length_r;
                        last_r <= last_r;
                    end
                endcase
                
            end
            else if (lvs_vld_r & i_lvs_rdy) begin  // later
                case (lvs_index_r)
                    'd0: begin
                        lvs_r <= {7'b0, core_lvs[504:256]};
                        field_ena_r <= 1'b0;
                        length_r <= 8'd248;
                        last_r <= 1'b1;
                    end

                    default: begin
                        lvs_r <= lvs_r;
                        field_ena_r <= field_ena_r;
                        length_r <= length_r;
                        last_r <= last_r;
                    end
                endcase
            end
        end
    end

    assign o_rdy = core_rdy_o;
    assign o_res_vld = res_vld_r;
    assign o_res = core_res;
    assign o_lvs_vld = lvs_vld_r;
    assign o_size = core_size;
    assign o_signed = core_signed;
    assign o_lvs = lvs_r;
    assign o_field_ena = field_ena_r;
    assign o_last = last_r;
    assign o_length = length_r;

endmodule