////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_prcr.sv
//  Author        : MR
//  Creation Date : 08/01/2020
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
//  DUT module to calculate surface area and volume using length, width, height.
////////////////////////////////////////////////////////////////////////////////

module cuboid_prcr (
  input               clk,
  input               rst,
  // input interface
  input      [16-1:0] length,
  input      [16-1:0] width,
  input      [16-1:0] height,
  input               in_valid,
  // output interface
  output reg          out_valid,
  output reg [32-1:0] area,
  output reg [32-1:0] volm

  );

  
  always @(posedge clk) 
  begin
    volm      <= length * width * height ;
    area      <= 2 * (length*width + width*height + height*length);
    out_valid <= in_valid ;
  end


endmodule 