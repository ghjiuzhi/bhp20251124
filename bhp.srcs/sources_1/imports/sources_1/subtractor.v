`timescale      1ns/1ns

`define GFP_DATA_WIDTH 256

module subtractor(
    input wire [`GFP_DATA_WIDTH-1:0]            sub_a_i,
    input wire [`GFP_DATA_WIDTH-1:0]            sub_b_i,
    output reg [`GFP_DATA_WIDTH:0]              sub_rslt_o
    );

    always @ ( * ) 
    begin
        sub_rslt_o = sub_a_i - sub_b_i;
    end


endmodule