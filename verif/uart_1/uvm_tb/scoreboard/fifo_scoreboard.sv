`uvm_analysis_imp_decl(_wr)
`uvm_analysis_imp_decl(_rd)

class fifo_scoreboard extends uvm_scoreboard;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp_wr #(fifo_item, fifo_scoreboard) wr_export;
  uvm_analysis_imp_rd #(fifo_item, fifo_scoreboard) rd_export;

  fifo_item expected_queue[$];

  int match_count;
  int mismatch_count;
  int total_reads_processed = 0;

  function new(string name="fifo_scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    wr_export = new("wr_export", this);
    rd_export = new("rd_export", this);
    match_count = 0;
    mismatch_count = 0;
  endfunction

  virtual function void write_wr(fifo_item item);
    total_reads_processed++;
    if (total_reads_processed % 100 == 0) begin
      `uvm_info("SCB_HEARTBEAT", $sformatf("Successfully drained %0d items from the RTL...", total_reads_processed), UVM_LOW)
    end
    if (item.corrupt == 1'b0) begin
      expected_queue.push_back(item);
      `uvm_info("SCB_WR", $sformatf("Stored expected data: 0x%0h", item.data), UVM_HIGH)
    end else begin
      `uvm_info("SCB_WR", "Corrupt packet detected. Expecting RTL to drop it.", UVM_HIGH)
    end
  endfunction

  virtual function void write_rd(fifo_item actual_item);
    fifo_item expected_item;

    if (expected_queue.size() == 0) begin
      `uvm_error("SCB_RD", "FATAL UNDERFLOW! RTL read data, but Scoreboard queue is empty!")
      mismatch_count++;
      return;
    end

    expected_item = expected_queue.pop_front();

    if (actual_item.data === expected_item.data) begin
      match_count++;
      `uvm_info("SCB_MATCH", $sformatf("Data matched! [0x%0h]", actual_item.data), UVM_HIGH)
    end else begin
      mismatch_count++;
      `uvm_error("SCB_MISMATCH", $sformatf("Data mismatch! Expected: 0x%0h | Actual: 0x%0h", expected_item.data, actual_item.data))
    end
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("SCB_SUMMARY", "\n+---------------------------------------+\n| FIFO CDC VERIFICATION SUMMARY         |\n+---------------------------------------+", UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| MATCHES    : %0d", match_count), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| MISMATCHES : %0d", mismatch_count), UVM_NONE)
    `uvm_info("SCB_SUMMARY", $sformatf("| ITEMS LEFT : %0d (Unread in Queue)", expected_queue.size()), UVM_NONE)
    `uvm_info("SCB_SUMMARY", "+---------------------------------------+", UVM_NONE)
  endfunction

endclass