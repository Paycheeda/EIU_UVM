module mdio_instruction_map #(
    parameter [4:0] PHY_ADDR_DEFAULT = 5'd1
)(
    input  wire [7:0]  instruction_index,

    output reg  [2:0]  cmd,
    output reg  [4:0]  phy_addr,
    output reg  [4:0]  reg_addr,
    output reg  [15:0] write_data,
    output reg  [15:0] expected_data,
    output reg  [15:0] mask_data,
    output reg  [31:0] delay_cycles
);

// ============================================================
// Command encoding
// Must match mdio_config_engine.v
// ============================================================

localparam CMD_END        = 3'd0;
localparam CMD_WRITE      = 3'd1;
localparam CMD_READ       = 3'd2;
localparam CMD_READ_CHECK = 3'd3;
localparam CMD_POLL       = 3'd4;
localparam CMD_DELAY      = 3'd5;


// ============================================================
// KSZ9031RNX Clause-22 standard register addresses
// ============================================================

localparam [4:0] REG_BMCR            = 5'h00;
localparam [4:0] REG_BMSR            = 5'h01;
localparam [4:0] REG_PHYID1          = 5'h02;
localparam [4:0] REG_PHYID2          = 5'h03;
localparam [4:0] REG_ANAR            = 5'h04;
localparam [4:0] REG_ANLPAR          = 5'h05;
localparam [4:0] REG_ANEXP           = 5'h06;
localparam [4:0] REG_ANNPTR          = 5'h07;
localparam [4:0] REG_ANLPNP          = 5'h08;
localparam [4:0] REG_GBCR            = 5'h09;
localparam [4:0] REG_GBSR            = 5'h0A;
localparam [4:0] REG_MMD_CTRL        = 5'h0D;
localparam [4:0] REG_MMD_DATA        = 5'h0E;
localparam [4:0] REG_EXT_STATUS      = 5'h0F;

localparam [4:0] REG_REMOTE_LOOPBACK = 5'h11;
localparam [4:0] REG_LINKMD          = 5'h12;
localparam [4:0] REG_PMA_PCS_STATUS  = 5'h13;
localparam [4:0] REG_RXER_COUNTER    = 5'h15;
localparam [4:0] REG_INT_CTRL_STATUS = 5'h1B;
localparam [4:0] REG_AUTO_MDIX       = 5'h1C;
localparam [4:0] REG_PHY_CTRL        = 5'h1F;


// ============================================================
// KSZ9031RNX expected values / masks
// ============================================================

// KSZ9031RNX PHY IDs:
// PHYID1 = 0x0022
// PHYID2 = 0x162x, where lower nibble is silicon revision.
localparam [15:0] PHYID1_EXPECTED = 16'h0022;
localparam [15:0] PHYID2_EXPECTED = 16'h1620;
localparam [15:0] PHYID2_MASK     = 16'hFFF0;

// BMSR bit 5 = Auto-Negotiation Complete
// BMSR bit 2 = Link Status
localparam [15:0] BMSR_LINK_AN_MASK     = 16'h0024;
localparam [15:0] BMSR_LINK_AN_EXPECTED = 16'h0024;

// BMCR normal/restart value for auto-negotiation operation.
// bit14 loopback = 0
// bit12 auto-neg enable = 1
// bit9 restart auto-neg = 1 for write only, self-clears
// bit8 full duplex = 1, ignored when auto-neg is enabled
// bit6 speed select = 1, ignored when auto-neg is enabled
localparam [15:0] BMCR_RESTART_AN_VALUE = 16'h1340;
localparam [15:0] BMCR_NORMAL_EXPECTED  = 16'h1000;
localparam [15:0] BMCR_NORMAL_MASK      = 16'h5C00;

// Advertise 10/100 half/full capability, IEEE 802.3 selector, no pause.
localparam [15:0] ANAR_ADV_VALUE = 16'h01E1;

// Advertise 1000BASE-T full-duplex only.
localparam [15:0] GBCR_ADV_VALUE = 16'h0200;
localparam [15:0] GBCR_ADV_MASK  = 16'h1F00;

// Register 1Ch: Auto MDI/MDI-X enabled, manual MDI/MDI-X disabled.
localparam [15:0] AUTO_MDIX_VALUE = 16'h0000;
localparam [15:0] AUTO_MDIX_MASK  = 16'h00C0;

