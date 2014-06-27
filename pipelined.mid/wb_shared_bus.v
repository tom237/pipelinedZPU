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


module wb_shared_bus(
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

    input wire[31:0] wb_in_dma,
    output wire[31:0] wb_out_dma,
    input wire[31:0] wb_adr_dma,
    input wire[3:0] wb_sel_dma,
    input wire wb_cyc_dma,
    input wire wb_stb_dma,
    output wire wb_ack_dma,
    output wire wb_stall_dma,
    input wire wb_we_dma,

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

    wire [31:0] wb_in_ram;
    wire [31:0] wb_out_ram;
    wire [31:0] wb_adr_ram;
    wire [3:0] wb_sel_ram;
    wire wb_cyc_ram;
    wire wb_stb_ram;
    wire wb_ack_ram;
    wire wb_stall_ram;
    wire wb_we_ram;
// signals for slave mux
    assign wb_in[0] = wb_in_ram;
    assign wb_in[1] = wb_in_itc;
    assign wb_in[2] = wb_in_s0;

    assign wb_ack[0] = wb_ack_ram;
    assign wb_ack[1] = wb_ack_itc;
    assign wb_ack[2] = wb_ack_s0;

    assign wb_stall[0] = wb_stall_ram;
    assign wb_stall[1] = wb_stall_itc;
    assign wb_stall[2] = wb_stall_s0;

    assign wb_out_ram = wb_in_cpu;
    assign wb_out_itc = wb_in_cpu;
    assign wb_out_s0 = wb_in_cpu;
    
    assign wb_adr_ram = wb_adr_cpu;
    assign wb_adr_itc = wb_adr_cpu;
    assign wb_adr_s0 = wb_adr_cpu;

    assign wb_sel_ram = wb_sel_cpu;
    assign wb_sel_itc = wb_sel_cpu;
    assign wb_sel_s0 = wb_sel_cpu;

    assign wb_we_ram = wb_we_cpu;
    assign wb_we_itc = wb_we_cpu;
    assign wb_we_s0 = wb_we_cpu;
        
    assign wb_out_cpu = wb_in[outstate];    
    assign wb_ack_cpu = wb_ack[outstate];
    assign wb_stall_cpu = wb_stall[outport];
    
    assign wb_cyc_ram = (outport == 0) ? wb_cyc_cpu : 1'b0;
    assign wb_cyc_itc = (outport == 1) ? wb_cyc_cpu : 1'b0;
    assign wb_cyc_s0 = (outport == 2) ? wb_cyc_cpu : 1'b0;

    assign wb_stb_ram = (outport == 0) ? wb_stb_cpu : 1'b0;
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

// signals for master mux
    wire[31:0] wbm_out[1:0];
    wire[31:0] wbm_adr[1:0];
    wire[3:0] wbm_sel[1:0];
    wire wbm_stb[1:0];
    wire wbm_cyc[1:0];
    wire wbm_wren[1:0];
    wire mastersel;
    reg lastmaster;
    wire ram_cyc;
    wire ram_ack;
    reg ram_int_ack;
    wire ram_en;
    wire ram_wren;

    // the master mux controlers

    assign mastersel = ((wb_cyc_ram == 1) && (wb_cyc_dma == 0)) ? 1'b0 :
                       ((wb_cyc_ram == 0) && (wb_cyc_dma == 1)) ? 1'b1 :
                       lastmaster;

    assign wb_stall_ram = ((wb_cyc_ram == 0) && (wb_cyc_dma == 0)) ? 1'b0 : ((mastersel == 0) && (ram_busy == 0)) ? 1'b0 : 1'b1;
    assign wb_stall_dma = ((wb_cyc_ram == 0) && (wb_cyc_dma == 0)) ? 1'b0 : ((mastersel == 1) && (ram_busy == 0)) ? 1'b0 : 1'b1;

    assign wb_in_ram = ram_in;
    assign wb_out_dma = ram_in;

//    reg[3:0] ram_sel_msk;
//    assign wb_in_ram[7:0] = (ram_sel_msk[0] == 1) ? ram_in[7:0] : 8'h00;
//    assign wb_out_dma[7:0] = (ram_sel_msk[0] == 1) ? ram_in[7:0] : 8'h00;
//    assign wb_in_ram[15:8] = (ram_sel_msk[1] == 1) ? ram_in[15:8] : 8'h00;
//    assign wb_out_dma[15:8] = (ram_sel_msk[1] == 1) ? ram_in[15:8] : 8'h00;
//    assign wb_in_ram[23:16] = (ram_sel_msk[2] == 1) ? ram_in[23:16] : 8'h00;
//    assign wb_out_dma[23:16] = (ram_sel_msk[2] == 1) ? ram_in[23:16] : 8'h00;
//    assign wb_in_ram[31:24] = (ram_sel_msk[3] == 1) ? ram_in[31:24] : 8'h00;
//    assign wb_out_dma[31:24] = (ram_sel_msk[3] == 1) ? ram_in[31:24] : 8'h00;   
   
    assign wbm_out[0] = wb_out_ram;
    assign wbm_out[1] = wb_in_dma;

    assign wbm_adr[0] = wb_adr_ram;
    assign wbm_adr[1] = wb_adr_dma;    
    
    assign wbm_sel[0] = wb_sel_ram;
    assign wbm_sel[1] = wb_sel_dma;    

    assign wbm_stb[0] = wb_stb_ram;
    assign wbm_stb[1] = wb_stb_dma;

    assign wbm_cyc[0] = wb_cyc_ram;
    assign wbm_cyc[1] = wb_cyc_dma;

    assign wbm_wren[0] = wb_we_ram;
    assign wbm_wren[1] = wb_we_dma;

    assign ram_wren = wbm_wren[mastersel];
    assign ram_out = wbm_out[mastersel];
    assign ram_adr = wbm_adr[mastersel];
    assign ram_msk = ((ram_wren == 1) && (ram_cyc == 1)) ? wbm_sel[mastersel] : 4'h0;
    assign ram_en = wbm_stb[mastersel];
    assign ram_cyc = wbm_cyc[mastersel];

    assign wb_ack_ram = (mastersel == 0) ? ram_ack : 1'b0;
    assign wb_ack_dma = (mastersel == 1) ? ram_ack : 1'b0;

    assign ram_ack = ((ram_cyc == 1) && (ram_busy == 0)) ? ram_int_ack : 1'b0;
    assign ram_enable = (ram_cyc == 1) ? ram_en : 1'b0;

// control signal for master
    always @ (posedge clk) begin
        if(rst == 1)begin
            lastmaster <= 0;
        end
        else begin
            if((wb_cyc_ram == 1) && (wb_cyc_dma == 0)) begin
                lastmaster <= 0;
            end
            else if((wb_cyc_ram == 0) && (wb_cyc_dma == 1)) begin
                lastmaster <= 1;
            end
            else if((wb_cyc_ram == 0) && (wb_cyc_dma == 0)) begin
                lastmaster <= 0;
            end
            else begin
                lastmaster <= lastmaster;
            end
        end
    end

// ram wb signals

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
