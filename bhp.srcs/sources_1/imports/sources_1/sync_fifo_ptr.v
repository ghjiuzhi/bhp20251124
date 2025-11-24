`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////

module sync_fifo_ptr #(
    parameter DATA_WIDTH = 256,
    parameter DATA_DEPTH = 5
)(
    input  wire                          i_clk,
    input  wire                          i_rstn,
    input  wire                          wr_en,
    input  wire [DATA_WIDTH-1:0]         wr_data,
    input  wire                          rd_en,
    output wire [DATA_WIDTH-1:0]         rd_data,
    output wire                          empty,
    output wire                          full,
    output wire [$clog2(DATA_DEPTH)-1:0] data_count
);

reg [$clog2(DATA_DEPTH):0] fifo_cnt;
reg [DATA_WIDTH-1:0] fifo_buffer [0:DATA_DEPTH-1];
reg [$clog2(DATA_DEPTH)-1:0] wr_addr;
reg [$clog2(DATA_DEPTH)-1:0] rd_addr;
reg [DATA_WIDTH-1:0]         rd_data_r;
assign rd_data = rd_data_r;

always @(posedge i_clk or negedge i_rstn) begin
    if (~i_rstn) begin
        wr_addr <= 0;
    end else if (wr_en && ~full) begin
        fifo_buffer[wr_addr] <= wr_data;
        if(wr_addr <= DATA_DEPTH - 2)
            wr_addr <= wr_addr + 1;
        else
            wr_addr <= 0;
    end
end

always @(posedge i_clk or negedge i_rstn) begin
    if (~i_rstn) begin
        rd_addr <= 0;
        rd_data_r <= 0;
    end else if (rd_en && ~empty) begin
        rd_data_r <= fifo_buffer[rd_addr];
        if(rd_addr <= DATA_DEPTH - 2)
            rd_addr <= rd_addr + 1;
        else
            rd_addr <= 0;
    end
end

always @(posedge i_clk or negedge i_rstn) begin
    if (~i_rstn) begin
        fifo_cnt <= 0;
    end else begin
        case ({wr_en && ~full, rd_en && ~empty})
            2'b00: fifo_cnt <= fifo_cnt;    
            2'b01: fifo_cnt <= fifo_cnt - 1;
            2'b10: fifo_cnt <= fifo_cnt + 1;
            2'b11: fifo_cnt <= fifo_cnt;    
        endcase
    end
end

assign full  = (fifo_cnt == DATA_DEPTH);
assign empty = (fifo_cnt == 0);

//
assign data_count = fifo_cnt;





endmodule