// Register 1Fh: interrupt active-low, jabber counter enabled.
localparam [15:0] PHY_CTRL_VALUE = 16'h0200;
localparam [15:0] PHY_CTRL_MASK  = 16'h4200;

// Register 1Bh: disable all interrupt enables.
localparam [15:0] INT_CTRL_DISABLE_VALUE = 16'h0000;


// ============================================================
// KSZ9031RNX MMD / RGMII pad skew settings
// ============================================================

// MMD device address 2h contains RGMII pad skew registers.
// Pad skew defaults are 0x7 for 4-bit data/control skew fields
// and 0x0F for 5-bit clock skew fields.
//
// RGMII TX clock skew requirement:
// The KSZ9031RNX expects MAC-side GTX_CLK delay by default. If the
// FPGA/MAC does not add enough TX clock skew, program MMD2.Reg8 GTX_CLK
// field to maximum while keeping RX_CLK field at its default value.
//
// RGMII_CLOCK_SKEW_VALUE layout, MMD2.Reg8:
// bits [9:5] = GTX_CLK input pad skew = 5'h1F  -> maximum positive adjustment
// bits [4:0] = RX_CLK output pad skew = 5'h0F  -> default, keeps RX_CLK around 1.2 ns internal skew
// value = {6'b000000, 5'h1F, 5'h0F} = 16'h03EF
localparam [15:0] RGMII_CTRL_SKEW_VALUE    = 16'h0077;
localparam [15:0] RGMII_RX_DATA_SKEW_VALUE = 16'h7777;
localparam [15:0] RGMII_TX_DATA_SKEW_VALUE = 16'h7777;
localparam [15:0] RGMII_CLOCK_SKEW_VALUE   = 16'h03EF;

// Keep WOL disabled in this configuration sequence.
localparam [15:0] WOL_CONTROL_DISABLE_VALUE = 16'h0000;

// Delay values are in mdio_config_engine clock cycles.
localparam [31:0] KSZ_DELAY_AFTER_RESET_CYCLES   = 32'd50000;  // 2 ms @ 25 MHz
localparam [31:0] KSZ_DELAY_AFTER_RESTART_CYCLES = 32'd25000;  // 1 ms @ 25 MHz


// ============================================================
// Instruction ROM
//
// This map is for KSZ9031RNX.
// It keeps mdio_master_clause22.v and mdio_config_engine.v generic.
// MMD accesses are encoded through Clause-22 portal registers 0Dh/0Eh.
// ============================================================

