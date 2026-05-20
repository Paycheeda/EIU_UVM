

module eth_rx_IF(
        input                 clk,
        input                 rst_n,
        
        input [7:0]         rxd,
        input                 rx_dv,
        input                 rx_er,
        
        output reg             rx_fifo_wr_en,
        output reg [7:0]     fifo_data_in,
    
        output reg             crc_first,
        output reg             crc_valid,
        output reg             crc_last,
        
        input                 crc_done_flag,
        input [31:0]         crc_calc,
        
        output reg             packet_received_corrupt_out,
        output reg [10:0]   invalid_bytes,
        output reg             rx_transaction_done_pulse,
        
        output reg [10:0]   payload_length
    );

localparam [63:0] PARAM_PREAMBLE = 64'h55_55_55_55_55_55_55_d5;

reg[63:0] preamble_word;
reg [7:0] rxd_reg1;
reg [7:0] rxd_reg2;
reg rx_dv_reg1;
reg rx_dv_reg2;
reg rx_er_reg1;
reg rx_er_reg2;

reg[10:0] byte_counter;
reg[1:0] crc_byte_count;
reg[31:0] crc_received;

reg[1:0] state;
localparam IDLE = 2'd0;
localparam CRC_CAPTURE_STATE = 2'd1;
localparam CRC_CHECK_STATE = 2'd2;
localparam ACQ_DONE_STATE = 2'd3;

reg rx_abort_active;
reg early_rx_drop_detected;
reg rx_er_seen_in_frame;

reg [15:0] udp_length;
reg [10:0] eth_packet_length;
reg eth_packet_length_valid;
reg    packet_received_corrupt_pulse;

