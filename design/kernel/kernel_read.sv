module kernel_read(
            
        input  wire                       clk,
        input  wire                       clk_uart,
        input  wire                       rst_n,
        input wire                        rx_clk_eth1,
        input wire                        rx_clk_eth2,
        input wire                        rx_clk_eth3,
        input wire                        rx_clk_eth4,

        input  wire [3:0]                 bkp_card_id,
        input  wire [3:0]                 fpga_card_id,
        input  wire                       bkp_data_dir,
        input  wire [5:0]                 bkp_address,
        inout [11:0]                      bkp_data,
        input  wire                       word_start_strobe_pulse,
        
        input [8:0]                       rx_fifo_data_out_uart1,
        input [8:0]                       rx_fifo_data_out_uart2,
        input [8:0]                       rx_fifo_data_out_uart3,
        input [7:0]                       rx_fifo_data_out_eth1,
        input [7:0]                       rx_fifo_data_out_eth2,
        input [7:0]                       rx_fifo_data_out_eth3,
        input [7:0]                       rx_fifo_data_out_eth4,
        
        input [10:0]                      rx_valid_byte_count_uart1,
        input [10:0]                      rx_valid_byte_count_uart2,
        input [10:0]                      rx_valid_byte_count_uart3,
        input [10:0]                      rx_eth_valid_bytes_eth1,
        input [10:0]                      rx_eth_valid_bytes_eth2,
        input [10:0]                      rx_eth_valid_bytes_eth3,
        input [10:0]                      rx_eth_valid_bytes_eth4,
        
        input [10:0]                      rx_corrupt_byte_count_uart1,
        input [10:0]                      rx_corrupt_byte_count_uart2,
        input [10:0]                      rx_corrupt_byte_count_uart3,
        input [10:0]                      rx_eth_corrupt_frame_count_eth1,
        input [10:0]                      rx_eth_corrupt_frame_count_eth2,
        input [10:0]                      rx_eth_corrupt_frame_count_eth3,
        input [10:0]                      rx_eth_corrupt_frame_count_eth4,
        
        input                             tx_fifo_full_uart1,
        input                             tx_fifo_full_uart2,
        input                             tx_fifo_full_uart3,
        input                             tx_fifo_full_eth1,
        input                             tx_fifo_full_eth2,
        input                             tx_fifo_full_eth3,
        input                             tx_fifo_full_eth4,
        input                             tx_fifo_full_eth_nrz,
        
        input                             rx_fifo_full_uart1,
        input                             rx_fifo_full_uart2,
        input                             rx_fifo_full_uart3,
        input                             rx_fifo_full_eth1,
        input                             rx_fifo_full_eth2,
        input                             rx_fifo_full_eth3,
        input                             rx_fifo_full_eth4,
        
        input                             tx_fifo_empty_uart1,
        input                             tx_fifo_empty_uart2,
        input                             tx_fifo_empty_uart3,
        input                             tx_fifo_empty_eth1,
        input                             tx_fifo_empty_eth2,
        input                             tx_fifo_empty_eth3,
        input                             tx_fifo_empty_eth4,
        input                             tx_fifo_empty_eth_nrz,
        
        input                             rx_fifo_empty_uart1,
        input                             rx_fifo_empty_uart2,
        input                             rx_fifo_empty_uart3,
        input                             rx_fifo_empty_eth1,
        input                             rx_fifo_empty_eth2,
        input                             rx_fifo_empty_eth3,
        input                             rx_fifo_empty_eth4,
        
    
        output reg                        rx_fifo_rd_en_uart1,
        output reg                        rx_fifo_rd_en_uart2,
        output reg                        rx_fifo_rd_en_uart3,
        output reg                        rx_fifo_rd_en_eth1,
        output reg                        rx_fifo_rd_en_eth2,
        output reg                        rx_fifo_rd_en_eth3,
        output reg                        rx_fifo_rd_en_eth4,
        
        input                             tx_data_sent_uart1,
        input                             tx_data_sent_uart2,
        input                             tx_data_sent_uart3,
        input                             tx_data_sent_eth1,
        input                             tx_data_sent_eth2,
        input                             tx_data_sent_eth3,
        input                             tx_data_sent_eth4,
        input                             tx_data_sent_eth_nrz
        
);


