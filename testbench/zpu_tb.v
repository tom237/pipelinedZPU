`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/11/2014 12:14:19 PM
// Design Name: 
// Module Name: zpu_tb
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


module zpu_tb(
    );

    reg clk;
    reg inter;
    reg rst;
    reg enable;
    reg wb_slave_cyc;
    reg wb_slave_stb;
    wire wb_stb;
    reg wb_ack;
    reg wb_stall;
    wire[136:0] dbg_o;
    wire[31:0] pc;
    wire[31:0] sp;
    wire[31:0] tos;
    wire[31:0] nos;
    wire[7:0] inst;
    wire dbgok;

    zpu_core uut(
        .clk(clk),
        .rstin(rst),
        .interrupt(inter),
        .enable(enable),
        .wb_stall(wb_stall),
        .wb_ack(wb_ack),
        .wb_stb(wb_stb),
        .wb_slave_cyc(wb_slave_cyc),
        .wb_slave_stb(wb_slave_stb),
        .dbg_o(dbg_o)
        );    

    assign pc = dbg_o[31:0]; //pc
    assign sp = dbg_o[63:32]; //sp
    assign tos = dbg_o[95:64]; //tos
    assign nos = dbg_o[127:96]; //nos
    assign inst = dbg_o[135:128]; //inst
    assign dbgok = dbg_o[136]; // valid data

    initial begin
        clk <= 0;
        rst <= 1;
        enable <= 1;
        wb_slave_cyc <= 0;
        wb_slave_stb <= 0;
        wb_stall <= 0;
        inter <= 0;
        #30 rst <= 0;
        #100 inter <= 1;
        #150 inter <= 0;
    end

    always begin
        #5 clk <= ~clk;
    end

    always @ (posedge clk)begin
        wb_ack <= wb_stb;
    end

endmodule
