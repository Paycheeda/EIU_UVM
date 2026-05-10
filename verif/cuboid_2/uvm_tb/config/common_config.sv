////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : common_config.sv
//  Author        : MR
//  Creation Date : 11/01/2021
//
//  Copyright 2020 Sahil Semiconductor. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    Sahil Semiconductor
//    1601 McCarthy Blvd
//    Milpitas CA – 95035
//
//  All information contained in this document is Sahil Semiconductor
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  Common Configuration Class
////////////////////////////////////////////////////////////////////////////////

class common_config extends uvm_component;

  uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

  function new(string name = "common_config", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  int       inp_num_cboids                 ;
  int       watchdog_timer                 ;

function void build_phase (uvm_phase phase);
  // function void post_randomize();
    string arg_value;
  //   super.post_randomize();
    if(clp.get_arg_value("+inp_num_cboids=" , arg_value)) inp_num_cboids = arg_value.atoi();
    if(clp.get_arg_value("+watchdog_timer=" , arg_value)) watchdog_timer = arg_value.atoi()*1000000; 

endfunction 

  // constraint inp_num_cboids_c  {inp_num_cboids == 100;}
  // constraint watchdog_timer_c  {watchdog_timer ==   20000;}


  `uvm_component_utils_begin(common_config)
  `uvm_field_int(inp_num_cboids  ,  UVM_DEC)
  `uvm_field_int(watchdog_timer  ,  UVM_DEC)
  `uvm_component_utils_end  

endclass// common_config


  // function void post_randomize();
  //   string arg_value;
  //   super.post_randomize();
  //   if(clp.get_arg_value("+inp_num_cboids=" , arg_value)) inp_num_cboids = arg_value.atoi();
  //   if(clp.get_arg_value("+watchdog_timer=" , arg_value)) watchdog_timer = arg_value.atoi()*1000000; 

  // endfunction // post_randomize