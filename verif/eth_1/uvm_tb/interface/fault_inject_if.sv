`ifndef FAULT_INJECT_IF_SV
`define FAULT_INJECT_IF_SV

interface fault_inject_if(input logic clk);
  eth_pkg::fault_t fault_type;
endinterface

`endif