wire [10:0] rx_valid_byte_count_uart1_kernel;
wire [10:0] rx_valid_byte_count_uart2_kernel;
wire [10:0] rx_valid_byte_count_uart3_kernel;
wire [10:0] rx_eth_valid_bytes_eth1_kernel;
wire [10:0] rx_eth_valid_bytes_eth2_kernel;
wire [10:0] rx_eth_valid_bytes_eth3_kernel;
wire [10:0] rx_eth_valid_bytes_eth4_kernel;
wire [10:0] rx_corrupt_byte_count_uart1_kernel;
wire [10:0] rx_corrupt_byte_count_uart2_kernel;
wire [10:0] rx_corrupt_byte_count_uart3_kernel;
wire [10:0] rx_eth_corrupt_frame_count_eth1_kernel;
wire [10:0] rx_eth_corrupt_frame_count_eth2_kernel;
wire [10:0] rx_eth_corrupt_frame_count_eth3_kernel;
wire [10:0] rx_eth_corrupt_frame_count_eth4_kernel;
wire tx_fifo_empty_uart1_kernel;
wire tx_fifo_empty_uart2_kernel;
wire tx_fifo_empty_uart3_kernel;
wire tx_fifo_empty_eth1_kernel;
wire tx_fifo_empty_eth2_kernel;
wire tx_fifo_empty_eth3_kernel;
wire tx_fifo_empty_eth4_kernel;
wire tx_fifo_empty_eth_nrz_kernel;
wire rx_fifo_full_uart1_kernel;
wire rx_fifo_full_uart2_kernel;
wire rx_fifo_full_uart3_kernel;
wire rx_fifo_full_eth1_kernel;
wire rx_fifo_full_eth2_kernel;
wire rx_fifo_full_eth3_kernel;
wire rx_fifo_full_eth4_kernel;
wire tx_data_sent_eth1_kernel;
wire tx_data_sent_eth2_kernel;
wire tx_data_sent_eth3_kernel;
wire tx_data_sent_eth4_kernel;
wire tx_data_sent_eth_nrz_kernel;

reg [10:0] count_uart1;
reg [10:0] count_uart2;
reg [10:0] count_uart3;
reg [10:0] count_eth1;
reg [10:0] count_eth2;
reg [10:0] count_eth3;
reg [10:0] count_eth4;

reg [11:0] bkp_data_reg;

reg bkp_data_drive;

assign bkp_data = bkp_data_drive ? bkp_data_reg : 12'bz;

wire en_detect;
assign en_detect = (!bkp_data_dir) && (bkp_card_id == fpga_card_id) && (bkp_address >= 6'd0 && bkp_address <= 6'd24);


reg [5:0] captured_address;
reg [1:0] state;

localparam IDLE = 2'd0;
localparam DATA_CAPTURE_STATE = 2'd1;
localparam FIFO_WAIT_STATE = 2'd2;
localparam DATA_SENT_STATE = 2'd3;

always @ (posedge clk or negedge rst_n)
begin
    if (!rst_n)
    begin
        bkp_data_drive <= 1'b0;
    end
    else if (bkp_data_dir || (bkp_card_id != fpga_card_id))
    begin
        bkp_data_drive <= 1'b0;
    end
    else if (en_detect && word_start_strobe_pulse)
    begin
        bkp_data_drive <= 1'b1;
    end
end

