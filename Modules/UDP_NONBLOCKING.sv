// ************************************************************************************************************************
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
// ************************************************************************************************************************
//
// PROJECT      :   40Gbps UDP Parser
// PRODUCT      :   N/A
// FILE         :   UDP_NONBLOCKING.sv
// AUTHOR       :   Sachith Rathnayake
// DESCRIPTION  :   40Gbps UDP packet processor which calculaes the SUM of the payload values or Max of the payloads.
//
// ************************************************************************************************************************
//
// REVISIONS:
//
//  Date           Developer               Description
//  -----------    --------------------    -----------
//  10-FEB-2023    Sachith Rathnayake      Creation
//
//
//*************************************************************************************************************************

`timescale 1ns/1ps

module UDP_NONBLOCKING(
    clk,
    reset,
    In_data,
    In_valid, 
    Out_ready,
    Out_data,
    Out_valid,
    In_ready
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
    
    typedef enum logic { 
        S0,      // First beat indication and skipping (RX)
        S1       // Feeding the calc engins and processing the data beat by beat starting from 2nd beat
    } RX;


    typedef enum logic { 
        A,      // Setting the Output ready 
        B       // Jumpnig back to A if Out_ready received else stay valid till Out_ready(TX)
     } TX;
    
//---------------------------------------------------------------------------------------------------------------------
// I/O signals
//---------------------------------------------------------------------------------------------------------------------
    
    input   logic [255:0] In_data; //remove the magic numbers
    input   logic         In_valid;
    input   logic         Out_ready;
    input   logic         clk;
    input   logic         reset;
    output  logic [255:0] Out_data;
    output  logic         Out_valid;
    output  logic         In_ready;
    
    //---------------------------------------------------------------------------------------------------------------------
    // Internal signals
    //---------------------------------------------------------------------------------------------------------------------
    
    RX state_rx = S0;
    TX state_tx = A;

    logic [255:0] input_buf;
    logic [255:0] input_reg1;
    logic [  6:0] count_beat;
        
    logic [  6:0] count_pd;
        
    logic [ 15:0] op_code;
    logic [ 15:0] op_code2;
    // logic [ 15:0] test_op;
    logic [ 31:0] calc_out_max;
    logic [ 31:0] calc_out_sum;
    logic [ 31:0] calc_out;
    logic         max_CE;
    logic         sum_CE;
    logic         clear_mem;
    logic         out_bit;
    logic         out_bit_latch;
    logic         out_available;
        
    // logic [ 15:0] test;
    
//---------------------------------------------------------------------------------------------------------------------
// Implementation
//---------------------------------------------------------------------------------------------------------------------
    
    sum_cal_block_nonblocking sum (
        .payload(input_reg1),
        .clk(clk),
        .CE(sum_CE),
        .clear_mem(clear_mem),
        .sum_out(calc_out_sum)
    );

    max_cal_block_nonblocking max (
        .payload(input_reg1),
        .clk(clk),
        .CE(max_CE),
        .clear_mem(clear_mem),
        .max_out(calc_out_max)
    );

    always_comb begin : SELECTOR
        unique case ( op_code )
            16'd1  : begin
                sum_CE   = 1'b1;
                max_CE   = ( op_code2 == 16'd2 )? 1'b1 : 1'b0 ;
            end
            16'd2  : begin
                max_CE   = 1'b1;
                sum_CE   = ( op_code2 == 16'd1 )? 1'b1 : 1'b0;
            end
            default: begin
                sum_CE   = ( op_code2 == 16'd1 )? 1'b1 : 1'b0;
                max_CE   = ( op_code2 == 16'd2 )? 1'b1 : 1'b0;
            end
        endcase
    end

    always_ff @( posedge clk ) begin : CALC_OUT
        unique case ( op_code )
            16'd1:  calc_out <= calc_out_sum;
            16'd2:  calc_out <= calc_out_max;
        endcase
    end

    always_ff @( posedge clk ) begin : udp_data_loading_fsm
        if (!reset ) begin
            state_rx           <= S0;
            state_tx        <= A ; //move to the reset of other FSM
            In_ready        <= 1'd1;
            out_available   <= 1'd1;
            Out_valid       <= 1'd0;
            out_bit         <= 1'd0;
            Out_data        <= 256'd0;
            input_reg1      <= 256'd0;
            count_beat      <= 7'd0;
            count_pd        <= 7'd0;
            op_code         <= 16'd0;
            // op_code2        <= 16'd0;
            clear_mem       <= 1'd0;
        end else begin
            unique case ( state_rx )
                S0  :   begin

                    if ( In_valid && In_ready ) begin
                        count_beat <= count_beat + 7'd1;
                        state_rx      <= S1;
                    end
                end
                S1  :   begin
                    if ( In_valid && In_ready ) begin
                        unique case (count_beat)
                            7'd1: begin
                                count_beat                  <= count_beat + 7'd1;
                                if(out_bit) begin
                                    op_code2    [ 15:  0]   <= In_data [176:160];
                                end
                                else begin
                                    op_code     [ 15:  0]   <= In_data [176:160];
                                end
                                input_reg1 [159:  0]        <= In_data [159:  0];
                                input_reg1 [255:160]        <= 96'd0;
                            end
                            7'd62: begin
                                if (out_available) begin
                                    count_beat              <= count_beat + 7'd1;
                                    input_reg1 [127:  0]    <= 128'd0;
                                    input_reg1 [255:128]    <= In_data [255:128];
                                    state_rx                   <= S0;
                                    out_bit                 <= 1'd1;
                                    count_beat              <= 7'd0;
                                    In_ready                <= 1'd1;
                                end else begin
                                    In_ready                <= 1'd0;
                                end
                            end
                            default: begin
                                count_beat                  <= count_beat + 7'd1;
                                input_reg1                  <= In_data;
                            end
                        endcase
                    end
                end
            endcase 
        end
    end

    always_ff @( posedge clk ) begin : udp_data_output_handling_fsm //(Out_data/count_pd/out_bit_latch)
        if (!reset ) begin
            op_code2        <= 16'd0;
            out_bit_latch   <= 1'b0;
        end
        else begin
            if ( out_bit || out_bit_latch ) begin
                out_bit_latch   <= 1'b0;
                unique case (state_tx)
                    A: begin
                        unique case (count_pd)
                            7'd3: begin
                                clear_mem   <= 1'd1;
                                count_pd    <= count_pd + 7'd1;
                            end
                            7'd4: begin
                                if(out_available) begin
                                    Out_data [ 31: 0]   <= calc_out [31:0];
                                    state_tx            <= B;
                                    clear_mem           <= 1'd1;
                                    op_code                     <= op_code2;
                                    op_code2                    <= 16'd0;
                                end
                            end
                            default: begin
                                count_pd    <= count_pd + 7'd1;
                            end
                        endcase
                    end
                    B: begin
                        if(Out_ready) begin
                            Out_valid       <= 1'd0; //set Out_valid to 1 when juping to this stage
                            count_pd        <= 7'd0;
                            out_bit_latch   <= 1'b0;
                            In_ready        <= 1'd1; //set
                            out_available   <= 1'd1;
                            state_tx        <= A;
                        end
                        else begin
                            Out_valid       <= 1'd1; //just to remember
                            count_pd        <= 7'd0;
                            In_ready        <= 1'd0;
                            out_available   <= 1'd0;
                        end
                    end
                endcase
            end
        end
    end

    always_ff @(posedge clk) begin : clear_mem_RESET
        if ( clear_mem ) begin
            clear_mem   <= 1'd0;
            Out_valid   <= 1'd0;
        end
    end

endmodule