// //`include "/home/Fei.Ma/r1cs_prj/alu_defs.vh"
// `include "../alu_defs.vh"

`define BOOL  3'b000 
`define IU8   3'b001
`define IU16  3'b010
`define IU32  3'b011
`define IU64  3'b100
`define IU128 3'b101
`define FIELD 3'b110

module cast_lossy_core (
        input          i_clk,
        input          i_rst_n,
        // input channel
        input          i_vld,
        input          i_rdy,
        input  [252:0] i_a,       // input operand
        input  [  2:0] i_size,    // in alu_defs.vh
        input          i_signed,  // signed is 1, unsigned is 0
        output         o_rdy,
        // output res channel
        output         o_res_vld,
        output [  2:0] o_size,    // check defines
        output         o_signed,  // int is 1, unsigned is 0
        output [127:0] o_res,     // output calculation result
        // output lvs channel
        output         o_lvs_vld,
        output [504:0] o_lvs      // output leaves
    );

    localparam ED_P_MIN1 = 253'h12ab655e9a2ca55660b44d1e5c37b00159aa76fed00000010a11800000000000;

    wire [252:0] cmp_tmp;

    reg  [127:0] res_r;
    reg  [504:0] all_lvs_r;
    reg  [  2:0] size_r;
    reg          sign_r;
    reg          vld_r;

    genvar i;
    generate
        for (i = 0; i < 253; i = i + 1) begin : calc_res
            if (i == 0) begin
                assign cmp_tmp[0] = i_a[i];
            end else begin
                assign cmp_tmp[i] = ED_P_MIN1[i] ? (i_a[i] & cmp_tmp[i-1]) : (i_a[i] | cmp_tmp[i-1]);
            end
        end
    endgenerate

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            res_r <= 'b0;
            all_lvs_r <= 'b0;
        end else if (i_vld & i_rdy) begin
            case(i_size)
                `IU8: res_r <= {120'b0, i_a[7:0]};
                `IU16: res_r <= {112'b0, i_a[15:0]};
                `IU32: res_r <= {96'b0, i_a[31:0]};
                `IU64: res_r <= {64'b0, i_a[63:0]};
                `IU128: res_r <= i_a[127:0];
            endcase
            all_lvs_r <= {cmp_tmp[252:1], i_a};
        end
    end

    always @(posedge i_clk or negedge i_rst_n) begin
        if (~i_rst_n) begin
            vld_r  <= 'b0;
            size_r <= 'b0;
            sign_r <= 'b0;
        end else begin
            if (i_rdy) begin
                vld_r  <= i_vld;
                size_r <= i_size;
                sign_r <= i_signed;
            end
        end
    end

    assign o_res_vld = vld_r;
    assign o_lvs_vld = vld_r;
    assign o_res = res_r;
    assign o_size = size_r;
    assign o_signed = sign_r;
    assign o_lvs = all_lvs_r;
    assign o_rdy = i_rdy;

endmodule