always @ (posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        rx_fifo_rd_en_uart1 <= 0;
        rx_fifo_rd_en_uart2 <= 0;
        rx_fifo_rd_en_uart3 <= 0;
        rx_fifo_rd_en_eth1 <= 0;
        rx_fifo_rd_en_eth2 <= 0;
        rx_fifo_rd_en_eth3 <= 0;
        rx_fifo_rd_en_eth4 <= 0;
        captured_address <= 0;
        bkp_data_reg <= 0;
        count_uart1 <= 0;
        count_uart2 <= 0;
        count_uart3 <= 0;
        count_eth1 <= 0;
        count_eth2 <= 0;
        count_eth3 <= 0;
        count_eth4 <= 0;
        state <= IDLE;
    end
    else
    begin
        case(state)
            IDLE:
            begin
                if(en_detect)
                begin
                    if(word_start_strobe_pulse)
                    begin
                        captured_address <= bkp_address;
                        case(bkp_address)
                            6'd0:
                            begin
                                if (!rx_fifo_empty_uart1)
                                begin
                                    rx_fifo_rd_en_uart1 <= 1'b1;
                                    count_uart1 <= count_uart1 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd3:
                            begin
                                if (!rx_fifo_empty_uart2)
                                begin
                                    rx_fifo_rd_en_uart2 <= 1'b1;
                                    count_uart2 <= count_uart2 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd6:
                            begin
                                if (!rx_fifo_empty_uart3)
                                begin
                                    rx_fifo_rd_en_uart3 <= 1'b1;
                                    count_uart3 <= count_uart3 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd9:
                            begin
                                if (!rx_fifo_empty_eth1)
                                begin
                                    rx_fifo_rd_en_eth1 <= 1'b1;
                                    count_eth1 <= count_eth1 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd12:
                            begin
                                if (!rx_fifo_empty_eth2)
                                begin
                                    rx_fifo_rd_en_eth2 <= 1'b1;
                                    count_eth2 <= count_eth2 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd15:
                            begin
                                if (!rx_fifo_empty_eth3)
                                begin
                                    rx_fifo_rd_en_eth3 <= 1'b1;
                                    count_eth3 <= count_eth3 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            6'd18:
                            begin
                                if (!rx_fifo_empty_eth4)
                                begin
                                    rx_fifo_rd_en_eth4 <= 1'b1;
                                    count_eth4 <= count_eth4 + 1;
                                    state <= FIFO_WAIT_STATE;
                                end
                                else
                                begin
                                    bkp_data_reg <= 12'd0;
                                    state <= DATA_SENT_STATE;
                                end
                            end
                            
                            default:
                            begin
                                rx_fifo_rd_en_uart1 <= 0;
                                rx_fifo_rd_en_uart2 <= 0;
                                rx_fifo_rd_en_uart3 <= 0;
                                rx_fifo_rd_en_eth1 <= 0;
                                rx_fifo_rd_en_eth2 <= 0;
                                rx_fifo_rd_en_eth3 <= 0;
                                rx_fifo_rd_en_eth4 <= 0;
                                state <= DATA_CAPTURE_STATE;
                            end
                        endcase
                    end
                    else
                    begin
                        state <= IDLE;
                    end
                end
                else
                begin
                    state <= IDLE;
                end
            end
            
            FIFO_WAIT_STATE:
            begin
                rx_fifo_rd_en_uart1 <= 0;
                rx_fifo_rd_en_uart2 <= 0;
                rx_fifo_rd_en_uart3 <= 0;
                rx_fifo_rd_en_eth1 <= 0;
                rx_fifo_rd_en_eth2 <= 0;
                rx_fifo_rd_en_eth3 <= 0;
                rx_fifo_rd_en_eth4 <= 0;
                state <= DATA_CAPTURE_STATE;
            end
            
            DATA_CAPTURE_STATE:
            begin
                state <= DATA_SENT_STATE;
                case(captured_address)
                    6'd0:
                    begin
                        bkp_data_reg[8:0] <= rx_fifo_data_out_uart1;
                        bkp_data_reg[11:9] <= 3'd0;
                    end
                    
                    6'd1:
                    begin
                        bkp_data_reg[10:0] <= rx_valid_byte_count_uart1_kernel - count_uart1 ;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd2:
                    begin
                        bkp_data_reg[10:0] <= rx_corrupt_byte_count_uart1_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd3:
                    begin
                        bkp_data_reg[8:0] <= rx_fifo_data_out_uart2;
                        bkp_data_reg[11:9] <= 3'd0;
                    end
                    
                    6'd4:
                    begin
                        bkp_data_reg[10:0] <= rx_valid_byte_count_uart2_kernel - count_uart2;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd5:
                    begin
                        bkp_data_reg[10:0] <= rx_corrupt_byte_count_uart2_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd6:
                    begin
                        bkp_data_reg[8:0] <= rx_fifo_data_out_uart3;
                        bkp_data_reg[11:9] <= 3'd0;
                    end
                    
                    6'd7:
                    begin
                        bkp_data_reg[10:0] <= rx_valid_byte_count_uart3_kernel - count_uart3;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd8:
                    begin
                        bkp_data_reg[10:0] <= rx_corrupt_byte_count_uart3_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd9:
                    begin
                        bkp_data_reg[7:0] <= rx_fifo_data_out_eth1;
                        bkp_data_reg[11:8] <= 4'd0;
                    end
                    
                    6'd10:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_valid_bytes_eth1_kernel - count_eth1;
                        if(rx_eth_valid_bytes_eth1_kernel - count_eth1 == 0)
                        begin
                            count_eth1 <= 0;
                        end
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd11:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_corrupt_frame_count_eth1_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd12:
                    begin
                        bkp_data_reg[7:0] <= rx_fifo_data_out_eth2;
                        bkp_data_reg[11:8] <= 4'd0;
                    end
                    
                    6'd13:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_valid_bytes_eth2_kernel - count_eth2;
                        if(rx_eth_valid_bytes_eth2_kernel - count_eth2 == 0)
                        begin
                            count_eth2 <= 0;
                        end
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd14:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_corrupt_frame_count_eth2_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd15:
                    begin
                        bkp_data_reg[7:0] <= rx_fifo_data_out_eth3;
                        bkp_data_reg[11:8] <= 4'd0;
                    end
                    
                    6'd16:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_valid_bytes_eth3_kernel - count_eth3;
                        if(rx_eth_valid_bytes_eth3_kernel - count_eth3 == 0)
                        begin
                            count_eth3 <= 0;
                        end
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd17:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_corrupt_frame_count_eth3_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd18:
                    begin
                        bkp_data_reg[7:0] <= rx_fifo_data_out_eth4;
                        bkp_data_reg[11:8] <= 4'd0;
                    end
                    
                    6'd19:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_valid_bytes_eth4_kernel - count_eth4;
                        if(rx_eth_valid_bytes_eth4_kernel - count_eth4 == 0)
                        begin
                            count_eth4 <= 0;
                        end
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd20:
                    begin
                        bkp_data_reg[10:0] <= rx_eth_corrupt_frame_count_eth4_kernel;
                        bkp_data_reg[11] <= 1'b0;
                    end
                    
                    6'd21:
                    begin
                        bkp_data_reg[0] <= tx_fifo_full_uart1;
                        bkp_data_reg[1] <= tx_fifo_empty_uart1_kernel;
                        bkp_data_reg[2] <= tx_fifo_full_uart2;
                        bkp_data_reg[3] <= tx_fifo_empty_uart2_kernel;
                        bkp_data_reg[4] <= tx_fifo_full_uart3;
                        bkp_data_reg[5] <= tx_fifo_empty_uart3_kernel;
                        bkp_data_reg[6] <= tx_fifo_full_eth1;
                        bkp_data_reg[7] <= tx_fifo_empty_eth1_kernel;
                        bkp_data_reg[8] <= tx_fifo_full_eth2;
                        bkp_data_reg[9] <= tx_fifo_empty_eth2_kernel;
                        bkp_data_reg[10] <= tx_fifo_full_eth3;
                        bkp_data_reg[11] <= tx_fifo_empty_eth3_kernel;
                    end
                    
                    6'd22:
                    begin
                        bkp_data_reg[0] <= tx_fifo_full_eth4;
                        bkp_data_reg[1] <= tx_fifo_empty_eth4_kernel;
                        bkp_data_reg[2] <= rx_fifo_full_uart1_kernel;
                        bkp_data_reg[3] <= rx_fifo_empty_uart1;
                        bkp_data_reg[4] <= rx_fifo_full_uart2_kernel;
                        bkp_data_reg[5] <= rx_fifo_empty_uart2;
                        bkp_data_reg[6] <= rx_fifo_full_uart3_kernel;
                        bkp_data_reg[7] <= rx_fifo_empty_uart3;
                        bkp_data_reg[8] <= rx_fifo_full_eth1_kernel;
                        bkp_data_reg[9] <= rx_fifo_empty_eth1;
                        bkp_data_reg[10] <= rx_fifo_full_eth2_kernel;
                        bkp_data_reg[11] <= rx_fifo_empty_eth2;
                    end
                    
                    6'd23:
                    begin
                        bkp_data_reg[0] <= rx_fifo_full_eth3_kernel;
                        bkp_data_reg[1] <= rx_fifo_empty_eth3;
                        bkp_data_reg[2] <= rx_fifo_full_eth4_kernel;
                        bkp_data_reg[3] <= rx_fifo_empty_eth4;
                        bkp_data_reg[4] <= tx_fifo_full_eth_nrz;
                        bkp_data_reg[5] <= tx_fifo_empty_eth_nrz_kernel;
                        bkp_data_reg[6] <= tx_data_sent_uart1;
                        bkp_data_reg[7] <= tx_data_sent_uart2;
                        bkp_data_reg[8] <= tx_data_sent_uart3;
                        bkp_data_reg[9] <= tx_data_sent_eth1_kernel;
                        bkp_data_reg[10] <= tx_data_sent_eth2_kernel;
                        bkp_data_reg[11] <= tx_data_sent_eth3_kernel;
                    end
                    
                    6'd24:
                    begin
                        bkp_data_reg[0] <= tx_data_sent_eth4_kernel;
                        bkp_data_reg[1] <= tx_data_sent_eth_nrz_kernel;
                        bkp_data_reg[11:2] <= 10'd0;
                    end
                    
                    default:
                    begin
                        // do nothing
                    end
                    
                endcase
            end
            
            DATA_SENT_STATE:
            begin
                if(word_start_strobe_pulse)
                begin
                    state <= DATA_SENT_STATE;
                end
                else
                begin
                    state <= IDLE;
                end
            end
            
            default:
            begin
                rx_fifo_rd_en_uart1 <= 0;
                rx_fifo_rd_en_uart2 <= 0;
                rx_fifo_rd_en_uart3 <= 0;
                rx_fifo_rd_en_eth1 <= 0;
                rx_fifo_rd_en_eth2 <= 0;
                rx_fifo_rd_en_eth3 <= 0;
                rx_fifo_rd_en_eth4 <= 0;
                state <= IDLE;
            end
            
        endcase
    end
end


cdc_count_11bit_toggle cdc_rx_valid_byte_count_uart1_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_valid_byte_count_uart1),

    .dst_count  (rx_valid_byte_count_uart1_kernel)
);



