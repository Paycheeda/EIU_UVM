module mdio_config_engine #(
    parameter [4:0] PHY_ADDR_DEFAULT = 5'd1,
    parameter [15:0] POLL_MAX_ATTEMPTS = 16'd65535
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start_config,

    output reg         config_busy,
    output reg         config_done,
    output reg         config_error,

    output reg  [15:0] last_read_data,
    output reg         last_read_valid,

    output wire        mdc,
    inout  wire        mdio
);

// ============================================================
// Command encoding
// Must match mdio_instruction_map.v
// ============================================================

localparam CMD_END        = 3'd0;
localparam CMD_WRITE      = 3'd1;
localparam CMD_READ       = 3'd2;
localparam CMD_READ_CHECK = 3'd3;
localparam CMD_POLL       = 3'd4;
localparam CMD_DELAY      = 3'd5;

// ============================================================
// MDIO operation encoding
// Must match mdio_master_clause22.v
// ============================================================

localparam WRITE_OPERATION = 1'b0;
localparam READ_OPERATION  = 1'b1;

// ============================================================
// Engine states
// ============================================================

localparam S_IDLE        = 5'd0;
localparam S_FETCH       = 5'd1;
localparam S_DECODE      = 5'd2;

localparam S_WRITE_START = 5'd3;
localparam S_WRITE_WAIT  = 5'd4;

localparam S_READ_START  = 5'd5;
localparam S_READ_WAIT   = 5'd6;
localparam S_READ_CHECK  = 5'd7;

localparam S_POLL_CHECK  = 5'd8;

localparam S_DELAY       = 5'd9;
localparam S_NEXT        = 5'd10;

localparam S_DONE        = 5'd11;
localparam S_ERROR       = 5'd12;

// ============================================================
// Engine registers
// ============================================================

reg [4:0]  state;
reg [7:0]  instruction_index;

reg [2:0]  active_cmd;
reg [4:0]  active_phy_addr;
reg [4:0]  active_reg_addr;
reg [15:0] active_write_data;
reg [15:0] active_expected_data;
reg [15:0] active_mask_data;
reg [31:0] active_delay_cycles;

reg [31:0] delay_counter;
reg [15:0] poll_attempt_count;

// ============================================================
// Instruction map wires
// ============================================================

wire [2:0]  map_cmd;
wire [4:0]  map_phy_addr;
wire [4:0]  map_reg_addr;
wire [15:0] map_write_data;
wire [15:0] map_expected_data;
wire [15:0] map_mask_data;
wire [31:0] map_delay_cycles;

mdio_instruction_map #(
    .PHY_ADDR_DEFAULT(PHY_ADDR_DEFAULT)
) u_mdio_instruction_map (
    .instruction_index (instruction_index),

    .cmd               (map_cmd),
    .phy_addr          (map_phy_addr),
    .reg_addr          (map_reg_addr),
    .write_data        (map_write_data),
    .expected_data     (map_expected_data),
    .mask_data         (map_mask_data),
    .delay_cycles      (map_delay_cycles)
);

// ============================================================
// MDIO master wires/registers
// ============================================================

reg        mdio_start_pulse;
reg        mdio_r_w_operation;
reg [4:0]  mdio_phy_add;
reg [4:0]  mdio_reg_add;
reg [15:0] mdio_data_tx;

wire [15:0] mdio_data_rx;
wire        mdio_transaction_done;

mdio_master_clause22 u_mdio_master_clause22 (
    .clk                   (clk),
    .rst_n                 (rst_n),

    .start_pulse            (mdio_start_pulse),
    .r_w_operation          (mdio_r_w_operation),

    .phy_add                (mdio_phy_add),
    .reg_add                (mdio_reg_add),
    .data_tx                (mdio_data_tx),

    .data_rx                (mdio_data_rx),
    .mdio_transaction_done  (mdio_transaction_done),

    .mdc                    (mdc),
    .mdio                   (mdio)
);

