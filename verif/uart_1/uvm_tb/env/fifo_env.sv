class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_wr_agent   wr_agnt;
  fifo_rd_agent   rd_agnt;
  fifo_scoreboard scrbrd;

  function new(string name="fifo_env", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    wr_agnt = fifo_wr_agent::type_id::create("wr_agnt", this);
    rd_agnt = fifo_rd_agent::type_id::create("rd_agnt", this);
    
    scrbrd  = fifo_scoreboard::type_id::create("scrbrd", this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    wr_agnt.mntr.mon_ap.connect(scrbrd.wr_export);
    rd_agnt.mntr.mon_ap.connect(scrbrd.rd_export);
  endfunction
endclass