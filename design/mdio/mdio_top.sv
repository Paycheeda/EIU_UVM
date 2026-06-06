module mdio_top #(

    parameter [4:0] PHY_ADDR_ETH1 = 5'd1,
    parameter [4:0] PHY_ADDR_ETH2 = 5'd1,
    parameter [4:0] PHY_ADDR_ETH3 = 5'd1,
    parameter [4:0] PHY_ADDR_ETH4 = 5'd1,
    parameter [4:0] PHY_ADDR_ETH5 = 5'd1,

    parameter [15:0] POLL_MAX_ATTEMPTS = 16'd65535

)(
    input  wire clk,
    input  wire rst_n,

    output wire config_busy_any,

    output wire all_config_done,
    output wire all_config_done_pulse,
    output wire all_config_success,
    output wire all_config_failed,
    output wire any_config_error,

    output wire [4:0] phy_config_busy,
    output wire [4:0] phy_config_done,
    output wire [4:0] phy_config_success,
    output wire [4:0] phy_config_error,

    output wire [7:0] mdio_status_led,

    output wire mdc_eth1,
    inout  wire mdio_eth1,

    output wire mdc_eth2,
    inout  wire mdio_eth2,

    output wire mdc_eth3,
    inout  wire mdio_eth3,

    output wire mdc_eth4,
    inout  wire mdio_eth4,

    output wire mdc_eth5,
    inout  wire mdio_eth5
);

// ============================================================
// Internal one-time start pulse after reset release
// ============================================================

reg start_config_issued;
reg start_config_pulse;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        start_config_issued <= 1'b0;
        start_config_pulse  <= 1'b0;
    end
    else
    begin
        if(!start_config_issued)
        begin
            start_config_pulse  <= 1'b1;
            start_config_issued <= 1'b1;
        end
        else
        begin
            start_config_pulse <= 1'b0;
        end
    end
end

// ============================================================
// Raw engine status wires
// ============================================================

wire [4:0] engine_busy;
wire [4:0] engine_done;
wire [4:0] engine_error;

// ============================================================
// Busy status
// ============================================================

assign config_busy_any = |engine_busy;
assign phy_config_busy = engine_busy;

// ============================================================
// Latched completion/error status
// ============================================================

reg [4:0] done_latched;
reg [4:0] error_latched;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        done_latched  <= 5'b00000;
        error_latched <= 5'b00000;
    end
    else
    begin
        if(start_config_pulse)
        begin
            done_latched  <= 5'b00000;
            error_latched <= 5'b00000;
        end
        else
        begin
            if(engine_done[0])
            begin
                done_latched[0]  <= 1'b1;
                error_latched[0] <= engine_error[0];
            end

            if(engine_done[1])
            begin
                done_latched[1]  <= 1'b1;
                error_latched[1] <= engine_error[1];
            end

            if(engine_done[2])
            begin
                done_latched[2]  <= 1'b1;
                error_latched[2] <= engine_error[2];
            end

            if(engine_done[3])
            begin
                done_latched[3]  <= 1'b1;
                error_latched[3] <= engine_error[3];
            end

            if(engine_done[4])
            begin
                done_latched[4]  <= 1'b1;
                error_latched[4] <= engine_error[4];
            end
        end
    end
end

// ============================================================
// Combined status
// ============================================================

wire all_done_level;
wire any_error_level;

assign all_done_level  = &done_latched;
assign any_error_level = |error_latched;

assign phy_config_done    = done_latched;
assign phy_config_error   = error_latched;
assign phy_config_success = done_latched & ~error_latched;

assign all_config_done    = all_done_level;
assign any_config_error   = any_error_level;
assign all_config_success = all_done_level & ~any_error_level;
assign all_config_failed  = all_done_level &  any_error_level;

// ============================================================
// One-clock pulse when all 5 PHY configs have completed
// ============================================================

reg all_done_level_d;

always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
        all_done_level_d <= 1'b0;
    else if(start_config_pulse)
        all_done_level_d <= 1'b0;
    else
        all_done_level_d <= all_done_level;
end

assign all_config_done_pulse = all_done_level & ~all_done_level_d;

