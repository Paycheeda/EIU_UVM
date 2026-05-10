// =====================================================
// Declare Analysis Imp Macros for Input & Output
// =====================================================
`uvm_analysis_imp_decl(_ingr)
`uvm_analysis_imp_decl(_egrs)

class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  // =====================================================
  // Constructor
  // =====================================================
  function new(string name="scoreboard", uvm_component parent=null);
    super.new(name, parent);
  endfunction : new

  // =====================================================
  // Analysis Imps (input + output)
  // =====================================================
  uvm_analysis_imp_ingr #(inp_transaction, scoreboard) ingr_imp_export;
  uvm_analysis_imp_egrs #(out_transaction, scoreboard) egrs_imp_export;

  // Queues & Storage
  out_transaction exp_q[$];   // queue for expected outputs
  out_transaction exp_trx;    // expected transaction
  inp_transaction inp_trx;    // input transaction
  out_transaction out_trx;    // actual transaction

  // Stats
  int match, mismatch, total;

  // =====================================================
  // Build Phase
  // =====================================================
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    ingr_imp_export = new("ingr_imp_export", this);
    egrs_imp_export = new("egrs_imp_export", this);
  endfunction : build_phase

  // =====================================================
  // Input Write 
  // =====================================================
  virtual function void write_ingr(inp_transaction in_trx);

    // Store for later use
    inp_trx = in_trx;

    // Create expected output transaction
    exp_trx = out_transaction::type_id::create("exp_trx");

    // =====================================================
    // DUT functionality
    // =====================================================

    // Multiplication: (a + jb)(c + jd) = (ac - bd) + j(ad + bc)
    exp_trx.y = (in_trx.a * in_trx.c) - (in_trx.b * in_trx.d);
    exp_trx.z = (in_trx.a * in_trx.d) + (in_trx.b * in_trx.c);

    // Addition: (a + jb) + (c + jd) = (a+c) + j(b+d)
    exp_trx.w = in_trx.a + in_trx.c;
    exp_trx.x = in_trx.b + in_trx.d;

    // Push into expected queue
    exp_q.push_back(exp_trx);

    total++;
  endfunction : write_ingr

  // =====================================================
  // Output Write (Checker)
  // =====================================================
  virtual function void write_egrs(out_transaction out_trx);

    if (exp_q.size() == 0) begin
      `uvm_error("SCB", "No expected transaction available")
    end
    else begin
      // Pop the first expected transaction
      exp_trx = exp_q.pop_front();

      // Compare actual vs expected
      if (out_trx.compare(exp_trx))
        match++;
      else begin
        mismatch++;
        display_mismatch(exp_trx, out_trx);
      end
    end
  endfunction : write_egrs

  // =====================================================
  // Report Phase
  // =====================================================
  virtual function void report_phase(uvm_phase phase);
    `uvm_info("SCB", $sformatf("Complex Results: Match=%0d, Mismatch=%0d, Total=%0d",
                                match, mismatch, total), UVM_MEDIUM)
  endfunction : report_phase

  // =====================================================
  // Debug Display for Mismatches
  // =====================================================
  virtual function void display_mismatch(out_transaction exp, out_transaction act);
    string msg;
    msg = $sformatf("\nMISMATCH!\nExpected: y=%0d z=%0d w=%0d x=%0d\n",
                    exp.y, exp.z, exp.w, exp.x);
    msg = {msg, $sformatf("Actual:   y=%0d z=%0d w=%0d x=%0d\n",
                    act.y, act.z, act.w, act.x)};
    msg = {msg, "=================================================\n"};
    `uvm_error("SCB", msg)
  endfunction : display_mismatch

endclass : scoreboard
