`ifndef BKP_INTF_SV
`define BKP_INTF_SV

interface bkp_intf(input logic clk, input logic rst_n);
    
    // ==========================================
    // Master to Slave (Backplane to EIU)
    // ==========================================
    logic        bkp_config_wr_pulse; // 50-60ns pulse for config writes
    logic        program_mode;        // High when master is configuring the EIU
    logic        word_start_strobe;   // 1cc pulse to push read data to the bus
    
    logic [3:0]  bkp_card_id;         // The ID the backplane is trying to talk to
    logic [3:0]  fpga_card_id;        // The hardwired ID of this specific EIU card
    
    logic        bkp_data_dir;        // 1 = Write (BKP drives), 0 = Read (EIU drives)
    logic [5:0]  bkp_address;         // Register / FIFO memory map address
    
    // ==========================================
    // Bidirectional Data Bus
    // ==========================================
    wire  [11:0] bkp_data;            // The actual physical pin
    
    // Internal register for the UVM Driver to manipulate
    logic [11:0] bkp_data_drive;
    
    // Continuous assignment: 
    // If Backplane is writing (dir==1), drive the physical bus. 
    // If Backplane is reading (dir==0), go High-Z to let the EIU drive it.
    assign bkp_data = (bkp_data_dir == 1'b1) ? bkp_data_drive : 12'bz;

endinterface

`endif