`timescale 1ns/100fs

module tb_top_loopback_uart_fifo;
  import uvm_pkg::*;
  import fifo_pkg::*;                 // Bring in the FIFO items
  import loopback_uartfifo_pkg::*;    // Bring in the Config items and the Test!
  
  // ==========================================
  // 1. SYSTEM CLOCKS & RESET (DECLARATIONS)
  // ==========================================
  bit clk_44_2386MHz; 
  bit clk_64MHz;      
  bit rst_n;

  // ==========================================
  // 2. INTERNAL ROUTING WIRES
  // ==========================================
  wire serial_loopback_link;
  wire uart1_tx_busy_wire;
  // --- NEW: RTL Stat Wires (STANDARDIZED NAMES) ---
  wire [10:0] uart1_rx_corrupt_byte_count;
  wire [10:0] uart1_rx_valid_byte_count;


  // TX FIFO to UART Wires
  wire [15:0] uart1_TX_data_fifo_out; // 16 bits!
  wire        uart1_TX_fifo_empty;
  wire        fifo_read_data_pulse_wire;

  // UART to RX FIFO Wires
  wire [15:0] uart1_RX_data_fifo_in;  // 16 bits!
  wire        uart1_RX_data_ready_pulse_out;
  wire        uart1_RX_data_corrupt_flag_out; 
  
  // --- EXPLICIT PADDING WIRES ---
  wire [15:0] tx_data_in_padded;
  wire [15:0] rx_data_out_padded;

  wire uart1_rx_busy_wire;

  // ==========================================
  // 3. UVM INTERFACES & ASSIGNMENTS
  // ==========================================
  fifo_intf_uart   #(9) vif_tx(clk_64MHz, clk_44_2386MHz); 
  fifo_intf_uart   #(9) vif_rx(clk_44_2386MHz, clk_64MHz); 
  uart_config_intf      vif_cfg(clk_44_2386MHz);
  serial_line_intf      vif_serial(clk_44_2386MHz, rst_n);

  error_inject_intf     err_vif(clk_44_2386MHz);

  assign vif_serial.serial_line = serial_loopback_link;


  // Route RTL stats into the UVM Config Interface
  assign vif_cfg.hw_rx_corrupt_bytes = uart1_rx_corrupt_byte_count;
  assign vif_cfg.hw_rx_valid_bytes   = uart1_rx_valid_byte_count;

  // Pad the 9-bit UVM output to 16 bits for the TX FIFO
  assign tx_data_in_padded = {7'b0, vif_tx.data_in};

  // Pad the 9-bit UART output to 16 bits for the RX FIFO
  wire [8:0] uart1_RX_data_raw; 
  assign uart1_RX_data_fifo_in = {7'b0, uart1_RX_data_raw};

  // Slice the 16-bit RX FIFO output back down to 9 bits for UVM
  assign vif_rx.data_out = rx_data_out_padded[8:0];

  assign vif_cfg.uart_tx_busy = uart1_tx_busy_wire;

  assign vif_serial.serial_line = serial_loopback_link;
  assign vif_cfg.uart_rx_busy        = uart1_rx_busy_wire;


  // ==========================================
  // 4. HARDWARE INSTANTIATIONS
  // ==========================================
  
  // TX FIFO: UVM writes to it, New UART reads from it.
  dual_port_FIFO #(
      .PARAM_DATA_WIDTH(16), // FIX: Force 16-bit
      .PARAM_FIFO_SIZE("18Kb")
  ) uart1_tx_fifo (
      .rst_n          (rst_n),
      .wr_clk         (clk_64MHz),
      .data_in        (tx_data_in_padded), // 16-bit Padded input
      .wr_en          (vif_tx.wr_en),              
      .rd_clk         (clk_44_2386MHz),
      .rd_en          (fifo_read_data_pulse_wire), 
      .data_out       (uart1_TX_data_fifo_out),    // 16-bit output
      .fifo_full      (vif_tx.fifo_full),
      .fifo_empty     (uart1_TX_fifo_empty)
  );

  // NEW UART WRAPPER
  uart #(
      .PARAM_MAX_DATA_WIDTH(9)
  ) uart_1 (
      .clk                    (clk_44_2386MHz),
      .rst_n                  (rst_n),
      .baudrate               (vif_cfg.baudrate),
      .parity_en              (vif_cfg.parity_en),
      .parity_odd_even        (vif_cfg.parity_odd_even),
      .data_width             (vif_cfg.data_width),
      .config_done_pulse      (vif_cfg.config_done_pulse),
      
      .rx                     (serial_loopback_link),
      .tx                     (serial_loopback_link),
      
      // TX Interface
      .tx_fifo_rd_en          (fifo_read_data_pulse_wire),
      .tx_fifo_data           (uart1_TX_data_fifo_out[8:0]), 
      .tx_acq_start           (~uart1_TX_fifo_empty), 
      
      .uart_tx_busy           (uart1_tx_busy_wire), // <--- FIXED: Now connected to TX!
      .tx_acq_done            (), 
      
      // RX Interface
      .rx_fifo_wr_en          (uart1_RX_data_ready_pulse_out),
      .rx_fifo_data           (uart1_RX_data_raw), 
      
      .rx_corrupt_byte_count  (uart1_rx_corrupt_byte_count),
      .rx_valid_byte_count    (uart1_rx_valid_byte_count),  
      .uart_rx_busy           (uart1_rx_busy_wire) // <--- FIXED: Left empty
  );

  // RX FIFO: New UART writes to it, UVM reads from it.
  dual_port_FIFO #(
      .PARAM_DATA_WIDTH(16), // FIX: Force 16-bit
      .PARAM_FIFO_SIZE("18Kb")
  ) uart1_rx_fifo (
      .rst_n          (rst_n),
      .wr_clk         (clk_44_2386MHz),
      .data_in        (uart1_RX_data_fifo_in),         // 16-bit Padded input
      .wr_en          (uart1_RX_data_ready_pulse_out), 
      .rd_clk         (clk_64MHz),
      .rd_en          (vif_rx.rd_en),                  
      .data_out       (rx_data_out_padded),            // 16-bit output
      .fifo_full      (vif_rx.fifo_full),
      .fifo_empty     (vif_rx.fifo_empty)
  );

  // ==========================================
  // 5. PROCEDURAL BLOCKS
  // ==========================================
  initial begin
    clk_44_2386MHz = 0;
    forever #11.3 clk_44_2386MHz = ~clk_44_2386MHz; 
  end

  initial begin
    clk_64MHz = 0;
    forever #7.8 clk_64MHz = ~clk_64MHz; 
  end

  initial begin
    rst_n         = 0; 
    vif_tx.rst_n  = 0;
    vif_rx.rst_n  = 0;
    vif_cfg.rst_n = 0;
    #2000;  
    rst_n         = 1;
    vif_tx.rst_n  = 1;
    vif_rx.rst_n  = 1;
    vif_cfg.rst_n = 1;
  end

  // --- NEW: Real-Time Hardware Alert ---
  always @(uart1_rx_corrupt_byte_count) begin
      if (uart1_rx_corrupt_byte_count > 0 && rst_n == 1'b1)
          `uvm_warning("HW_ALERT", $sformatf("\033[1;33m RTL flagged a CORRUPT BYTE! Hardware Total: %0d \033[0m", uart1_rx_corrupt_byte_count))
  end

  initial begin
    uvm_config_db#(virtual fifo_intf_uart)::set(null, "*tx_agnt*", "fifo_vif", vif_tx);
    uvm_config_db#(virtual fifo_intf_uart)::set(null, "*rx_agnt*", "fifo_vif", vif_rx);
    
    // CHANGED: Use "*" so the Scoreboard (and everything else) can see the Config Interface!
    uvm_config_db#(virtual uart_config_intf)::set(null, "*", "cfg_vif", vif_cfg);
    
    uvm_config_db#(virtual serial_line_intf)::set(null, "*phys_mon*", "serial_vif", vif_serial);
    uvm_config_db#(virtual error_inject_intf)::set(null, "*", "err_vif", err_vif);
    
    run_test(); 
  end
endmodule