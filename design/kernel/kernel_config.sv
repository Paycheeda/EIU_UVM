module kernel_config(
		
		
		input  wire                       clk,
		input  wire 					  clk_uart,
		input  wire 				      clk_eth1,
		input  wire 				      clk_eth2,
		input  wire 				      clk_eth3,
		input  wire 				      clk_eth4,
		input  wire                       rst_n,

		// =========================================================
		// Backplane configuration interface
		// =========================================================
		input  wire                       bkp_config_wr_pulse,
		input  wire [3:0]   			  bkp_card_id,
		input  wire [3:0]   			  fpga_card_id,
		input  wire                       bkp_data_dir,
		input  wire [5:0]                 bkp_address,
		input  wire  [11:0]            	  bkp_data,

		// =========================================================
		// Global configuration done pulse
		// =========================================================
		output reg 						  config_done_uart,
		output reg 						  config_done_eth1,
		output reg 						  config_done_eth2,
		output reg 						  config_done_eth3,
		output reg 						  config_done_eth4,
		output reg 						  config_done_pulse,
		// =========================================================
		// UART1 configuration outputs
		// =========================================================
		output wire [31:0]                baudrate_uart1,
		output wire                       parity_en_uart1,
		output wire                       parity_odd_even_uart1,
		output wire                       data_width_uart1,

		// =========================================================
		// UART2 configuration outputs
		// =========================================================
		output wire [31:0]                baudrate_uart2,
		output wire                       parity_en_uart2,
		output wire                       parity_odd_even_uart2,
		output wire                       data_width_uart2,

		// =========================================================
		// UART3 configuration outputs
		// =========================================================
		output wire [31:0]                baudrate_uart3,
		output wire                       parity_en_uart3,
		output wire                       parity_odd_even_uart3,
		output wire                       data_width_uart3,

		// =========================================================
		// ETH1 configuration outputs
		// =========================================================
		output wire [47:0]                dest_mac_eth1,
		output wire [47:0]                source_mac_eth1,
		output wire [31:0]                source_ip_eth1,
		output wire [31:0]                dest_ip_eth1,
		output wire [15:0]                source_port_eth1,
		output wire [15:0]                dest_port_eth1,
		output wire [10:0]                tx_payload_length_eth1,

		// =========================================================
		// ETH2 configuration outputs
		// =========================================================
		output wire [47:0]                dest_mac_eth2,
		output wire [47:0]                source_mac_eth2,
		output wire [31:0]                source_ip_eth2,
		output wire [31:0]                dest_ip_eth2,
		output wire [15:0]                source_port_eth2,
		output wire [15:0]                dest_port_eth2,
		output wire [10:0]                tx_payload_length_eth2,

		// =========================================================
		// ETH3 configuration outputs
		// =========================================================
		output wire [47:0]                dest_mac_eth3,
		output wire [47:0]                source_mac_eth3,
		output wire [31:0]                source_ip_eth3,
		output wire [31:0]                dest_ip_eth3,
		output wire [15:0]                source_port_eth3,
		output wire [15:0]                dest_port_eth3,
		output wire [10:0]                tx_payload_length_eth3,

		// =========================================================
		// ETH4 configuration outputs
		// =========================================================
		output wire [47:0]                dest_mac_eth4,
		output wire [47:0]                source_mac_eth4,
		output wire [31:0]                source_ip_eth4,
		output wire [31:0]                dest_ip_eth4,
		output wire [15:0]                source_port_eth4,
		output wire [15:0]                dest_port_eth4,
		output wire [10:0]                tx_payload_length_eth4,

		// =========================================================
		// ETH_NRZ configuration outputs
		// =========================================================
		output wire [47:0]                dest_mac_eth_nrz,
		output wire [47:0]                source_mac_eth_nrz,
		output wire [31:0]                source_ip_eth_nrz,
		output wire [31:0]                dest_ip_eth_nrz,
		output wire [15:0]                source_port_eth_nrz,
		output wire [15:0]                dest_port_eth_nrz,
		output wire [10:0]                tx_payload_length_eth_nrz,
		output reg						  tx_zero_endian_eth_nrz,
		output reg  [1:0]                 tx_bpw_eth_nrz,
		output reg  [11:0]                tx_sync_word1_eth_nrz,
		output reg  [11:0]                tx_sync_word2_eth_nrz
	);

reg       	config_read_done;
reg [1:0] 	state;
localparam 	IDLE = 2'd0;
localparam 	CONFIG_READ_STATE = 2'd1;
localparam 	CONFIG_DONE_STATE = 2'd2;

