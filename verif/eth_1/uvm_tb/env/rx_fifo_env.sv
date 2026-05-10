`ifndef RX_FIFO_ENV_SV
`define RX_FIFO_ENV_SV

class rx_fifo_env extends uvm_env;
  `uvm_component_utils(rx_fifo_env)

  rx_fifo_in_agent   in_agnt;
  rx_fifo_out_agent  out_agnt;
  rx_fifo_scoreboard scb;

  function new(string name="rx_fifo_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    in_agnt  = rx_fifo_in_agent::type_id::create("in_agnt", this);
    out_agnt = rx_fifo_out_agent::type_id::create("out_agnt", this);
    scb      = rx_fifo_scoreboard::type_id::create("scb", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    // Connect Input Agent Monitor to Scoreboard IN FIFO
    in_agnt.mon.mon_ap.connect(scb.in_fifo.analysis_export);
    // Connect Output Agent Monitor to Scoreboard OUT FIFO
    out_agnt.mon.mon_ap.connect(scb.out_fifo.analysis_export);
  endfunction

endclass

`endif