// ============================================================
// Main configuration engine FSM
// ============================================================

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state                 <= S_IDLE;
        instruction_index     <= 8'd0;

        config_busy           <= 1'b0;
        config_done           <= 1'b0;
        config_error          <= 1'b0;

        last_read_data        <= 16'd0;
        last_read_valid       <= 1'b0;

        active_cmd            <= CMD_END;
        active_phy_addr       <= PHY_ADDR_DEFAULT;
        active_reg_addr       <= 5'd0;
        active_write_data     <= 16'd0;
        active_expected_data  <= 16'd0;
        active_mask_data      <= 16'hFFFF;
        active_delay_cycles   <= 32'd0;

        delay_counter         <= 32'd0;
        poll_attempt_count    <= 16'd0;

        mdio_start_pulse      <= 1'b0;
        mdio_r_w_operation    <= READ_OPERATION;
        mdio_phy_add          <= PHY_ADDR_DEFAULT;
        mdio_reg_add          <= 5'd0;
        mdio_data_tx          <= 16'd0;
    end
    else
    begin
        config_done      <= 1'b0;
        last_read_valid  <= 1'b0;
        mdio_start_pulse <= 1'b0;

        case(state)

            // ----------------------------------------------------
            // Idle
            // ----------------------------------------------------
            S_IDLE:
            begin
                config_busy <= 1'b0;

                if(start_config)
                begin
                    instruction_index  <= 8'd0;
                    config_busy        <= 1'b1;
                    config_done        <= 1'b0;
                    config_error       <= 1'b0;
                    last_read_data     <= 16'd0;
                    delay_counter      <= 32'd0;
                    poll_attempt_count <= 16'd0;

                    state              <= S_FETCH;
                end
            end

            // ----------------------------------------------------
            // Let instruction ROM settle for current index
            // ----------------------------------------------------
            S_FETCH:
            begin
                state <= S_DECODE;
            end

            // ----------------------------------------------------
            // Latch current instruction
            // ----------------------------------------------------
            S_DECODE:
            begin
                active_cmd           <= map_cmd;
                active_phy_addr      <= map_phy_addr;
                active_reg_addr      <= map_reg_addr;
                active_write_data    <= map_write_data;
                active_expected_data <= map_expected_data;
                active_mask_data     <= map_mask_data;
                active_delay_cycles  <= map_delay_cycles;

                delay_counter        <= 32'd0;

                if(map_cmd == CMD_POLL)
                    poll_attempt_count <= 16'd0;

                case(map_cmd)

                    CMD_END:
                        state <= S_DONE;

                    CMD_WRITE:
                        state <= S_WRITE_START;

                    CMD_READ:
                        state <= S_READ_START;

                    CMD_READ_CHECK:
                        state <= S_READ_START;

                    CMD_POLL:
                        state <= S_READ_START;

                    CMD_DELAY:
                        state <= S_DELAY;

                    default:
                        state <= S_ERROR;

                endcase
            end

            // ----------------------------------------------------
            // Start write transaction
            // ----------------------------------------------------
            S_WRITE_START:
            begin
                mdio_phy_add       <= active_phy_addr;
                mdio_reg_add       <= active_reg_addr;
                mdio_data_tx       <= active_write_data;
                mdio_r_w_operation <= WRITE_OPERATION;
                mdio_start_pulse   <= 1'b1;

                state              <= S_WRITE_WAIT;
            end

            // ----------------------------------------------------
            // Wait for write completion
            // ----------------------------------------------------
            S_WRITE_WAIT:
            begin
                if(mdio_transaction_done)
                    state <= S_NEXT;
            end

            // ----------------------------------------------------
            // Start read transaction
            // ----------------------------------------------------
            S_READ_START:
            begin
                mdio_phy_add       <= active_phy_addr;
                mdio_reg_add       <= active_reg_addr;
                mdio_data_tx       <= 16'h0000;
                mdio_r_w_operation <= READ_OPERATION;
                mdio_start_pulse   <= 1'b1;

                state              <= S_READ_WAIT;
            end

            // ----------------------------------------------------
            // Wait for read completion
            // ----------------------------------------------------
            S_READ_WAIT:
            begin
                if(mdio_transaction_done)
                begin
                    last_read_data  <= mdio_data_rx;
                    last_read_valid <= 1'b1;

                    if(active_cmd == CMD_READ)
                        state <= S_NEXT;
                    else if(active_cmd == CMD_READ_CHECK)
                        state <= S_READ_CHECK;
                    else if(active_cmd == CMD_POLL)
                        state <= S_POLL_CHECK;
                    else
                        state <= S_ERROR;
                end
            end

            // ----------------------------------------------------
            // Check a read value once
            // ----------------------------------------------------
            S_READ_CHECK:
            begin
                if((last_read_data & active_mask_data) == (active_expected_data & active_mask_data))
                    state <= S_NEXT;
                else
                    state <= S_ERROR;
            end

            // ----------------------------------------------------
            // Poll until masked bits match expected value
            // ----------------------------------------------------
            S_POLL_CHECK:
            begin
                if((last_read_data & active_mask_data) == (active_expected_data & active_mask_data))
                begin
                    state <= S_NEXT;
                end
                else
                begin
                    if(poll_attempt_count >= POLL_MAX_ATTEMPTS)
                    begin
                        state <= S_ERROR;
                    end
                    else
                    begin
                        poll_attempt_count <= poll_attempt_count + 1'b1;
                        state <= S_READ_START;
                    end
                end
            end

            // ----------------------------------------------------
            // Delay instruction
            // ----------------------------------------------------
            S_DELAY:
            begin
                if(active_delay_cycles == 32'd0)
                begin
                    state <= S_NEXT;
                end
                else if(delay_counter >= active_delay_cycles - 1'b1)
                begin
                    delay_counter <= 32'd0;
                    state <= S_NEXT;
                end
                else
                begin
                    delay_counter <= delay_counter + 1'b1;
                    state <= S_DELAY;
                end
            end

            // ----------------------------------------------------
            // Advance to next instruction
            // ----------------------------------------------------
            S_NEXT:
            begin
                instruction_index <= instruction_index + 1'b1;
                state             <= S_FETCH;
            end

            // ----------------------------------------------------
            // Sequence completed successfully
            // ----------------------------------------------------
            S_DONE:
            begin
                config_busy  <= 1'b0;
                config_done  <= 1'b1;
                config_error <= 1'b0;
                state        <= S_IDLE;
            end

            // ----------------------------------------------------
            // Sequence failed
            // ----------------------------------------------------
            S_ERROR:
            begin
                config_busy  <= 1'b0;
                config_done  <= 1'b1;
                config_error <= 1'b1;
                state        <= S_IDLE;
            end

            default:
            begin
                config_busy  <= 1'b0;
                config_error <= 1'b1;
                state        <= S_IDLE;
            end

        endcase
    end
end

endmodule