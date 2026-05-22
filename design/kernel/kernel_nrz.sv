module kernel_nrz(

        input                       clk,
        input                       clk_eth,
        input                       rst_n,

        input                       bkp_prg_mode_on,
        input                       clk_20MHz,
        input                       data_in_nrz,

        output                      config_done_pulse_eth_nrz,
        input                       config_done_pulse,
        input [1:0]                 tx_bpw_eth_nrz,
        input [10:0]                tx_payload_length_eth_nrz,
        input                       tx_zero_endian_eth_nrz,
        input [11:0]                tx_sync_word1_eth_nrz,
        input [11:0]                tx_sync_word2_eth_nrz,

        output [10:0]               tx_payload_length_actual,

        output wire                 eth_tx_start_pulse_eth_nrz,
        output reg                  tx_fifo_wr_en_eth_nrz,
        output reg [7:0]            tx_fifo_data_in_eth_nrz

);

// =====================================================================================
// Configuration done latch in 64 MHz kernel clock domain
// =====================================================================================

reg kernel_config_done;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        kernel_config_done <= 1'b0;
    else if(config_done_pulse)
        kernel_config_done <= 1'b1;
end

// =====================================================================================
// Configuration values
// These are static after configuration. Program mode disables NRZ processing.
// =====================================================================================

wire [1:0]  tx_bpw;
wire [10:0] tx_payload_internal;
wire        tx_zero_endian;
wire [11:0] tx_sync_word1;
wire [11:0] tx_sync_word2;

assign tx_bpw              = (kernel_config_done) ? tx_bpw_eth_nrz             : 2'd0;
assign tx_payload_internal = (kernel_config_done) ? tx_payload_length_eth_nrz  : 11'd0;
assign tx_zero_endian      = (kernel_config_done) ? tx_zero_endian_eth_nrz     : 1'b0;
assign tx_sync_word1       = (kernel_config_done) ? tx_sync_word1_eth_nrz      : 12'd0;
assign tx_sync_word2       = (kernel_config_done) ? tx_sync_word2_eth_nrz      : 12'd0;