// ============================================================
// LED status mapping
//
// Suggested EIU LED usage:
//
// LED[0] = ETH1 config success
// LED[1] = ETH2 config success
// LED[2] = ETH3 config success
// LED[3] = ETH4 config success
// LED[4] = ETH5 config success
// LED[5] = any PHY config error
// LED[6] = all PHY configs completed
// LED[7] = all PHY configs successful
// ============================================================

assign mdio_status_led[0] = phy_config_success[0];
assign mdio_status_led[1] = phy_config_success[1];
assign mdio_status_led[2] = phy_config_success[2];
assign mdio_status_led[3] = phy_config_success[3];
assign mdio_status_led[4] = phy_config_success[4];
assign mdio_status_led[5] = any_config_error;
assign mdio_status_led[6] = all_config_done;
assign mdio_status_led[7] = all_config_success;

// ============================================================
// ETH1 MDIO configuration engine
// ============================================================

mdio_config_engine #(
    .PHY_ADDR_DEFAULT  (PHY_ADDR_ETH1),
    .POLL_MAX_ATTEMPTS (POLL_MAX_ATTEMPTS)
) u_mdio_config_engine_eth1 (
    .clk             (clk),
    .rst_n           (rst_n),

    .start_config    (start_config_pulse),

    .config_busy     (engine_busy[0]),
    .config_done     (engine_done[0]),
    .config_error    (engine_error[0]),

    .last_read_data  (),
    .last_read_valid (),

    .mdc             (mdc_eth1),
    .mdio            (mdio_eth1)
);

// ============================================================
// ETH2 MDIO configuration engine
// ============================================================

mdio_config_engine #(
    .PHY_ADDR_DEFAULT  (PHY_ADDR_ETH2),
    .POLL_MAX_ATTEMPTS (POLL_MAX_ATTEMPTS)
) u_mdio_config_engine_eth2 (
    .clk             (clk),
    .rst_n           (rst_n),

    .start_config    (start_config_pulse),

    .config_busy     (engine_busy[1]),
    .config_done     (engine_done[1]),
    .config_error    (engine_error[1]),

    .last_read_data  (),
    .last_read_valid (),

    .mdc             (mdc_eth2),
    .mdio            (mdio_eth2)
);

// ============================================================
// ETH3 MDIO configuration engine
// ============================================================

mdio_config_engine #(
    .PHY_ADDR_DEFAULT  (PHY_ADDR_ETH3),
    .POLL_MAX_ATTEMPTS (POLL_MAX_ATTEMPTS)
) u_mdio_config_engine_eth3 (
    .clk             (clk),
    .rst_n           (rst_n),

    .start_config    (start_config_pulse),

    .config_busy     (engine_busy[2]),
    .config_done     (engine_done[2]),
    .config_error    (engine_error[2]),

    .last_read_data  (),
    .last_read_valid (),

    .mdc             (mdc_eth3),
    .mdio            (mdio_eth3)
);

// ============================================================
// ETH4 MDIO configuration engine
// ============================================================

mdio_config_engine #(
    .PHY_ADDR_DEFAULT  (PHY_ADDR_ETH4),
    .POLL_MAX_ATTEMPTS (POLL_MAX_ATTEMPTS)
) u_mdio_config_engine_eth4 (
    .clk             (clk),
    .rst_n           (rst_n),

    .start_config    (start_config_pulse),

    .config_busy     (engine_busy[3]),
    .config_done     (engine_done[3]),
    .config_error    (engine_error[3]),

    .last_read_data  (),
    .last_read_valid (),

    .mdc             (mdc_eth4),
    .mdio            (mdio_eth4)
);

// ============================================================
// ETH5 MDIO configuration engine
// ============================================================

mdio_config_engine #(
    .PHY_ADDR_DEFAULT  (PHY_ADDR_ETH5),
    .POLL_MAX_ATTEMPTS (POLL_MAX_ATTEMPTS)
) u_mdio_config_engine_eth5 (
    .clk             (clk),
    .rst_n           (rst_n),

    .start_config    (start_config_pulse),

    .config_busy     (engine_busy[4]),
    .config_done     (engine_done[4]),
    .config_error    (engine_error[4]),

    .last_read_data  (),
    .last_read_valid (),

    .mdc             (mdc_eth5),
    .mdio            (mdio_eth5)
);

endmodule