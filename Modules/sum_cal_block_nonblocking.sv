
// ***********************************************************************************************************************
//
// Copyright(C) 2022 ACCELR
// All rights reserved.
//
// THIS IS UNPUBLISHED PROPRIETARY SOURCE CODE OF
// ACCELER LOGIC (PVT) LTD, SRI LANKA.
//
// This copy of the Source Code is intended for ACCELR's internal use only and is
// intended for view by persons duly authorized by the management of ACCELR. No
// part of this file may be reproduced or distributed in any form or by any
// means without the written approval of the Management of ACCELR.
//
// ACCELR, Sri Lanka            https://accelr.lk
// No 175/95, John Rodrigo Mw,  info@accelr.net
// Katubedda, Sri Lanka         +94 77 3166850
//
// ***********************************************************************************************************************
//
// PROJECT      :   40Gbps UDP Parser
// PRODUCT      :   NA
// FILE         :   sum_cal_block_nonblocking.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   RTL tree adder block module for calculating the sum of 8 numbers of 4byte integers
//
// ***********************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  10-FEB-2023    Sachith Rathnayake      creation
//
//
//*************************************************************************************************************************

`timescale 1ns/1ps

module sum_cal_block_nonblocking (
    payload,
    clk,
    CE,
    clear_mem,
    sum_out
);

    //---------------------------------------------------------------------------------------------------------------------
    // Global constant headers
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // parameter definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // localparam definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // type definitions
    //---------------------------------------------------------------------------------------------------------------------
    
    
    
    //---------------------------------------------------------------------------------------------------------------------
    // I/O signals
    //---------------------------------------------------------------------------------------------------------------------
    
    input   logic   unsigned    [255:0]    payload;
    input   logic                          clk;
    input   logic                          CE;
    input   logic                          clear_mem;
    output  logic   unsigned    [ 31:0]    sum_out;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    logic   [31:0]  input_reg       [7:0];
    logic   [31:0]  first_layer     [3:0];
    logic   [31:0]  second_layer    [1:0];

    logic   [31:0]  I               [3:0];
    logic   [31:0]  II              [1:0];
    logic   [31:0]  III;
    
    logic   [31:0]  mem;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Implementation
    //---------------------------------------------------------------------------------------------------------------------
    
    generate
        for (genvar i = 0; i <= 3; i++) begin
            sum_cal sum (
                .A(input_reg[i*2]),
                .B(input_reg[i*2+1]),
                .C(I[i])
            );
        end
    endgenerate

    generate
        for (genvar i = 0; i <= 1; i++) begin
            sum_cal sum (
                .A(first_layer[i*2]),
                .B(first_layer[i*2+1]),
                .C(II[i])
            );
        end
    endgenerate

    sum_cal final_adder (
        .A(second_layer[0]),
        .B(second_layer[1]),
        .C(III)
    );

    sum_cal accumulator (
        .A(III),
        .B(mem),
        .C(sum_out)
    );


    always_ff @( posedge clk ) begin    : register_transiton
        if (CE) begin
                input_reg       [0] <=  payload [ 31:  0];
                input_reg       [1] <=  payload [ 63: 32];
                input_reg       [2] <=  payload [ 95: 64];
                input_reg       [3] <=  payload [127: 96];
                input_reg       [4] <=  payload [159:128];
                input_reg       [5] <=  payload [191:160];
                input_reg       [6] <=  payload [223:192];
                input_reg       [7] <=  payload [255:224];
                first_layer         <=  I;
                second_layer        <=  II;
                mem                 <=  sum_out;

                if ( clear_mem ) begin
                    mem <=  0;
                end
        end
        else begin
                input_reg       [0] <=  32'd0;
                input_reg       [1] <=  32'd0;
                input_reg       [2] <=  32'd0;
                input_reg       [3] <=  32'd0;
                input_reg       [4] <=  32'd0;
                input_reg       [5] <=  32'd0;
                input_reg       [6] <=  32'd0;
                input_reg       [7] <=  32'd0;
                first_layer     [0] <=  32'd0;
                first_layer     [1] <=  32'd0;
                first_layer     [2] <=  32'd0;
                first_layer     [3] <=  32'd0;
                second_layer    [0] <=  32'd0;
                second_layer    [1] <=  32'd0;
                mem                 <=  32'd0;
        end  
    end
    
endmodule