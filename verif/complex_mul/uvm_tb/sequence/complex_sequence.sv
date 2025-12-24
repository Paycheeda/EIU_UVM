class complex_seq extends uvm_sequence #(txn);
  `uvm_object_utils(complex_seq)

  txn tr;
  common_config cfg;

  function new(string name="complex_seq");
    super.new(name);
  endfunction

  task body();
    for (int i = 0; i < cfg.num_txn; i++) begin
    tr = txn::type_id::create("tr");
    tr.cfg = cfg; 

    start_item(tr);
    assert(tr.randomize());
    finish_item(tr);

    `uvm_info("SEQ", $sformatf("Generated txn: real_a=%0d, imag_a=%0d", tr.real_a, tr.imag_a), UVM_MEDIUM)
    end
  endtask
endclass