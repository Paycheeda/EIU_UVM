`ifndef BKP_INTF_SV
`define BKP_INTF_SV

interface bkp_intf(input logic clk, input logic rst_n);
    
    logic        bkp_config_wr_pulse;
    logic [3:0]  bkp_card_id;
    logic [3:0]  fpga_card_id;
    logic        bkp_data_dir; // 1 = Write, 0 = Read
    logic [5:0]  bkp_address;
    
    // THE FIX: Must be a 'wire' to support bidirectional driving!
    wire [11:0]  bkp_data;

    // A register for the UVM driver to use. 
    // We will drive 'Z' when bkp_data_dir is 0 (Read).
    logic [11:0] bkp_data_drive;
    
    // Continuous assignment: if writing, drive the bus. If reading, go High-Z.
    assign bkp_data = (bkp_data_dir == 1'b1) ? bkp_data_drive : 12'bz;

endinterface

`endif