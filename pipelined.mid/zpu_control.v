`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/18/2014 07:38:30 AM
// Design Name: 
// Module Name: zpu_control
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


module zpu_control(
    input wire clk,
    input wire rst,
    output wire tx_serial,
    input wire rx_serial,
    input wire inter,
    output wire[7:0] led,
    input wire[7:0] sw
//    inout wire[31:0] gpio
    );

    wire enable;
    wire[31:0] interrupt;
    
    // wb master
    wire[31:0] wb_in;
    wire[31:0] wb_out;
    wire[3:0] wb_sel;
    wire wb_stb;
    wire wb_cyc;
    wire wb_ack;
    wire wb_stall;
    wire wb_we;
    wire[31:0] wb_adr;

    //wb slave
    wire[31:0] wb_slave_out;
    wire[31:0] wb_slave_in;
    wire[31:0] wb_slave_adr;
    wire[3:0] wb_slave_sel;
    wire wb_slave_cyc;
    wire wb_slave_stb;
    wire wb_slave_ack;
    wire wb_slave_stall;
    wire wb_slave_wren;

    wire[31:0] gpioin;
    wire[31:0] gpioout;
    wire[31:0] gpiodir;

    assign led = gpioout[7:0];
    assign gpioin[15:8] = sw;    

    reg ackreg;
    assign enable = 1;
    assign interrupt[28:1] = 0;
    assign interrupt[0] = 0;//inter;
    assign wb_slave_cyc = 0;
    assign wb_slave_stb = 0;
    assign wb_stall = 0;
    assign wb_ack = ackreg;
    always @ (posedge clk)begin
        ackreg <= wb_stb;
    end
    
    zpu_core zpu_mag(
        //basic signals
        .clk(clk),
        .rstin(rst),
        .enable(enable),
        .interrupt(interrupt),
        
        // wb master
        .wb_in(wb_in),
        .wb_out(wb_out),
        .wb_sel(wb_sel),
        .wb_stb(wb_stb),
        .wb_cyc(wb_cyc),
        .wb_ack(wb_ack),
        .wb_stall(wb_stall),
        .wb_we(wb_we),
        .wb_adr(wb_adr),
    
        //wb slave
        .wb_slave_out(wb_slave_out),
        .wb_slave_in(wb_slave_in),
        .wb_slave_adr(wb_slave_adr),
        .wb_slave_sel(wb_slave_sel),
        .wb_slave_cyc(wb_slave_cyc),
        .wb_slave_stb(wb_slave_stb),
        .wb_slave_ack(wb_slave_ack),
        .wb_slave_stall(wb_slave_stall),
        .wb_slave_wren(wb_slave_wren),
        
        //debug serial
        .tx_serial(tx_serial),
        .rx_serial(rx_serial),
//        .gpio(gpio)
        .gpioin(gpioin),
        .gpioout(gpioout),
        .gpiodir(gpiodir)
        );


endmodule
