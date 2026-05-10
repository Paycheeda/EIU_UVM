`ifndef ETH_RX_ENV_SV
`define ETH_RX_ENV_SV

class eth_rx_env extends uvm_env;
  `uvm_component_utils(eth_rx_env)

  phy_rx_agent      phy_agnt;
  fifo_out_agent    fifo_agnt;
  eth_rx_scoreboard scb;

  function new(string name = "eth_rx_env", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    phy_agnt  = phy_rx_agent::type_id::create("phy_agnt", this);
    fifo_agnt = fifo_out_agent::type_id::create("fifo_agnt", this);
    scb       = eth_rx_scoreboard::type_id::create("scb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Wire the Monitors to the Scoreboard!
    phy_agnt.mon.mon_ap.connect(scb.phy_export);
    fifo_agnt.mon.mon_ap.connect(scb.fifo_export);
  endfunction
endclass

`endif