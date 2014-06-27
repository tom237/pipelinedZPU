`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/16/2014 08:38:00 AM
// Design Name: 
// Module Name: wb_slave_mux
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


module wb_mux(
    input wire[31:0] ram_in,
    output wire[31:0] ram_out,
    output wire[31:0] ram_adr,
    output wire[3:0] ram_msk,
    output wire ram_enable,
    input wire ram_busy,

    input wire[31:0] wb_in_itc,
    output wire[31:0] wb_out_itc,
    output wire[31:0] wb_adr_itc,
    output wire[3:0] wb_sel_itc,
    output wire wb_cyc_itc,
    output wire wb_stb_itc,
    input wire wb_ack_itc,
    input wire wb_stall_itc,
    output wire wb_we_itc,
    
    input wire [31:0] wb_in_s0,
    output wire [31:0] wb_out_s0,
    output wire [31:0] wb_adr_s0,
    output wire [3:0] wb_sel_s0,
    output wire wb_cyc_s0,
    output wire wb_stb_s0,
    input wire wb_ack_s0,
    input wire wb_stall_s0,
    output wire wb_we_s0,

    input wire[31:0] wb_in_cpu,
    output wire[31:0] wb_out_cpu,
    input wire[31:0] wb_adr_cpu,
    input wire[3:0] wb_sel_cpu,
    input wire wb_cyc_cpu,
    input wire wb_stb_cpu,
    output wire wb_ack_cpu,
    output wire wb_stall_cpu,
    input wire wb_we_cpu,

    input wire clk,
    input wire rst
    );
    parameter interupt_ctrl_adr = 24'h080A00;
    parameter interupt_ctrl_adr_size = 8;
    parameter pc_bit_size = 15;

    reg[1:0] outstate;
    wire[1:0] outport;
    
    assign outport = (wb_adr_cpu[31:pc_bit_size] == 0) ? 2'h0 : //te mux controler for wb slave
                      (wb_adr_cpu[31:interupt_ctrl_adr_size] == interupt_ctrl_adr) ? 2'h1 :
                      2'h2;    

    wire[31:0] wb_in[2:0];
    wire wb_ack[2:0];
    wire wb_stall[2:0];

    wire [3:0] wb_sel_ram;
// signals for slave mux
    assign wb_in[0] = ram_in;
    assign wb_in[1] = wb_in_itc;
    assign wb_in[2] = wb_in_s0;

    assign wb_ack[0] = ram_ack;
    assign wb_ack[1] = wb_ack_itc;
    assign wb_ack[2] = wb_ack_s0;

    assign wb_stall[0] = ram_busy;
    assign wb_stall[1] = wb_stall_itc;
    assign wb_stall[2] = wb_stall_s0;

    assign ram_out = wb_in_cpu;
    assign wb_out_itc = wb_in_cpu;
    assign wb_out_s0 = wb_in_cpu;
    
    assign wb_sel_ram = wb_adr_cpu;
    assign wb_adr_itc = wb_adr_cpu;
    assign wb_adr_s0 = wb_adr_cpu;

    assign ram_sel = wb_sel_cpu;
    assign wb_sel_itc = wb_sel_cpu;
    assign wb_sel_s0 = wb_sel_cpu;

    assign ram_wren = wb_we_cpu;
    assign wb_we_itc = wb_we_cpu;
    assign wb_we_s0 = wb_we_cpu;
        
    assign wb_out_cpu = wb_in[outstate];    
    assign wb_ack_cpu = wb_ack[outstate];
    assign wb_stall_cpu = wb_stall[outport];
    
    assign ram_cyc = (outport == 0) ? wb_cyc_cpu : 1'b0;
    assign wb_cyc_itc = (outport == 1) ? wb_cyc_cpu : 1'b0;
    assign wb_cyc_s0 = (outport == 2) ? wb_cyc_cpu : 1'b0;

    assign ram_en = (outport == 0) ? wb_stb_cpu : 1'b0;
    assign wb_stb_itc = (outport == 1) ? wb_stb_cpu : 1'b0;
    assign wb_stb_s0 = (outport == 2) ? wb_stb_cpu : 1'b0;

// control signals for slave
    always @ (posedge clk)begin
        if(rst == 1)begin
            outstate <= 0;
        end
        else begin
            outstate <= outport;
        end
    end

// ram wb signals

    reg ram_int_ack;

    assign ram_msk = ((ram_wren == 1) && (ram_cyc == 1)) ? wb_sel_ram : 4'h0;
    assign ram_enable = (ram_cyc == 1) ? ram_en : 1'b0;
    assign ram_ack = ((ram_cyc == 1) && (ram_busy == 0)) ? ram_int_ack : 1'b0;

    always @ (posedge clk)begin
        if(rst == 1)begin
            ram_int_ack <= 0;
//            ram_sel_msk <= 0;
        end
        else begin
            if(ram_busy == 0)begin
                ram_int_ack <= ram_en;
            end
//            ram_sel_msk <= wbm_sel[mastersel];
        end
    end
    
endmodule
