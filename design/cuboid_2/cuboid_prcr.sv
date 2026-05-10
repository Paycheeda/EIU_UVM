////////////////////////////////////////////////////////////////////////////////
//
//  Filename      : cuboid_prcr.sv
//  Author        : MR
//  Creation Date : 01/16/2020
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
//  DUT module to calculate surface area and volume and perimeter using 
//  length, width, height. It has serial input and serial output
////////////////////////////////////////////////////////////////////////////////

module cuboid_prcr (
  input               clk,

  // input interface
  input [16-1:0] in_data,
  input          in_valid,
  input          in_start,
  //           _ 
  //   _______| |_________            in_start
  //           __ __ __
  //  ________|  |  |  |_________     in_valid
  //           L  W  H                in_ata

  // output interface
  output reg [32-1:0]  out_data ,
  output reg           out_start,
  output               out_valid
  //           _ 
  //   _______| |_________            out_start
  //           __ __ __
  //  ________|  |  |  |_________     out_valid
  //           A  V  P                out_data
  //

  );
  
  reg      [16-1:0] length;
  reg      [16-1:0] width;
  reg      [16-1:0] height;
  reg      [32-1:0] perimeter;
  reg      [32-1:0] volm;
  reg      [ 2-1:0] in_start_d;
  reg      [ 2-1:0] out_start_d;
  
  // First input is length
  always @(posedge clk) 
    if (in_valid && in_start)
      length <= in_data;

  // Second input is width
  always @(posedge clk) 
    if (in_valid && in_start_d[0] && !in_start)
      width <= in_data;

  // Third input is Height
  // Will remain unused in this module
 // always @(posedge clk) 
   // if (in_valid && in_start_d[1] && !in_start)
     // height <= in_data;

  // in_start_d is the delayed version  of  in_Start
  // This is used to latch values of width and height
  // and calculate outputs. 
  always @(posedge clk) 
    if (in_valid && in_start)   // on every in_start clearing all the bits in delay register
      in_start_d <= {1'b0, 1'b1} ;
    else if (in_valid && !in_start) // delaying/shifting in_start on every valid
      in_start_d <= {in_start_d[0], 1'b0} ;


  // calculating all the outputs
  // here height = in_data
  always @(posedge clk) 
  if (in_valid && in_start_d[1] && !in_start )
    begin
      out_data  <= 2 * (length*width + width*in_data + in_data*length); // calculating area
      volm      <= length * width * in_data ;
      perimeter <= 4 * (length + width + in_data);
    end
  else if (out_start) //Negated condition
    out_data   <= volm ;
  else if (out_start_d[0]) //Condition removed
    out_data   <= perimeter;
  else
    out_data   <= 'd0;  //

  // out_start logic
  always @(posedge clk) 
  if (in_valid && in_start_d[1] && !in_start )
    out_start <= 1'b1 ;
  else
    out_start <= 1'b0 ;

  // out_start_d is the delayed version of out_start
  always @(posedge clk)
    out_start_d <= {out_start_d[0],out_start};


  assign out_valid = (|out_start_d) || out_start ;


endmodule 
