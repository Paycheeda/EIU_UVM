class txn extends uvm_sequence_item;
  randc bit [15:0] real_a;
  randc bit [15:0] real_b;
  
  randc bit [15:0] imag_a;
  randc bit [15:0] imag_b;

  bit      [31:0] add_real;
  bit      [31:0] add_imag;

  bit      [31:0] mul_real;
  bit      [31:0] mul_imag;

  common_config   cfg;

  constraint comp_num { real_a inside {cfg.minr_a:cfg.maxr_a};
                        real_b inside {cfg.minr_a:cfg.maxr_a};

                        imag_a inside {cfg.mini_a:cfg.maxi_a};
                        imag_b inside {cfg.mini_a:cfg.maxi_a};   
  }
  
  
  `uvm_object_utils_begin(txn)
    `uvm_field_int(real_a, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(real_b, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(imag_a, UVM_ALL_ON|UVM_NOCOMPARE)
    `uvm_field_int(imag_b, UVM_ALL_ON|UVM_NOCOMPARE)
  `uvm_object_utils_end

  function new(string name="txn");
    super.new(name);
  endfunction 

endclass 
