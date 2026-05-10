// ---------------------------------------------------------
// WRITE SEQUENCE (Producer)
// ---------------------------------------------------------
class fifo_wr_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_wr_seq)
  
  rand int num_packets;

  function new(string name = "fifo_wr_seq");
    super.new(name);
  endfunction

  virtual task body();
    fifo_item item;
    repeat(num_packets) begin
      item = fifo_item::type_id::create("item");
      start_item(item);
      if (!item.randomize()) `uvm_error("WR_SEQ", "Randomization failed")
      finish_item(item);
    end
    `uvm_info("WR_SEQ", $sformatf("Finished writing %0d packets.", num_packets), UVM_LOW)
  endtask
endclass

// ---------------------------------------------------------
// READ SEQUENCE (Consumer)
// ---------------------------------------------------------
class fifo_rd_seq extends uvm_sequence #(fifo_item);
  `uvm_object_utils(fifo_rd_seq)
  
  rand int num_packets;

  function new(string name = "fifo_rd_seq");
    super.new(name);
  endfunction

  virtual task body();
    fifo_item item;
    repeat(num_packets) begin
      item = fifo_item::type_id::create("item");
      start_item(item);
      if (!item.randomize()) `uvm_error("RD_SEQ", "Randomization failed")
      finish_item(item);
    end
    `uvm_info("RD_SEQ", $sformatf("Finished reading %0d packets.", num_packets), UVM_LOW)
  endtask
endclass