`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/25/2014 02:40:12 PM
// Design Name: 
// Module Name: debug_serial
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module debug_serial(
    input wire clk,
    input wire rst,
    input wire start_trasmit,
    output reg ready_recive,
    output reg reciveint,
    output reg transmitint,
    input wire[7:0] tx_data,
    output reg[7:0] rx_data,
    output reg tx_serial,
    input wire rx_serial,
    input wire[boudgen_size-1:0] boudgen
    );
    parameter boudgen_size = 16;
    
    reg[boudgen_size:0] rx_boud_gen;
    reg[boudgen_size:0] tx_boud_gen;
    reg[2:0] rx_state;
    reg[1:0] tx_state;
    reg[7:0] rx_internal_data;
    reg[7:0] tx_internal_data;
    reg[3:0] rx_bit_remain;
    reg[3:0] tx_bit_remain;
    reg rxfifo0;
    reg rxfifo1;
    reg rxfifo2;
    reg txfifo0;
    reg txfifo1;

    reg debug;

`define rx_idle 0
`define rx_start 1 
`define rx_read 2
`define rx_stop 3
`define rx_wait 4
`define rx_error 5

`define tx_idle 0
`define tx_sending 1
`define tx_stoping 2

    always @ (posedge clk)begin
        if(rst == 1)begin
            ready_recive <= 0;
            reciveint <= 0;
            transmitint <= 0;
            rx_data <= 0;
            tx_serial <= 0;
            rx_boud_gen <= boudgen;
            tx_boud_gen <= boudgen;
            rx_state <= `rx_idle;
            tx_state <= `tx_idle;
            rx_internal_data <= 0;
            tx_internal_data <= 0;
            rx_bit_remain <= 8;
            tx_bit_remain <= 8;
            rxfifo0 <= 1;
            rxfifo1 <= 1;
            rxfifo2 <= 1;
            txfifo0 <= 1;
            txfifo1 <= 1;            
        end
        else begin
            //boudgens            
            if(rx_boud_gen == 0)begin
                rx_boud_gen <= boudgen;
            end       
            else begin
                rx_boud_gen <= rx_boud_gen - 16'h0001;
            end     
            if(tx_boud_gen == 0)begin
                tx_boud_gen <= boudgen;
            end
            else begin
                tx_boud_gen <= tx_boud_gen - 16'h0001;
            end
            //boudgens end
            
            //rx state machine
            case(rx_state)
                `rx_idle : begin
                    if(rxfifo2 == 0)begin
                        rx_boud_gen <= {1'b00,boudgen[boudgen_size-1:1]};
                        rx_state <= `rx_start;                        
                        ready_recive <= 0;
                    end
                end
                `rx_start : begin
                    if(rx_boud_gen == 0)begin
                        if(rxfifo2 == 0)begin
                            rx_bit_remain <= 7;
                            rx_state <= `rx_read;
                            rx_internal_data <= 0;
                        end
                        else begin
                            rx_state <= `rx_error;
                        end
                    end
                end
                `rx_read : begin
                    if(rx_boud_gen == 0)begin
                        rx_internal_data <= {rxfifo2, rx_internal_data[7:1]};
                        rx_bit_remain <= rx_bit_remain - 4'h1;
                        if(rx_bit_remain == 0)begin
                            rx_state <= `rx_stop;
                        end
                    end
                end
                `rx_stop : begin
                    if(rx_boud_gen == 0)begin
                        if(rxfifo2 == 1)begin
                            rx_state <= `rx_idle;
                            ready_recive <= 1;
                            rx_data <= rx_internal_data;
                            reciveint <= 1;
                        end
                        else begin
                            rx_state <= `rx_error;
                        end        
                    end
                end
                `rx_wait : begin
                    if(rx_boud_gen == 0)begin
                        rx_state <= `rx_idle;        
                    end
                end
                `rx_error : begin // if error wait 2 bit
                    rx_boud_gen <= {boudgen[boudgen_size-1:0],1'b0};
                    rx_state <= `rx_wait;
                end
            endcase   
            //rx state machine end

            //tx fifo
            case(tx_state)
                `tx_idle : begin
                    transmitint <= 1;
                    if(start_trasmit == 1)begin
                        tx_internal_data <= tx_data;//tx_data;
                        tx_boud_gen <= boudgen;
                        txfifo0 <= 0;
                        transmitint <= 0;
                        tx_bit_remain <= 8;
                        tx_state <= `tx_sending;
                    end
                end
                `tx_sending : begin
                    transmitint <= 0;
                    if(tx_boud_gen == 0)begin
                        if(tx_bit_remain == 0)begin
                            txfifo0 <= 1;
                            tx_boud_gen <= boudgen; // {boudgen[boudgen_size-2:0],1'b0}
                            tx_state <= `tx_stoping; 
                        end
                        else begin
                            tx_bit_remain <= tx_bit_remain - 4'h1;
                            txfifo0 <= tx_internal_data[0];
                            tx_internal_data <= {1'b0, tx_internal_data[7:1]};                 
                        end
                    end
                end
                `tx_stoping : begin
                    transmitint <= 0;
                    if(tx_boud_gen == 0) begin
                        tx_state <= `tx_idle;
                    end
                end
            endcase
            //tx fifo end

            // fifos for async network
            rxfifo2 <= rxfifo1;
            rxfifo1 <= rxfifo0;
            rxfifo0 <= rx_serial;
            tx_serial <= txfifo1;
            txfifo1 <= txfifo0;
        end
    end
    
endmodule