assign tx_payload_length_actual = (tx_bpw == 2'd0) ? tx_payload_internal : (tx_payload_internal << 1);

wire [10:0] payload_words_after_sync;
assign payload_words_after_sync = (tx_payload_internal > 11'd2) ? (tx_payload_internal - 11'd2) : 11'd0;

// =====================================================================================
// CDC: control bits into 20 MHz and 64 MHz domains
// =====================================================================================

wire kernel_config_done_sync_20;
wire bkp_prg_mode_on_sync_20;
wire bkp_prg_mode_on_sync_64;

cdc_bit_sync u_kernel_config_done_sync_20 (
    .dst_clk  (clk_20MHz),
    .rst_n    (rst_n),
    .async_in (kernel_config_done),
    .sync_out (kernel_config_done_sync_20)
);

cdc_bit_sync u_bkp_prg_mode_on_sync_20 (
    .dst_clk  (clk_20MHz),
    .rst_n    (rst_n),
    .async_in (bkp_prg_mode_on),
    .sync_out (bkp_prg_mode_on_sync_20)
);

cdc_bit_sync u_bkp_prg_mode_on_sync_64 (
    .dst_clk  (clk),
    .rst_n    (rst_n),
    .async_in (bkp_prg_mode_on),
    .sync_out (bkp_prg_mode_on_sync_64)
);

// =====================================================================================
// 20 MHz serial NRZ sync detector and payload word capture
// =====================================================================================

localparam NRZ_SEARCH_SYNC1_20  = 2'd0;
localparam NRZ_CAPTURE_SYNC2_20 = 2'd1;
localparam NRZ_CAPTURE_PAYLOAD_20 = 2'd2;

reg [1:0]  nrz_state_20;
reg [11:0] sync1_shift_reg_20;
reg [11:0] sync2_shift_reg_20;
reg [11:0] payload_shift_reg_20;
reg [3:0]  sync2_bit_counter_20;
reg [3:0]  payload_bit_counter_20;
reg [10:0] payload_word_count_20;

reg        sync_word1_detected_20;
reg        sync_word2_detected_20;
reg        sync_locked_20;

reg        sync_acquired_pulse_20;
reg        payload_word_valid_20;
reg [11:0] payload_word_20;

wire [11:0] sync1_shift_next_20;
wire [11:0] sync2_shift_next_20;
wire [11:0] payload_shift_next_20;

assign sync1_shift_next_20   = {sync1_shift_reg_20[10:0], data_in_nrz};
assign sync2_shift_next_20   = {sync2_shift_reg_20[10:0], data_in_nrz};
assign payload_shift_next_20 = {payload_shift_reg_20[10:0], data_in_nrz};

wire [3:0] bpw_last_count_20;
assign bpw_last_count_20 = (tx_bpw == 2'd0) ? 4'd7  :
                           (tx_bpw == 2'd1) ? 4'd8  :
                           (tx_bpw == 2'd2) ? 4'd9  :
                                              4'd11;

wire sync_word1_match_20;
wire sync_word2_match_20;

assign sync_word1_match_20 =
        (tx_bpw == 2'd0) ? (sync1_shift_next_20[7:0]  == tx_sync_word1[7:0])  :
        (tx_bpw == 2'd1) ? (sync1_shift_next_20[8:0]  == tx_sync_word1[8:0])  :
        (tx_bpw == 2'd2) ? (sync1_shift_next_20[9:0]  == tx_sync_word1[9:0])  :
                           (sync1_shift_next_20[11:0] == tx_sync_word1[11:0]);

assign sync_word2_match_20 =
        (tx_bpw == 2'd0) ? (sync2_shift_next_20[7:0]  == tx_sync_word2[7:0])  :
        (tx_bpw == 2'd1) ? (sync2_shift_next_20[8:0]  == tx_sync_word2[8:0])  :
        (tx_bpw == 2'd2) ? (sync2_shift_next_20[9:0]  == tx_sync_word2[9:0])  :
                           (sync2_shift_next_20[11:0] == tx_sync_word2[11:0]);

function [11:0] nrz_word_from_shift;
    input [11:0] shift_value;
    input [1:0]  bpw_value;
    begin
        case(bpw_value)
            2'd0: nrz_word_from_shift = {4'd0, shift_value[7:0]};
            2'd1: nrz_word_from_shift = {3'd0, shift_value[8:0]};
            2'd2: nrz_word_from_shift = {2'd0, shift_value[9:0]};
            2'd3: nrz_word_from_shift = shift_value[11:0];
            default: nrz_word_from_shift = 12'd0;
        endcase
    end
endfunction

always @(negedge clk_20MHz or negedge rst_n)
begin
    if(!rst_n)
    begin
        nrz_state_20            <= NRZ_SEARCH_SYNC1_20;
        sync1_shift_reg_20      <= 12'd0;
        sync2_shift_reg_20      <= 12'd0;
        payload_shift_reg_20    <= 12'd0;
        sync2_bit_counter_20    <= 4'd0;
        payload_bit_counter_20  <= 4'd0;
        payload_word_count_20   <= 11'd0;
        sync_word1_detected_20  <= 1'b0;
        sync_word2_detected_20  <= 1'b0;
        sync_locked_20          <= 1'b0;
        sync_acquired_pulse_20  <= 1'b0;
        payload_word_valid_20   <= 1'b0;
        payload_word_20         <= 12'd0;
    end
    else
    begin
        sync_acquired_pulse_20 <= 1'b0;
        payload_word_valid_20  <= 1'b0;
        if(bkp_prg_mode_on_sync_20 || !kernel_config_done_sync_20)
        begin
            nrz_state_20            <= NRZ_SEARCH_SYNC1_20;
            sync1_shift_reg_20      <= 12'd0;
            sync2_shift_reg_20      <= 12'd0;
            payload_shift_reg_20    <= 12'd0;
            sync2_bit_counter_20    <= 4'd0;
            payload_bit_counter_20  <= 4'd0;
            payload_word_count_20   <= 11'd0;
            sync_word1_detected_20  <= 1'b0;
            sync_word2_detected_20  <= 1'b0;
            sync_locked_20          <= 1'b0;
            payload_word_20         <= 12'd0;
        end
        else
        begin
            case(nrz_state_20)
                NRZ_SEARCH_SYNC1_20:
                begin
                    sync1_shift_reg_20     <= sync1_shift_next_20;
                    sync2_shift_reg_20     <= 12'd0;
                    payload_shift_reg_20   <= 12'd0;
                    sync2_bit_counter_20   <= 4'd0;
                    payload_bit_counter_20 <= 4'd0;
                    payload_word_count_20  <= 11'd0;
                    sync_word1_detected_20 <= 1'b0;
                    sync_word2_detected_20 <= 1'b0;
                    sync_locked_20         <= 1'b0;
                    if(sync_word1_match_20)
                    begin
                        sync_word1_detected_20 <= 1'b1;
                        nrz_state_20           <= NRZ_CAPTURE_SYNC2_20;
                    end
                end

                NRZ_CAPTURE_SYNC2_20:
                begin
                    sync2_shift_reg_20 <= sync2_shift_next_20;
                    if(sync2_bit_counter_20 < bpw_last_count_20)
                    begin
                        sync2_bit_counter_20 <= sync2_bit_counter_20 + 1'b1;
                    end
                    else
                    begin
                        sync2_bit_counter_20 <= 4'd0;
                        if(sync_word2_match_20)
                        begin
                            sync_word2_detected_20 <= 1'b1;
                            sync_locked_20         <= 1'b1;
                            sync_acquired_pulse_20 <= 1'b1;
                            payload_shift_reg_20   <= 12'd0;
                            payload_bit_counter_20 <= 4'd0;
                            payload_word_count_20  <= 11'd0;

                            if(payload_words_after_sync == 11'd0)
                            begin
                                sync_word1_detected_20 <= 1'b0;
                                sync_word2_detected_20 <= 1'b0;
                                sync_locked_20         <= 1'b0;
                                sync1_shift_reg_20     <= 12'd0;
                                sync2_shift_reg_20     <= 12'd0;
                                nrz_state_20           <= NRZ_SEARCH_SYNC1_20;
                            end
                            else
                            begin
                                nrz_state_20 <= NRZ_CAPTURE_PAYLOAD_20;
                            end
                        end
                        else
                        begin
                            sync_word1_detected_20 <= 1'b0;
                            sync_word2_detected_20 <= 1'b0;
                            sync_locked_20         <= 1'b0;
                            sync2_shift_reg_20     <= 12'd0;
                            sync1_shift_reg_20     <= sync2_shift_next_20;
                            nrz_state_20           <= NRZ_SEARCH_SYNC1_20;
                        end
                    end
                end

                NRZ_CAPTURE_PAYLOAD_20:
                begin
                    payload_shift_reg_20 <= payload_shift_next_20;

                    if(payload_bit_counter_20 < bpw_last_count_20)
                    begin
                        payload_bit_counter_20 <= payload_bit_counter_20 + 1'b1;
                    end
                    else
                    begin
                        payload_bit_counter_20 <= 4'd0;
                        payload_word_valid_20  <= 1'b1;
                        payload_word_20        <= nrz_word_from_shift(payload_shift_next_20, tx_bpw);
                        if(payload_word_count_20 == (payload_words_after_sync - 1'b1))
                        begin
                            payload_word_count_20  <= 11'd0;
                            sync_word1_detected_20 <= 1'b0;
                            sync_word2_detected_20 <= 1'b0;
                            sync_locked_20         <= 1'b0;
                            sync1_shift_reg_20     <= 12'd0;
                            sync2_shift_reg_20     <= 12'd0;
                            payload_shift_reg_20   <= 12'd0;
                            nrz_state_20           <= NRZ_SEARCH_SYNC1_20;
                        end
                        else
                        begin
                            payload_word_count_20 <= payload_word_count_20 + 1'b1;
                        end
                    end
                end

                default:
                begin
                    nrz_state_20 <= NRZ_SEARCH_SYNC1_20;
                end

            endcase
        end
    end
end

// =====================================================================================
// CDC: 20 MHz events/word into 64 MHz kernel clock domain
// =====================================================================================

wire sync_acquired_pulse_64;
wire payload_word_valid_64;
wire [11:0] payload_word_64;

cdc_pulse_toggle_sync_negedge_src u_sync_acquired_pulse_cdc (
    .src_clk   (clk_20MHz),
    .dst_clk   (clk),
    .rst_n     (rst_n),
    .src_pulse (sync_acquired_pulse_20),
    .dst_pulse (sync_acquired_pulse_64)
);

cdc_word12_toggle_sync_negedge_src u_payload_word_cdc (
    .src_clk   (clk_20MHz),
    .dst_clk   (clk),
    .rst_n     (rst_n),
    .src_valid (payload_word_valid_20),
    .src_word  (payload_word_20),
    .dst_valid (payload_word_valid_64),
    .dst_word  (payload_word_64)
);

// =====================================================================================
// 64 MHz FIFO writer FSM
// =====================================================================================

localparam TX_IDLE              = 4'd0;
localparam TX_WRITE_SYNC1_B1    = 4'd1;
localparam TX_WRITE_SYNC1_B2    = 4'd2;
localparam TX_WRITE_SYNC2_B1    = 4'd3;
localparam TX_WRITE_SYNC2_B2    = 4'd4;
localparam TX_WAIT_PAYLOAD_WORD = 4'd5;
localparam TX_WRITE_PAYLOAD_B1  = 4'd6;
localparam TX_WRITE_PAYLOAD_B2  = 4'd7;
localparam TX_DONE              = 4'd8;

reg [3:0]  tx_state_64;
reg [10:0] byte_counter_64;
reg [11:0] payload_word_latched_64;
reg        eth_tx_start_pulse_eth_nrz_64;

function [7:0] nrz_word_first_byte;
    input [11:0] word_value;
    input [1:0]  bpw_value;
    input        zero_endian_value;
    begin
        case(bpw_value)
            2'd0: nrz_word_first_byte = word_value[7:0];
            2'd1: nrz_word_first_byte = (!zero_endian_value) ? {7'd0, word_value[8]}    : word_value[8:1];
            2'd2: nrz_word_first_byte = (!zero_endian_value) ? {6'd0, word_value[9:8]}  : word_value[9:2];
            2'd3: nrz_word_first_byte = (!zero_endian_value) ? {4'd0, word_value[11:8]} : word_value[11:4];
            default: nrz_word_first_byte = 8'd0;
        endcase
    end
endfunction

function [7:0] nrz_word_second_byte;
    input [11:0] word_value;
    input [1:0]  bpw_value;
    input        zero_endian_value;
    begin
        case(bpw_value)
            2'd1: nrz_word_second_byte = (!zero_endian_value) ? word_value[7:0] : {word_value[0],   7'd0};
            2'd2: nrz_word_second_byte = (!zero_endian_value) ? word_value[7:0] : {word_value[1:0], 6'd0};
            2'd3: nrz_word_second_byte = (!zero_endian_value) ? word_value[7:0] : {word_value[3:0], 4'd0};
            default: nrz_word_second_byte = 8'd0;
        endcase
    end
endfunction

wire tx_word_has_second_byte;
assign tx_word_has_second_byte = (tx_bpw != 2'd0);

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        tx_state_64                    <= TX_IDLE;
        byte_counter_64                <= 11'd0;
        payload_word_latched_64        <= 12'd0;
        eth_tx_start_pulse_eth_nrz_64  <= 1'b0;
        tx_fifo_wr_en_eth_nrz          <= 1'b0;
        tx_fifo_data_in_eth_nrz        <= 8'd0;
    end
    else
    begin
        eth_tx_start_pulse_eth_nrz_64 <= 1'b0;
        tx_fifo_wr_en_eth_nrz         <= 1'b0;
        if(bkp_prg_mode_on_sync_64 || !kernel_config_done)
        begin
            tx_state_64             <= TX_IDLE;
            byte_counter_64         <= 11'd0;
            payload_word_latched_64 <= 12'd0;
            tx_fifo_data_in_eth_nrz <= 8'd0;
        end
        else
        begin
            case(tx_state_64)
                TX_IDLE:
                begin
                    byte_counter_64 <= 11'd0;
                    if(sync_acquired_pulse_64)
					begin
                        tx_state_64 <= TX_WRITE_SYNC1_B1;
					end
				end

                TX_WRITE_SYNC1_B1:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_first_byte(tx_sync_word1, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    if(tx_word_has_second_byte)
					begin
                        tx_state_64 <= TX_WRITE_SYNC1_B2;
                    end
					else
					begin
                        tx_state_64 <= TX_WRITE_SYNC2_B1;
					end
				end

                TX_WRITE_SYNC1_B2:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_second_byte(tx_sync_word1, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    tx_state_64             <= TX_WRITE_SYNC2_B1;
                end

                TX_WRITE_SYNC2_B1:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_first_byte(tx_sync_word2, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    if(tx_word_has_second_byte)
					begin
                        tx_state_64 <= TX_WRITE_SYNC2_B2;
                    end
					else if((byte_counter_64 + 1'b1) >= tx_payload_length_actual)
                    begin
						tx_state_64 <= TX_DONE;
                    end
					else
					begin
                        tx_state_64 <= TX_WAIT_PAYLOAD_WORD;
					end
				end

                TX_WRITE_SYNC2_B2:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_second_byte(tx_sync_word2, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    if((byte_counter_64 + 1'b1) >= tx_payload_length_actual)
					begin
                        tx_state_64 <= TX_DONE;
                    end
					else
					begin
                        tx_state_64 <= TX_WAIT_PAYLOAD_WORD;
					end
				end

                TX_WAIT_PAYLOAD_WORD:
                begin
                    if(payload_word_valid_64)
                    begin
                        payload_word_latched_64 <= payload_word_64;
                        tx_state_64             <= TX_WRITE_PAYLOAD_B1;
                    end
                end

                TX_WRITE_PAYLOAD_B1:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_first_byte(payload_word_latched_64, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    if(tx_word_has_second_byte)
					begin
                        tx_state_64 <= TX_WRITE_PAYLOAD_B2;
                    end
					else if((byte_counter_64 + 1'b1) >= tx_payload_length_actual)
                    begin
						tx_state_64 <= TX_DONE;
                    end
					else
					begin
                        tx_state_64 <= TX_WAIT_PAYLOAD_WORD;
					end
				end

                TX_WRITE_PAYLOAD_B2:
                begin
                    tx_fifo_wr_en_eth_nrz   <= 1'b1;
                    tx_fifo_data_in_eth_nrz <= nrz_word_second_byte(payload_word_latched_64, tx_bpw, tx_zero_endian);
                    byte_counter_64         <= byte_counter_64 + 1'b1;
                    if((byte_counter_64 + 1'b1) >= tx_payload_length_actual)
					begin
                        tx_state_64 <= TX_DONE;
                    end
					else
					begin
                        tx_state_64 <= TX_WAIT_PAYLOAD_WORD;
					end
				end

                TX_DONE:
                begin
                    eth_tx_start_pulse_eth_nrz_64 <= 1'b1;
                    byte_counter_64               <= 11'd0;
                    payload_word_latched_64       <= 12'd0;
                    tx_state_64                   <= TX_IDLE;
                end

                default:
                begin
                    tx_state_64 <= TX_IDLE;
                end

            endcase
        end
    end
end

// =====================================================================================
// CDC: ETH_NRZ start/config-done pulse from 64 MHz kernel clock to Ethernet TX clock
// =====================================================================================

cdc_pulse_toggle_sync u_eth_nrz_start_pulse_cdc (
    .src_clk    (clk),
    .dst_clk    (clk_eth),
    .rst_n      (rst_n),
    .src_pulse  (eth_tx_start_pulse_eth_nrz_64),
    .dst_pulse  (eth_tx_start_pulse_eth_nrz)
);

cdc_pulse_toggle_sync u_eth_nrz_config_done_pulse_cdc (
    .src_clk    (clk),
    .dst_clk    (clk_eth),
    .rst_n      (rst_n),
    .src_pulse  (eth_tx_start_pulse_eth_nrz_64),
    .dst_pulse  (config_done_pulse_eth_nrz)
);

endmodule

module cdc_word12_toggle_sync_negedge_src(
    input  wire        src_clk,
    input  wire        dst_clk,
    input  wire        rst_n,
    input  wire        src_valid,
    input  wire [11:0] src_word,
    output reg         dst_valid,
    output reg  [11:0] dst_word
);

reg [11:0] src_word_shadow;
reg        src_toggle;

always @(negedge src_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        src_word_shadow <= 12'd0;
        src_toggle      <= 1'b0;
    end
    else if(src_valid)
    begin
        src_word_shadow <= src_word;
        src_toggle      <= ~src_toggle;
    end
end

wire dst_toggle_sync;

cdc_bit_sync u_cdc_bit_sync (
    .dst_clk  (dst_clk),
    .rst_n    (rst_n),
    .async_in (src_toggle),
    .sync_out (dst_toggle_sync)
);

reg dst_toggle_sync_d;
wire dst_toggle_edge;

assign dst_toggle_edge = dst_toggle_sync ^ dst_toggle_sync_d;

always @(posedge dst_clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        dst_toggle_sync_d <= 1'b0;
        dst_word          <= 12'd0;
        dst_valid         <= 1'b0;
    end
    else
    begin
        dst_toggle_sync_d <= dst_toggle_sync;
        dst_valid         <= 1'b0;

        if(dst_toggle_edge)
        begin
            dst_word  <= src_word_shadow;
            dst_valid <= 1'b1;
        end
    end
end

endmodule

module cdc_pulse_toggle_sync_negedge_src(
    input  wire src_clk,
    input  wire dst_clk,
    input  wire rst_n,
    input  wire src_pulse,
    output wire dst_pulse
);

reg src_toggle;

always @(negedge src_clk or negedge rst_n)
begin
    if(!rst_n)
        src_toggle <= 1'b0;
    else if(src_pulse)
        src_toggle <= ~src_toggle;
end

wire dst_toggle_sync;

cdc_bit_sync u_cdc_bit_sync (
    .dst_clk  (dst_clk),
    .rst_n    (rst_n),
    .async_in (src_toggle),
    .sync_out (dst_toggle_sync)
);

reg dst_toggle_sync_d;

always @(posedge dst_clk or negedge rst_n)
begin
    if(!rst_n)
        dst_toggle_sync_d <= 1'b0;
    else
        dst_toggle_sync_d <= dst_toggle_sync;
end

assign dst_pulse = dst_toggle_sync ^ dst_toggle_sync_d;

endmodule