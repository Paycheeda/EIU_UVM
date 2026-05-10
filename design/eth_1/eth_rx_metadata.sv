module eth_rx_metadata(

        input           clk,
        input           rst_n,

        input           rx_transaction_done_pulse,
        input           packet_received_corrupt_pulse,
        input  [10:0]   payload_length,
        input  [10:0]   invalid_bytes,

        input           fifo_rd_en,
        output [22:0]   fifo_data_out,
        output          fifo_empty,
        output          fifo_full,

        output reg      metadata_overflow_pulse

    );

wire [22:0] fifo_data_in;
wire        fifo_wr_en;

assign fifo_data_in = {
                        packet_received_corrupt_pulse,  // [22]
                        invalid_bytes,                  // [21:11]
                        payload_length                  // [10:0]
                      };

assign fifo_wr_en = rx_transaction_done_pulse && !fifo_full;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        metadata_overflow_pulse <= 1'b0;
    end
    else
    begin
        metadata_overflow_pulse <= 1'b0;
        if (rx_transaction_done_pulse && fifo_full)
        begin
            metadata_overflow_pulse <= 1'b1;
        end
    end
end

dual_port_FIFO #(
        .PARAM_DATA_WIDTH(23),
        .PARAM_FIFO_SIZE ("18Kb")
) metadata_fifo (
        .rst_n      (rst_n),
        .wr_clk     (clk),
        .data_in    (fifo_data_in),
        .wr_en      (fifo_wr_en),

        .rd_clk     (clk),
        .rd_en      (fifo_rd_en),
        .data_out   (fifo_data_out),

        .fifo_full  (fifo_full),
        .fifo_empty (fifo_empty)
);

endmodule