cdc_count_11bit_toggle cdc_rx_valid_byte_count_uart2_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_valid_byte_count_uart2),

    .dst_count  (rx_valid_byte_count_uart2_kernel)
);



cdc_count_11bit_toggle cdc_rx_valid_byte_count_uart3_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_valid_byte_count_uart3),

    .dst_count  (rx_valid_byte_count_uart3_kernel)
);




cdc_count_11bit_toggle cdc_rx_eth_valid_bytes_eth1_inst
(
    .src_clk    (rx_clk_eth1),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_valid_bytes_eth1),

    .dst_count  (rx_eth_valid_bytes_eth1_kernel)
);



cdc_count_11bit_toggle cdc_rx_eth_valid_bytes_eth2_inst
(
    .src_clk    (rx_clk_eth2),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_valid_bytes_eth2),

    .dst_count  (rx_eth_valid_bytes_eth2_kernel)
);



cdc_count_11bit_toggle cdc_rx_eth_valid_bytes_eth3_inst
(
    .src_clk    (rx_clk_eth3),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_valid_bytes_eth3),

    .dst_count  (rx_eth_valid_bytes_eth3_kernel)
);


cdc_count_11bit_toggle cdc_rx_eth_valid_bytes_eth4_inst
(
    .src_clk    (rx_clk_eth4),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_valid_bytes_eth4),

    .dst_count  (rx_eth_valid_bytes_eth4_kernel)
);