reg [2:0] addr_count [0:40];

reg [31:0] baudrate_uart        [0:2];
reg        parity_en_uart       [0:2];
reg        parity_odd_even_uart [0:2];
reg        data_width_uart      [0:2];

reg [47:0] dest_mac_eth         [0:4];
reg [47:0] source_mac_eth       [0:4];
reg [31:0] source_ip_eth        [0:4];
reg [31:0] dest_ip_eth          [0:4];
reg [15:0] source_port_eth      [0:4];
reg [15:0] dest_port_eth        [0:4];
reg [10:0] tx_payload_length_eth[0:4];

reg        config_done_latched;

wire [1:0] uart_index;
wire [2:0] eth_index;
wire [2:0] eth_field;

assign uart_index = bkp_address[1:0];
assign eth_index  = (bkp_address - 6'd3) / 7;
assign eth_field  = (bkp_address - 6'd3) % 7;

wire cfg_wr_hit;

assign cfg_wr_hit = bkp_config_wr_pulse && 
					(bkp_card_id == fpga_card_id) 
					&& bkp_data_dir && 
					(bkp_address <= 6'd40);

assign baudrate_uart1        = baudrate_uart[0];
assign baudrate_uart2        = baudrate_uart[1];
assign baudrate_uart3        = baudrate_uart[2];

assign parity_en_uart1       = parity_en_uart[0];
assign parity_en_uart2       = parity_en_uart[1];
assign parity_en_uart3       = parity_en_uart[2];

assign parity_odd_even_uart1 = parity_odd_even_uart[0];
assign parity_odd_even_uart2 = parity_odd_even_uart[1];
assign parity_odd_even_uart3 = parity_odd_even_uart[2];

assign data_width_uart1      = data_width_uart[0];
assign data_width_uart2      = data_width_uart[1];
assign data_width_uart3      = data_width_uart[2];

assign dest_mac_eth1         = dest_mac_eth[0];
assign dest_mac_eth2         = dest_mac_eth[1];
assign dest_mac_eth3         = dest_mac_eth[2];
assign dest_mac_eth4         = dest_mac_eth[3];
assign dest_mac_eth_nrz      = dest_mac_eth[4];

assign source_mac_eth1       = source_mac_eth[0];
assign source_mac_eth2       = source_mac_eth[1];
assign source_mac_eth3       = source_mac_eth[2];
assign source_mac_eth4       = source_mac_eth[3];
assign source_mac_eth_nrz    = source_mac_eth[4];

assign source_ip_eth1        = source_ip_eth[0];
assign source_ip_eth2        = source_ip_eth[1];
assign source_ip_eth3        = source_ip_eth[2];
assign source_ip_eth4        = source_ip_eth[3];
assign source_ip_eth_nrz     = source_ip_eth[4];

assign dest_ip_eth1          = dest_ip_eth[0];
assign dest_ip_eth2          = dest_ip_eth[1];
assign dest_ip_eth3          = dest_ip_eth[2];
assign dest_ip_eth4          = dest_ip_eth[3];
assign dest_ip_eth_nrz       = dest_ip_eth[4];

assign source_port_eth1      = source_port_eth[0];
assign source_port_eth2      = source_port_eth[1];
assign source_port_eth3      = source_port_eth[2];
assign source_port_eth4      = source_port_eth[3];
assign source_port_eth_nrz   = source_port_eth[4];

assign dest_port_eth1        = dest_port_eth[0];
assign dest_port_eth2        = dest_port_eth[1];
assign dest_port_eth3        = dest_port_eth[2];
assign dest_port_eth4        = dest_port_eth[3];
assign dest_port_eth_nrz     = dest_port_eth[4];

assign tx_payload_length_eth1    = tx_payload_length_eth[0];
assign tx_payload_length_eth2    = tx_payload_length_eth[1];
assign tx_payload_length_eth3    = tx_payload_length_eth[2];
assign tx_payload_length_eth4    = tx_payload_length_eth[3];
assign tx_payload_length_eth_nrz = tx_payload_length_eth[4];

reg all_config_received;
integer a;

always @(*)
begin
    all_config_received = 1'b1;

    for (a = 0; a < 41; a = a + 1)
    begin
        if (addr_count[a] < required_writes(a[5:0]))
            all_config_received = 1'b0;
    end
end

integer i;

always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        state                 <= IDLE;
        config_done_pulse     <= 1'b0;
        config_done_latched   <= 1'b0;
        config_read_done      <= 1'b0;
        tx_zero_endian_eth_nrz <= 1'b0;
		tx_bpw_eth_nrz			 <= 2'd0;
		tx_sync_word1_eth_nrz	 <= 12'd0;
		tx_sync_word2_eth_nrz	 <= 12'd0;
        for (i = 0; i < 41; i = i + 1)
        begin
            addr_count[i] <= 3'd0;
        end
        for (i = 0; i < 3; i = i + 1)
        begin
            baudrate_uart[i]        <= 32'd0;
            parity_en_uart[i]       <= 1'b0;
            parity_odd_even_uart[i] <= 1'b0;
            data_width_uart[i]      <= 1'b0;
        end
        for (i = 0; i < 5; i = i + 1)
        begin
            dest_mac_eth[i]          <= 48'd0;
            source_mac_eth[i]        <= 48'd0;
            source_ip_eth[i]         <= 32'd0;
            dest_ip_eth[i]           <= 32'd0;
            source_port_eth[i]       <= 16'd0;
            dest_port_eth[i]         <= 16'd0;
            tx_payload_length_eth[i] <= 11'd0;
        end
    end
    else
    begin
        config_done_pulse <= 1'b0;
        case (state)
            IDLE:
            begin
                config_read_done <= 1'b0;
                if (!config_done_latched && all_config_received)
                begin
                    state <= CONFIG_DONE_STATE;
                end
                else if (cfg_wr_hit && !config_done_latched)
                begin
                    state <= CONFIG_READ_STATE;
                end
                else
                begin
                    state <= IDLE;
                end
            end
            
			CONFIG_READ_STATE:
            begin
                if (!config_read_done)
                begin
                    config_read_done <= 1'b1;
                    if (addr_count[bkp_address] < required_writes(bkp_address))
                    begin
                        addr_count[bkp_address] <= addr_count[bkp_address] + 1'b1;
                        if (bkp_address <= 6'd2)
                        begin
                            baudrate_uart[uart_index]        <= {baudrate_uart[uart_index][23:0], bkp_data[7:0]};
                            parity_en_uart[uart_index]       <= bkp_data[8];
                            parity_odd_even_uart[uart_index] <= bkp_data[9];
                            data_width_uart[uart_index]      <= bkp_data[10];
                        end
                        else if(bkp_address <= 6'd37)
                        begin
                            case (eth_field)

                                3'd0:
                                begin
                                    dest_mac_eth[eth_index] <= {dest_mac_eth[eth_index][35:0], bkp_data[11:0]};
                                end

                                3'd1:
                                begin
                                    source_mac_eth[eth_index] <= {source_mac_eth[eth_index][35:0], bkp_data[11:0]};
                                end

                                3'd2:
                                begin
                                    source_ip_eth[eth_index] <= {source_ip_eth[eth_index][23:0], bkp_data[7:0]};
                                end

                                3'd3:
                                begin
                                    dest_ip_eth[eth_index] <= {dest_ip_eth[eth_index][23:0], bkp_data[7:0]};
                                end

                                3'd4:
                                begin
                                    source_port_eth[eth_index] <= {source_port_eth[eth_index][7:0], bkp_data[7:0]};
                                end

                                3'd5:
                                begin
                                    dest_port_eth[eth_index] <= {dest_port_eth[eth_index][7:0], bkp_data[7:0]};
                                end

                                3'd6:
                                begin
                                    tx_payload_length_eth[eth_index] <= bkp_data[10:0];

                                    if (eth_index == 3'd4)
                                    begin
                                        tx_zero_endian_eth_nrz <= bkp_data[11];
                                    end
                                end

                                default:
                                begin
                                    // no operation
                                end

                            endcase
                        end
						else
						begin
							case(bkp_address)
								6'd38:
								begin
									tx_bpw_eth_nrz <= bkp_data[1:0];
								end
								
								6'd39:
								begin
									tx_sync_word1_eth_nrz <= bkp_data[11:0];
								end
								
								6'd40:
								begin
									tx_sync_word2_eth_nrz <= bkp_data[11:0];
								end
								
								default:
								begin
									// do nothing
								end
								
							endcase
						end
                    end
                end
                if (cfg_wr_hit)
                begin
                    state <= CONFIG_READ_STATE;
                end
                else
                begin
                    config_read_done <= 1'b0;
                    state <= IDLE;
                end
            end
            
			CONFIG_DONE_STATE:
            begin
                config_done_pulse   <= 1'b1;
                config_done_latched <= 1'b1;
                state               <= IDLE;
            end
            
			default:
            begin
                state            <= IDLE;
                config_read_done <= 1'b0;
            end
        endcase
    end
end



// ============================================================
// config_done_pulse CDC
// Source domain : clk       = 64 MHz kernel clock
// UART domain   : uart_clk  = 44.2368 MHz
// ETH domain    : eth_clk   = 125 MHz
// ============================================================

reg config_done_toggle_kernel;

(* ASYNC_REG = "TRUE" *) reg [2:0] config_done_uart_sync;
(* ASYNC_REG = "TRUE" *) reg [2:0] config_done_eth1_sync;
(* ASYNC_REG = "TRUE" *) reg [2:0] config_done_eth2_sync;
(* ASYNC_REG = "TRUE" *) reg [2:0] config_done_eth3_sync;
(* ASYNC_REG = "TRUE" *) reg [2:0] config_done_eth4_sync;

// ============================================================
// Kernel clock domain: convert config_done_pulse into toggle
// ============================================================
always @(posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_toggle_kernel <= 1'b0;
    end
    else
    begin
        if (config_done_pulse)
        begin
            config_done_toggle_kernel <= ~config_done_toggle_kernel;
        end
    end
end

// ============================================================
// UART clock domain: synchronize toggle and generate pulse
// ============================================================
always @(posedge clk_uart or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_uart_sync <= 3'b000;
        config_done_uart      <= 1'b0;
    end
    else
    begin
        config_done_uart_sync <= {config_done_uart_sync[1:0], config_done_toggle_kernel};
        config_done_uart      <= config_done_uart_sync[2] ^ config_done_uart_sync[1];
    end
end

// ============================================================
// ETH clock domain: synchronize toggle and generate pulse
// ============================================================
always @(posedge clk_eth1 or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_eth1_sync <= 3'b000;
        config_done_eth1      <= 1'b0;
    end
    else
    begin
        config_done_eth1_sync <= {config_done_eth1_sync[1:0], config_done_toggle_kernel};
        config_done_eth1      <= config_done_eth1_sync[2] ^ config_done_eth1_sync[1];
    end
end

always @(posedge clk_eth2 or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_eth2_sync <= 3'b000;
        config_done_eth2      <= 1'b0;
    end
    else
    begin
        config_done_eth2_sync <= {config_done_eth2_sync[1:0], config_done_toggle_kernel};
        config_done_eth2      <= config_done_eth2_sync[2] ^ config_done_eth2_sync[1];
    end
end

always @(posedge clk_eth3 or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_eth3_sync <= 3'b000;
        config_done_eth3      <= 1'b0;
    end
    else
    begin
        config_done_eth3_sync <= {config_done_eth3_sync[1:0], config_done_toggle_kernel};
        config_done_eth3      <= config_done_eth3_sync[2] ^ config_done_eth3_sync[1];
    end
end

always @(posedge clk_eth4 or negedge rst_n)
begin
    if (!rst_n)
    begin
        config_done_eth4_sync <= 3'b000;
        config_done_eth4      <= 1'b0;
    end
    else
    begin
        config_done_eth4_sync <= {config_done_eth4_sync[1:0], config_done_toggle_kernel};
        config_done_eth4      <= config_done_eth4_sync[2] ^ config_done_eth4_sync[1];
    end
end



function [2:0] required_writes;
    input [5:0] addr;
    reg [2:0] eth_field;
    begin
        if (addr <= 6'd2)
        begin
            // UART1, UART2, UART3 baudrate needs 4 writes
            required_writes = 3'd4;
        end
        else if (addr <= 6'd37)
        begin
            eth_field = (addr - 6'd3) % 7;

            case (eth_field)
                3'd0: required_writes = 3'd4; // dest MAC
                3'd1: required_writes = 3'd4; // source MAC
                3'd2: required_writes = 3'd4; // source IP
                3'd3: required_writes = 3'd4; // dest IP
                3'd4: required_writes = 3'd2; // source port
                3'd5: required_writes = 3'd2; // dest port
                3'd6: required_writes = 3'd1; // payload length
                default: required_writes = 3'd0;
            endcase
        end
		else if (addr <= 6'd40)
        begin
            required_writes = 3'd1; // tx_bpw, sync_word1, sync_word2
        end
        else
        begin
            required_writes = 3'd0;
        end
    end
endfunction

endmodule