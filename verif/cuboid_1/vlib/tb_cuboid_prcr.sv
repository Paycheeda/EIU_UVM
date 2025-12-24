module tb_cuboid_prcr;
  import uvm_pkg::*;
  import cuboid_pkg::*;

// ====================================
// testbench signals
// ====================================
bit clk;

// ====================================
// Interface instant
// ====================================

cuboid_inp_intf cuboid_inp_if (.clk(clk));
cuboid_out_intf cuboid_out_if (.clk(clk));


// ====================================
// Design instant
// ====================================
  cuboid_prcr cuboid_prcr_inst(
  .clk         (clk),
  .in_valid    (cuboid_inp_if.valid  ),
  .length      (cuboid_inp_if.length ),
  .width       (cuboid_inp_if.width  ),
  .height      (cuboid_inp_if.height ),
  .area        (cuboid_out_if.area   ),
  .volm        (cuboid_out_if.volm   ),
  .out_valid   (cuboid_out_if.valid  )
  );

// ====================================
// Initial Block
// ====================================
initial 
begin
  uvm_config_db #(virtual cuboid_inp_intf)::set(null, "uvm_test_top.env.ingr_agnt.drvr" , "cuboid_in_intf", cuboid_inp_if);
  uvm_config_db #(virtual cuboid_inp_intf)::set(null, "uvm_test_top.env.ingr_agnt.mntr", "cuboid_in_intf", cuboid_inp_if);
  uvm_config_db #(virtual cuboid_out_intf)::set(null, "uvm_test_top.env.egrs_agnt.mntr", "cuboid_o_intf" , cuboid_out_if);
  uvm_config_db #(virtual cuboid_inp_intf)::set(null, "uvm_test_top"                   , "cuboid_in_intf", cuboid_inp_if);
  run_test ();
end

// ====================================
// Interface instant
// ====================================
always 
  #5 clk = ~clk ;

endmodule : tb_cuboid_prcr         