cdc_count_11bit_toggle cdc_rx_corrupt_byte_count_uart1_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_corrupt_byte_count_uart1),

    .dst_count  (rx_corrupt_byte_count_uart1_kernel)
);


cdc_count_11bit_toggle cdc_rx_corrupt_byte_count_uart2_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_corrupt_byte_count_uart2),

    .dst_count  (rx_corrupt_byte_count_uart2_kernel)
);


cdc_count_11bit_toggle cdc_rx_corrupt_byte_count_uart3_inst
(
    .src_clk    (clk_uart),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_corrupt_byte_count_uart3),

    .dst_count  (rx_corrupt_byte_count_uart3_kernel)
);



cdc_count_11bit_toggle cdc_rx_eth_corrupt_frame_count_eth1_inst
(
    .src_clk    (rx_clk_eth1),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_corrupt_frame_count_eth1),

    .dst_count  (rx_eth_corrupt_frame_count_eth1_kernel)
);


cdc_count_11bit_toggle cdc_rx_eth_corrupt_frame_count_eth2_inst
(
    .src_clk    (rx_clk_eth2),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_corrupt_frame_count_eth2),

    .dst_count  (rx_eth_corrupt_frame_count_eth2_kernel)
);


cdc_count_11bit_toggle cdc_rx_eth_corrupt_frame_count_eth3_inst
(
    .src_clk    (rx_clk_eth3),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_corrupt_frame_count_eth3),

    .dst_count  (rx_eth_corrupt_frame_count_eth3_kernel)
);