always @(*)
begin
    // Default safe values
    cmd           = CMD_END;
    phy_addr      = PHY_ADDR_DEFAULT;
    reg_addr      = 5'd0;
    write_data    = 16'd0;
    expected_data = 16'd0;
    mask_data     = 16'hFFFF;
    delay_cycles  = 32'd0;

    case(instruction_index)

        // ----------------------------------------------------
        // 0: Optional settle delay after PHY reset
        // ----------------------------------------------------
        8'd0:
        begin
            cmd = CMD_DELAY;
            delay_cycles = KSZ_DELAY_AFTER_RESET_CYCLES;
        end
        // ----------------------------------------------------
        // 1: Verify KSZ9031 PHY ID1
        // ----------------------------------------------------
        8'd1:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_PHYID1;
            expected_data = PHYID1_EXPECTED;
            mask_data = 16'hFFFF;
        end
        // ----------------------------------------------------
        // 2: Verify KSZ9031 PHY ID2/model, ignore revision nibble
        // ----------------------------------------------------
        8'd2:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_PHYID2;
            expected_data = PHYID2_EXPECTED;
            mask_data = PHYID2_MASK;
        end
        // ----------------------------------------------------
        // 3: Advertise 10/100 capabilities, no pause
        // ----------------------------------------------------
        8'd3:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_ANAR;
            write_data = ANAR_ADV_VALUE;
        end
        // ----------------------------------------------------
        // 4: Confirm ANAR advertisement
        // ----------------------------------------------------
        8'd4:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_ANAR;
            expected_data = ANAR_ADV_VALUE;
            mask_data = 16'hFFFF;
        end
        // ----------------------------------------------------
        // 5: Advertise 1000BASE-T full duplex only
        // ----------------------------------------------------
        8'd5:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_GBCR;
            write_data = GBCR_ADV_VALUE;
        end
        // ----------------------------------------------------
        // 6: Confirm 1000BASE-T advertisement bits
        // ----------------------------------------------------
        8'd6:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_GBCR;
            expected_data = GBCR_ADV_VALUE;
            mask_data = GBCR_ADV_MASK;
        end
        // ----------------------------------------------------
        // 7: Enable Auto MDI/MDI-X
        // ----------------------------------------------------
        8'd7:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_AUTO_MDIX;
            write_data = AUTO_MDIX_VALUE;
        end
        // ----------------------------------------------------
        // 8: Confirm Auto MDI/MDI-X enabled
        // ----------------------------------------------------
        8'd8:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_AUTO_MDIX;
            expected_data = AUTO_MDIX_VALUE;
            mask_data = AUTO_MDIX_MASK;
        end
        // ----------------------------------------------------
        // 9: Set PHY Control safe defaults: INT active-low, jabber counter enabled
        // ----------------------------------------------------
        8'd9:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_PHY_CTRL;
            write_data = PHY_CTRL_VALUE;
        end
        // ----------------------------------------------------
        // 10: Confirm PHY Control safe bits
        // ----------------------------------------------------
        8'd10:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_PHY_CTRL;
            expected_data = PHY_CTRL_VALUE;
            mask_data = PHY_CTRL_MASK;
        end
        // ----------------------------------------------------
        // 11: Disable all PHY interrupts / clear upper enable bits
        // ----------------------------------------------------
        8'd11:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_INT_CTRL_STATUS;
            write_data = INT_CTRL_DISABLE_VALUE;
        end
        // ----------------------------------------------------
        // 12: Read interrupt control/status once; lower status bits are read-clear
        // ----------------------------------------------------
        8'd12:
        begin
            cmd = CMD_READ;
            reg_addr = REG_INT_CTRL_STATUS;
        end
        // ----------------------------------------------------
        // 13: MMD2.0004: select MMD device address for RGMII control signal skew
        // ----------------------------------------------------
        8'd13:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 14: MMD2.0004: select register address for RGMII control signal skew
        // ----------------------------------------------------
        8'd14:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0004;
        end
        // ----------------------------------------------------
        // 15: MMD2.0004: select data mode for write
        // ----------------------------------------------------
        8'd15:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 16: MMD2.0004: write RGMII control signal skew
        // ----------------------------------------------------
        8'd16:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = RGMII_CTRL_SKEW_VALUE;
        end
        // ----------------------------------------------------
        // 17: MMD2.0004: reselect MMD device address for readback
        // ----------------------------------------------------
        8'd17:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 18: MMD2.0004: reselect register address for readback
        // ----------------------------------------------------
        8'd18:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0004;
        end
        // ----------------------------------------------------
        // 19: MMD2.0004: select data mode for readback
        // ----------------------------------------------------
        8'd19:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 20: MMD2.0004: confirm RGMII control signal skew
        // ----------------------------------------------------
        8'd20:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_MMD_DATA;
            expected_data = RGMII_CTRL_SKEW_VALUE;
            mask_data = 16'h00FF;
        end
        // ----------------------------------------------------
        // 21: MMD2.0005: select MMD device address for RGMII RX data skew
        // ----------------------------------------------------
        8'd21:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 22: MMD2.0005: select register address for RGMII RX data skew
        // ----------------------------------------------------
        8'd22:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0005;
        end
        // ----------------------------------------------------
        // 23: MMD2.0005: select data mode for write
        // ----------------------------------------------------
        8'd23:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 24: MMD2.0005: write RGMII RX data skew
        // ----------------------------------------------------
        8'd24:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = RGMII_RX_DATA_SKEW_VALUE;
        end
        // ----------------------------------------------------
        // 25: MMD2.0005: reselect MMD device address for readback
        // ----------------------------------------------------
        8'd25:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 26: MMD2.0005: reselect register address for readback
        // ----------------------------------------------------
        8'd26:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0005;
        end
        // ----------------------------------------------------
        // 27: MMD2.0005: select data mode for readback
        // ----------------------------------------------------
        8'd27:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 28: MMD2.0005: confirm RGMII RX data skew
        // ----------------------------------------------------
        8'd28:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_MMD_DATA;
            expected_data = RGMII_RX_DATA_SKEW_VALUE;
            mask_data = 16'hFFFF;
        end
        // ----------------------------------------------------
        // 29: MMD2.0006: select MMD device address for RGMII TX data skew
        // ----------------------------------------------------
        8'd29:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 30: MMD2.0006: select register address for RGMII TX data skew
        // ----------------------------------------------------
        8'd30:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0006;
        end
        // ----------------------------------------------------
        // 31: MMD2.0006: select data mode for write
        // ----------------------------------------------------
        8'd31:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 32: MMD2.0006: write RGMII TX data skew
        // ----------------------------------------------------
        8'd32:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = RGMII_TX_DATA_SKEW_VALUE;
        end
        // ----------------------------------------------------
        // 33: MMD2.0006: reselect MMD device address for readback
        // ----------------------------------------------------
        8'd33:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 34: MMD2.0006: reselect register address for readback
        // ----------------------------------------------------
        8'd34:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0006;
        end
        // ----------------------------------------------------
        // 35: MMD2.0006: select data mode for readback
        // ----------------------------------------------------
        8'd35:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 36: MMD2.0006: confirm RGMII TX data skew
        // ----------------------------------------------------
        8'd36:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_MMD_DATA;
            expected_data = RGMII_TX_DATA_SKEW_VALUE;
            mask_data = 16'hFFFF;
        end
        // ----------------------------------------------------
        // 37: MMD2.0008: select MMD device address for RGMII clock skew, GTX_CLK delayed, RX_CLK default
        // ----------------------------------------------------
        8'd37:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 38: MMD2.0008: select register address for RGMII clock skew, GTX_CLK delayed, RX_CLK default
        // ----------------------------------------------------
        8'd38:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0008;
        end
        // ----------------------------------------------------
        // 39: MMD2.0008: select data mode for write
        // ----------------------------------------------------
        8'd39:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 40: MMD2.0008: write RGMII clock skew, GTX_CLK delayed, RX_CLK default
        // ----------------------------------------------------
        8'd40:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = RGMII_CLOCK_SKEW_VALUE;
        end
        // ----------------------------------------------------
        // 41: MMD2.0008: reselect MMD device address for readback
        // ----------------------------------------------------
        8'd41:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 42: MMD2.0008: reselect register address for readback
        // ----------------------------------------------------
        8'd42:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0008;
        end
        // ----------------------------------------------------
        // 43: MMD2.0008: select data mode for readback
        // ----------------------------------------------------
        8'd43:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 44: MMD2.0008: confirm RGMII clock skew, GTX_CLK delayed, RX_CLK default
        // ----------------------------------------------------
        8'd44:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_MMD_DATA;
            expected_data = RGMII_CLOCK_SKEW_VALUE;
            mask_data = 16'h03FF;
        end
        // ----------------------------------------------------
        // 45: MMD2.0010: select MMD device address for WOL control disabled
        // ----------------------------------------------------
        8'd45:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 46: MMD2.0010: select register address for WOL control disabled
        // ----------------------------------------------------
        8'd46:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0010;
        end
        // ----------------------------------------------------
        // 47: MMD2.0010: select data mode for write
        // ----------------------------------------------------
        8'd47:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 48: MMD2.0010: write WOL control disabled
        // ----------------------------------------------------
        8'd48:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = WOL_CONTROL_DISABLE_VALUE;
        end
        // ----------------------------------------------------
        // 49: MMD2.0010: reselect MMD device address for readback
        // ----------------------------------------------------
        8'd49:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 50: MMD2.0010: reselect register address for readback
        // ----------------------------------------------------
        8'd50:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0010;
        end
        // ----------------------------------------------------
        // 51: MMD2.0010: select data mode for readback
        // ----------------------------------------------------
        8'd51:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 52: MMD2.0010: confirm WOL control disabled
        // ----------------------------------------------------
        8'd52:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_MMD_DATA;
            expected_data = WOL_CONTROL_DISABLE_VALUE;
            mask_data = 16'hFFFF;
        end
        // ----------------------------------------------------
        // 53: Restart auto-negotiation with normal BMCR
        // ----------------------------------------------------
        8'd53:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_BMCR;
            write_data = BMCR_RESTART_AN_VALUE;
        end
        // ----------------------------------------------------
        // 54: Small delay after BMCR restart write
        // ----------------------------------------------------
        8'd54:
        begin
            cmd = CMD_DELAY;
            delay_cycles = KSZ_DELAY_AFTER_RESTART_CYCLES;
        end
        // ----------------------------------------------------
        // 55: Confirm BMCR normal mode bits
        // ----------------------------------------------------
        8'd55:
        begin
            cmd = CMD_READ_CHECK;
            reg_addr = REG_BMCR;
            expected_data = BMCR_NORMAL_EXPECTED;
            mask_data = BMCR_NORMAL_MASK;
        end
        // ----------------------------------------------------
        // 56: Poll BMSR until link up + auto-neg complete
        // ----------------------------------------------------
        8'd56:
        begin
            cmd = CMD_POLL;
            reg_addr = REG_BMSR;
            expected_data = BMSR_LINK_AN_EXPECTED;
            mask_data = BMSR_LINK_AN_MASK;
        end
        // ----------------------------------------------------
        // 57: Read BMCR for debug
        // ----------------------------------------------------
        8'd57:
        begin
            cmd = CMD_READ;
            reg_addr = REG_BMCR;
        end
        // ----------------------------------------------------
        // 58: Read BMSR for debug
        // ----------------------------------------------------
        8'd58:
        begin
            cmd = CMD_READ;
            reg_addr = REG_BMSR;
        end
        // ----------------------------------------------------
        // 59: Read PHYID1 for debug
        // ----------------------------------------------------
        8'd59:
        begin
            cmd = CMD_READ;
            reg_addr = REG_PHYID1;
        end
        // ----------------------------------------------------
        // 60: Read PHYID2 for debug
        // ----------------------------------------------------
        8'd60:
        begin
            cmd = CMD_READ;
            reg_addr = REG_PHYID2;
        end
        // ----------------------------------------------------
        // 61: Read ANAR for debug
        // ----------------------------------------------------
        8'd61:
        begin
            cmd = CMD_READ;
            reg_addr = REG_ANAR;
        end
        // ----------------------------------------------------
        // 62: Read ANLPAR for debug
        // ----------------------------------------------------
        8'd62:
        begin
            cmd = CMD_READ;
            reg_addr = REG_ANLPAR;
        end
        // ----------------------------------------------------
        // 63: Read ANEXP for debug
        // ----------------------------------------------------
        8'd63:
        begin
            cmd = CMD_READ;
            reg_addr = REG_ANEXP;
        end
        // ----------------------------------------------------
        // 64: Read ANNPTR for debug
        // ----------------------------------------------------
        8'd64:
        begin
            cmd = CMD_READ;
            reg_addr = REG_ANNPTR;
        end
        // ----------------------------------------------------
        // 65: Read ANLPNP for debug
        // ----------------------------------------------------
        8'd65:
        begin
            cmd = CMD_READ;
            reg_addr = REG_ANLPNP;
        end
        // ----------------------------------------------------
        // 66: Read 1000BT Control for debug
        // ----------------------------------------------------
        8'd66:
        begin
            cmd = CMD_READ;
            reg_addr = REG_GBCR;
        end
        // ----------------------------------------------------
        // 67: Read 1000BT Status for debug
        // ----------------------------------------------------
        8'd67:
        begin
            cmd = CMD_READ;
            reg_addr = REG_GBSR;
        end
        // ----------------------------------------------------
        // 68: Read Extended Status for debug
        // ----------------------------------------------------
        8'd68:
        begin
            cmd = CMD_READ;
            reg_addr = REG_EXT_STATUS;
        end
        // ----------------------------------------------------
        // 69: Read Remote Loopback for debug
        // ----------------------------------------------------
        8'd69:
        begin
            cmd = CMD_READ;
            reg_addr = REG_REMOTE_LOOPBACK;
        end
        // ----------------------------------------------------
        // 70: Read LinkMD for debug
        // ----------------------------------------------------
        8'd70:
        begin
            cmd = CMD_READ;
            reg_addr = REG_LINKMD;
        end
        // ----------------------------------------------------
        // 71: Read Digital PMA/PCS Status for debug
        // ----------------------------------------------------
        8'd71:
        begin
            cmd = CMD_READ;
            reg_addr = REG_PMA_PCS_STATUS;
        end
        // ----------------------------------------------------
        // 72: Read RXER Counter for debug
        // ----------------------------------------------------
        8'd72:
        begin
            cmd = CMD_READ;
            reg_addr = REG_RXER_COUNTER;
        end
        // ----------------------------------------------------
        // 73: Read Interrupt Control/Status for debug
        // ----------------------------------------------------
        8'd73:
        begin
            cmd = CMD_READ;
            reg_addr = REG_INT_CTRL_STATUS;
        end
        // ----------------------------------------------------
        // 74: Read Auto MDI/MDI-X for debug
        // ----------------------------------------------------
        8'd74:
        begin
            cmd = CMD_READ;
            reg_addr = REG_AUTO_MDIX;
        end
        // ----------------------------------------------------
        // 75: Read PHY Control for debug
        // ----------------------------------------------------
        8'd75:
        begin
            cmd = CMD_READ;
            reg_addr = REG_PHY_CTRL;
        end
        // ----------------------------------------------------
        // 76: MMD2.0000: select MMD device address for read Common Control
        // ----------------------------------------------------
        8'd76:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 77: MMD2.0000: select register address for read Common Control
        // ----------------------------------------------------
        8'd77:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0000;
        end
        // ----------------------------------------------------
        // 78: MMD2.0000: select data mode for read Common Control
        // ----------------------------------------------------
        8'd78:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 79: MMD2.0000: read Common Control
        // ----------------------------------------------------
        8'd79:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 80: MMD2.0001: select MMD device address for read Strap Status
        // ----------------------------------------------------
        8'd80:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 81: MMD2.0001: select register address for read Strap Status
        // ----------------------------------------------------
        8'd81:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0001;
        end
        // ----------------------------------------------------
        // 82: MMD2.0001: select data mode for read Strap Status
        // ----------------------------------------------------
        8'd82:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 83: MMD2.0001: read Strap Status
        // ----------------------------------------------------
        8'd83:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 84: MMD2.0002: select MMD device address for read Operation Mode Strap Override
        // ----------------------------------------------------
        8'd84:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 85: MMD2.0002: select register address for read Operation Mode Strap Override
        // ----------------------------------------------------
        8'd85:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 86: MMD2.0002: select data mode for read Operation Mode Strap Override
        // ----------------------------------------------------
        8'd86:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 87: MMD2.0002: read Operation Mode Strap Override
        // ----------------------------------------------------
        8'd87:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 88: MMD2.0003: select MMD device address for read Operation Mode Strap Status
        // ----------------------------------------------------
        8'd88:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 89: MMD2.0003: select register address for read Operation Mode Strap Status
        // ----------------------------------------------------
        8'd89:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0003;
        end
        // ----------------------------------------------------
        // 90: MMD2.0003: select data mode for read Operation Mode Strap Status
        // ----------------------------------------------------
        8'd90:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 91: MMD2.0003: read Operation Mode Strap Status
        // ----------------------------------------------------
        8'd91:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 92: MMD2.0004: select MMD device address for read RGMII Control Signal Pad Skew
        // ----------------------------------------------------
        8'd92:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 93: MMD2.0004: select register address for read RGMII Control Signal Pad Skew
        // ----------------------------------------------------
        8'd93:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0004;
        end
        // ----------------------------------------------------
        // 94: MMD2.0004: select data mode for read RGMII Control Signal Pad Skew
        // ----------------------------------------------------
        8'd94:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 95: MMD2.0004: read RGMII Control Signal Pad Skew
        // ----------------------------------------------------
        8'd95:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 96: MMD2.0005: select MMD device address for read RGMII RX Data Pad Skew
        // ----------------------------------------------------
        8'd96:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 97: MMD2.0005: select register address for read RGMII RX Data Pad Skew
        // ----------------------------------------------------
        8'd97:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0005;
        end
        // ----------------------------------------------------
        // 98: MMD2.0005: select data mode for read RGMII RX Data Pad Skew
        // ----------------------------------------------------
        8'd98:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 99: MMD2.0005: read RGMII RX Data Pad Skew
        // ----------------------------------------------------
        8'd99:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 100: MMD2.0006: select MMD device address for read RGMII TX Data Pad Skew
        // ----------------------------------------------------
        8'd100:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 101: MMD2.0006: select register address for read RGMII TX Data Pad Skew
        // ----------------------------------------------------
        8'd101:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0006;
        end
        // ----------------------------------------------------
        // 102: MMD2.0006: select data mode for read RGMII TX Data Pad Skew
        // ----------------------------------------------------
        8'd102:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 103: MMD2.0006: read RGMII TX Data Pad Skew
        // ----------------------------------------------------
        8'd103:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 104: MMD2.0008: select MMD device address for read RGMII Clock Pad Skew
        // ----------------------------------------------------
        8'd104:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 105: MMD2.0008: select register address for read RGMII Clock Pad Skew
        // ----------------------------------------------------
        8'd105:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0008;
        end
        // ----------------------------------------------------
        // 106: MMD2.0008: select data mode for read RGMII Clock Pad Skew
        // ----------------------------------------------------
        8'd106:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 107: MMD2.0008: read RGMII Clock Pad Skew
        // ----------------------------------------------------
        8'd107:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 108: MMD2.0010: select MMD device address for read WOL Control
        // ----------------------------------------------------
        8'd108:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 109: MMD2.0010: select register address for read WOL Control
        // ----------------------------------------------------
        8'd109:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0010;
        end
        // ----------------------------------------------------
        // 110: MMD2.0010: select data mode for read WOL Control
        // ----------------------------------------------------
        8'd110:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 111: MMD2.0010: read WOL Control
        // ----------------------------------------------------
        8'd111:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 112: MMD2.0011: select MMD device address for read WOL Magic Packet MAC-DA-0
        // ----------------------------------------------------
        8'd112:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 113: MMD2.0011: select register address for read WOL Magic Packet MAC-DA-0
        // ----------------------------------------------------
        8'd113:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0011;
        end
        // ----------------------------------------------------
        // 114: MMD2.0011: select data mode for read WOL Magic Packet MAC-DA-0
        // ----------------------------------------------------
        8'd114:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 115: MMD2.0011: read WOL Magic Packet MAC-DA-0
        // ----------------------------------------------------
        8'd115:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 116: MMD2.0012: select MMD device address for read WOL Magic Packet MAC-DA-1
        // ----------------------------------------------------
        8'd116:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 117: MMD2.0012: select register address for read WOL Magic Packet MAC-DA-1
        // ----------------------------------------------------
        8'd117:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0012;
        end
        // ----------------------------------------------------
        // 118: MMD2.0012: select data mode for read WOL Magic Packet MAC-DA-1
        // ----------------------------------------------------
        8'd118:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 119: MMD2.0012: read WOL Magic Packet MAC-DA-1
        // ----------------------------------------------------
        8'd119:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 120: MMD2.0013: select MMD device address for read WOL Magic Packet MAC-DA-2
        // ----------------------------------------------------
        8'd120:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h0002;
        end
        // ----------------------------------------------------
        // 121: MMD2.0013: select register address for read WOL Magic Packet MAC-DA-2
        // ----------------------------------------------------
        8'd121:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_DATA;
            write_data = 16'h0013;
        end
        // ----------------------------------------------------
        // 122: MMD2.0013: select data mode for read WOL Magic Packet MAC-DA-2
        // ----------------------------------------------------
        8'd122:
        begin
            cmd = CMD_WRITE;
            reg_addr = REG_MMD_CTRL;
            write_data = 16'h4002;
        end
        // ----------------------------------------------------
        // 123: MMD2.0013: read WOL Magic Packet MAC-DA-2
        // ----------------------------------------------------
        8'd123:
        begin
            cmd = CMD_READ;
            reg_addr = REG_MMD_DATA;
        end
        // ----------------------------------------------------
        // 124: End configuration sequence
        // ----------------------------------------------------
        8'd124:
        begin
            cmd = CMD_END;
        end

        default:
        begin
            cmd = CMD_END;
        end

    endcase
end

endmodule
