`ifndef FAULT_INJECT_IF_SV
`define FAULT_INJECT_IF_SV

interface fault_inject_if(input logic clk);
  import eth_pkg::*; // MUST IMPORT THE PACKAGE HERE!
  fault_t fault_type; 
endinterface

`endif