cdc_count_11bit_toggle cdc_rx_eth_corrupt_frame_count_eth4_inst
(
    .src_clk    (rx_clk_eth4),
    .dst_clk    (clk),
    .rst_n      (rst_n),

    .src_count  (rx_eth_corrupt_frame_count_eth4),

    .dst_count  (rx_eth_corrupt_frame_count_eth4_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_uart1_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_uart1),

    .sync_out  (tx_fifo_empty_uart1_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_uart2_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_uart2),

    .sync_out  (tx_fifo_empty_uart2_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_uart3_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_uart3),

    .sync_out  (tx_fifo_empty_uart3_kernel)
);




cdc_bit_sync cdc_tx_fifo_empty_eth1_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_eth1),

    .sync_out  (tx_fifo_empty_eth1_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_eth2_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_eth2),

    .sync_out  (tx_fifo_empty_eth2_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_eth3_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_eth3),

    .sync_out  (tx_fifo_empty_eth3_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_eth4_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_eth4),

    .sync_out  (tx_fifo_empty_eth4_kernel)
);


cdc_bit_sync cdc_tx_fifo_empty_eth_nrz_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_fifo_empty_eth_nrz),

    .sync_out  (tx_fifo_empty_eth_nrz_kernel)
);




cdc_bit_sync cdc_rx_fifo_full_uart1_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_uart1),

    .sync_out  (rx_fifo_full_uart1_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_uart2_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_uart2),

    .sync_out  (rx_fifo_full_uart2_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_uart3_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_uart3),

    .sync_out  (rx_fifo_full_uart3_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_eth1_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_eth1),

    .sync_out  (rx_fifo_full_eth1_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_eth2_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_eth2),

    .sync_out  (rx_fifo_full_eth2_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_eth3_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_eth3),

    .sync_out  (rx_fifo_full_eth3_kernel)
);


cdc_bit_sync cdc_rx_fifo_full_eth4_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (rx_fifo_full_eth4),

    .sync_out  (rx_fifo_full_eth4_kernel)
);



cdc_bit_sync cdc_tx_data_sent_eth1_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_data_sent_eth1),

    .sync_out  (tx_data_sent_eth1_kernel)
);



cdc_bit_sync cdc_tx_data_sent_eth2_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_data_sent_eth2),

    .sync_out  (tx_data_sent_eth2_kernel)
);


cdc_bit_sync cdc_tx_data_sent_eth3_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_data_sent_eth3),

    .sync_out  (tx_data_sent_eth3_kernel)
);




cdc_bit_sync cdc_tx_data_sent_eth4_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_data_sent_eth4),

    .sync_out  (tx_data_sent_eth4_kernel)
);




cdc_bit_sync cdc_tx_data_sent_eth_nrz_inst
(
    .dst_clk   (clk),
    .rst_n     (rst_n),

    .async_in  (tx_data_sent_eth_nrz),

    .sync_out  (tx_data_sent_eth_nrz_kernel)
);

endmodule