reg [10:0] actual_fifo_writes;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        actual_fifo_writes <= 0;
    end else begin
        if (rx_transaction_done_pulse) begin
            actual_fifo_writes <= 0;
        end else if (rx_fifo_wr_en) begin
            actual_fifo_writes <= actual_fifo_writes + 1;
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        rx_dv_reg1 <= 0; rx_dv_reg2 <= 0;
        rx_er_reg1 <= 0; rx_er_reg2 <= 0;
        rxd_reg1 <= 0; rxd_reg2 <= 0;
    end else begin
        rx_dv_reg1 <= rx_dv; rx_dv_reg2 <= rx_dv_reg1;
        rx_er_reg1 <= rx_er; rx_er_reg2 <= rx_er_reg1;
        rxd_reg1 <= rxd; rxd_reg2 <= rxd_reg1;
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        fifo_data_in <= 0;
        byte_counter <= 0;
        rx_fifo_wr_en <= 0;
        preamble_word <= 0;
        early_rx_drop_detected <= 0;
        rx_er_seen_in_frame <= 0;
        rx_abort_active <= 0;
        udp_length <= 0;
        eth_packet_length <= 0;
        eth_packet_length_valid <= 0;
        payload_length <= 0;
        crc_first <= 0; crc_valid <= 0; crc_last <= 0;
    end else begin
        if(rx_dv_reg2 && byte_counter == 11'd0) rx_er_seen_in_frame <= 1'b0;
        if(rx_dv_reg2 && rx_er_reg2) rx_er_seen_in_frame <= 1'b1;
        
        if(rx_dv_reg2) begin
            if(rx_er_reg2 || rx_abort_active) begin
                rx_abort_active <= 1'b1;
                rx_fifo_wr_en <= 1'b0;
                crc_first <= 1'b0; crc_valid <= 1'b0; crc_last <= 1'b0;
                if(!rx_abort_active) early_rx_drop_detected <= 1'b1;
                else early_rx_drop_detected <= 1'b0;
            end else begin
                fifo_data_in <= rxd_reg2;
                byte_counter <= byte_counter + 1;
                if(byte_counter < 8) begin    
                    eth_packet_length_valid <= 0;
                    preamble_word <= {preamble_word[55:0] , rxd_reg2};
                    rx_fifo_wr_en <= 0;
                    crc_first <= 0; crc_valid <= 0; crc_last <= 0;
                end else if(byte_counter == 8) begin
                    rx_fifo_wr_en <= 1;
                    crc_first <= 1; crc_valid <= 1; crc_last <= 0;
                end else if (byte_counter > 8 && byte_counter < 46) begin
                    rx_fifo_wr_en <= 1;
                    crc_first <= 0; crc_valid <= 1; crc_last <= 0;
                end else if(byte_counter == 46) begin
                    udp_length[15:8] <= rxd_reg2;
                    rx_fifo_wr_en <= 1; crc_valid <= 1;
                end else if(byte_counter == 47) begin
                    udp_length[7:0] <= rxd_reg2;
                    eth_packet_length <= {udp_length[15:8], rxd_reg2} + 11'd46;
                    payload_length <= {udp_length[15:8], rxd_reg2} - 11'd8;
                    eth_packet_length_valid <= 1'b1;
                    rx_fifo_wr_en <= 1; crc_valid <= 1;
                end else if(eth_packet_length_valid && byte_counter < eth_packet_length - 5) begin
                    rx_fifo_wr_en <= 1; crc_first <= 0; crc_valid <= 1; crc_last <= 0;
                end else if(eth_packet_length_valid && byte_counter == eth_packet_length - 5) begin
                    rx_fifo_wr_en <= 1; crc_first <= 0; crc_valid <= 1; crc_last <= 1;
                end else begin
                    rx_fifo_wr_en <= 0; crc_first <= 0; crc_valid <= 0; crc_last <= 0;
                end
            end
        end else begin
            crc_first <= 0; crc_valid <= 0; crc_last <= 0;
            fifo_data_in <= 0; rx_fifo_wr_en <= 0; byte_counter <= 0;
            
            if(rx_abort_active) begin
                early_rx_drop_detected <= 1'b0;
                rx_abort_active        <= 1'b0;
            end else begin
                rx_abort_active <= 1'b0;
                // ---> THE BULLETPROOF FIX <---
                // Unconditional drop detection: If the line goes quiet while we have 
                // uncommitted writes in the payload state (IDLE), flush it immediately.
                if(actual_fifo_writes > 0 && state == IDLE && !crc_last) begin
                    early_rx_drop_detected <= 1'b1;
                end else begin
                    early_rx_drop_detected <= 1'b0;
                end
                // -----------------------------
            end
        end
    end
end

always @ (posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        packet_received_corrupt_pulse <= 0;
        packet_received_corrupt_out <= 0;
        rx_transaction_done_pulse <= 0;
        crc_byte_count <= 0; crc_received <= 0;
        invalid_bytes <= 0;
        state <= 0;
    end else begin
        packet_received_corrupt_pulse <= 0;
        packet_received_corrupt_out <= 0;
        rx_transaction_done_pulse <= 0;
        
        case(state)
            IDLE: begin
                if(early_rx_drop_detected) begin
                    invalid_bytes <= actual_fifo_writes; 
                    packet_received_corrupt_pulse <= 1;
                    crc_byte_count <= 0;
                    state <= ACQ_DONE_STATE;
                end else if(crc_last) begin
                    invalid_bytes <= 0;
                    crc_received <= {rxd_reg2, 24'd0};
                    crc_byte_count <= 1;
                    packet_received_corrupt_pulse <= 0;
                    state <= CRC_CAPTURE_STATE;
                end else begin
                    state <= IDLE;
                end
            end
            
            CRC_CAPTURE_STATE: begin
                if(rx_dv_reg2) begin
                    crc_received <= {rxd_reg2, crc_received[31:8]};
                    if(crc_byte_count < 3) begin
                        crc_byte_count <= crc_byte_count + 1;
                        state <= CRC_CAPTURE_STATE;
                    end else begin
                        crc_byte_count <= 0;
                        state <= CRC_CHECK_STATE;
                    end
                end else begin
                    invalid_bytes <= actual_fifo_writes;
                    packet_received_corrupt_pulse <= 1;
                    crc_byte_count <= 0;
                    state <= ACQ_DONE_STATE;
                end
            end
            
            CRC_CHECK_STATE: begin
                if(crc_done_flag) begin
                    if(!rx_er_seen_in_frame && crc_received == crc_calc && preamble_word == PARAM_PREAMBLE) begin
                        packet_received_corrupt_pulse <= 0;
                        state <= ACQ_DONE_STATE;
                    end else begin
                        invalid_bytes <= actual_fifo_writes;
                        packet_received_corrupt_pulse <= 1;
                        state <= ACQ_DONE_STATE;
                    end
                end else begin
                    state <= CRC_CHECK_STATE;
                end
            end
            
            ACQ_DONE_STATE: begin    
                packet_received_corrupt_out <= packet_received_corrupt_pulse;
                rx_transaction_done_pulse <= 1;
                state <= IDLE;
            end
            
            default: begin
                rx_transaction_done_pulse <= 0;
                state <= IDLE;
            end
        endcase
    end
end
always @(posedge clk) begin
    // Replace with your actual internal FIFO write enable and data signals
    if (rx_fifo_wr_en) begin
        $display("[RTL_MAC_FIFO] @%0t: Pushing %h to Internal FIFO", $time, fifo_data_in);
    end
end

endmodule