////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_config.sv
//  Author        : Ahmed Ali
//  Creation Date : 16/04/2026
//
//  Copyright 2026 Avant Labs PVT LTD. All Rights Reserved.
//
//  No portions of this material may be reproduced in any form without
//  the written permission of:
//
//    First Floor, Jumaira Arcade,
//    Fateh Jang Road,
//    Sector F-17, Islamabad, 45230
//
//  All information contained in this document is Avant Labs PVT LTD
//  company private, proprietary and trade secret.
//
//  Description
//  ===========
//  UVM configuration object for UART cuboid verification
////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_config.sv
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

class cuboid_config extends uvm_component;

  uvm_cmdline_processor clp = uvm_cmdline_processor::get_inst();

  function new(string name = "cuboid_config", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  // TODO add Configurations
   int       config_1                   ;
   int       config_2                   ;
  
  // constraint config_1_c  {config_1 == 100;}
  // constraint config_2_c  {config_2 ==   0;}

  `uvm_component_utils_begin(cuboid_config)
  `uvm_field_int(config_1  ,  UVM_DEC)
  `uvm_field_int(config_2  ,  UVM_DEC)
  `uvm_component_utils_end  

  int       weight_min                     ;
  int       weight_max                     ;
  int       height_min                     ;
  int       height_max                     ;
  int       length_min                     ;
  int       length_max                     ;

  function void build_phase (uvm_phase phase);
    // function void post_randomize();
      string arg_value;
    //   super.post_randomize();
      if(clp.get_arg_value("+weight_min=" , arg_value)) weight_min = arg_value.atoi();
      if(clp.get_arg_value("+weight_max=" , arg_value)) weight_max = arg_value.atoi();
      if(clp.get_arg_value("+height_min=" , arg_value)) height_min = arg_value.atoi();
      if(clp.get_arg_value("+height_max=" , arg_value)) height_max = arg_value.atoi();
      if(clp.get_arg_value("+length_min=" , arg_value)) length_min = arg_value.atoi();
      if(clp.get_arg_value("+length_max=" , arg_value)) length_max = arg_value.atoi();

  endfunction 

  function void post_randomize();
    string arg_value;
    super.post_randomize();
    if(clp.get_arg_value("+config_1=" , arg_value)) config_1 = arg_value.atoi();
    if(clp.get_arg_value("+config_2=" , arg_value)) config_2 = arg_value.atoi(); 

  endfunction // post_randomize

endclass// cuboid_config