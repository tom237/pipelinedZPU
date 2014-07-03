`timescale 1ns / 1ps
`include "zpupkg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kurucz Tamas
// 
// Create Date: 04/09/2014 04:43:50 PM
// Design Name: 
// Module Name: zpu_top
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


module zpu_core(
    //basic signals
    input wire clk,
    input wire rstin,
    input wire enable,
    input wire[interrupt_number-1:0] interrupt,
    
    // wb master
    input wire[31:0] wb_in,
    output wire[31:0] wb_out,
    output wire[3:0] wb_sel,
    output wire wb_stb,
    output wire wb_cyc,
    input wire wb_ack,
    input wire wb_stall,
    output wire wb_we,
    output wire[31:0] wb_adr,

    //wb slave
    output wire wb_slave_clk,
    output wire wb_slave_rst,
    output wire[31:0] wb_slave_out,
    input wire[31:0] wb_slave_in,
    input wire[31:0] wb_slave_adr,
    input wire[3:0] wb_slave_sel,
    input wire wb_slave_cyc,
    input wire wb_slave_stb,
    output wire wb_slave_ack,
    output wire wb_slave_stall,
    input wire wb_slave_wren,

    //perif
    output wire tx_serial,
    input wire rx_serial,
    input wire[31:0] gpioin,
    output wire[31:0] gpioout,
    output wire[31:0] gpiodir,
    //debug output
    output wire[136:0] dbg_o
    );
    parameter data_mem_start_bits = 26; // have to greater then pc_bit_size
    parameter data_mem_size_in_bits = 11;// sp size smaller them data_mem_start_bits have to greater then 7
    parameter pc_bit_size = 25; //pc size have to less then data_mem_start_bits so the max value is 29 if 
                                 //data_mem_start_bits is 30 and in interupt_ctrl_adr MSB is 1
    parameter interupt_ctrl_adr = 24'h080A00; // on wisbone bus basic periferias adress most significant 24 bit
    parameter interupt_ctrl_adr_size = 8; // the basic perpherias require interupt_ctrl_adr_size**2 adres size from wisbone bus
    parameter interrupt_number = 29; // the number of interrupt sources if enable_POPINT = 1 max 29
    parameter disable_pipelined_wb = 0; // if 1 use standard wb bus if 0 use pipelined wb bus as master
    parameter clk_hz = 100000000; // clock frequency for uart init
    parameter boud_rate_debug = 9600; // boudrate for uart init
    ////////////////////////////////////////////

    parameter maxdatasize = (1 << data_mem_size_in_bits) - 1; // requred for initial addres to sp
//    parameter boudgen_size = 16;
    
//    wire wb_slave_cyc;
//    assign wb_slave_cyc = 0;
//    wire wb_slave_stb;
//    assign wb_slave_stb = 0;
    
    wire[31:0] inst_mem_adr;
    wire[31:0] inst_mem_out;
    wire[31:0] inst_mem_in;
    wire[3:0] inst_mem_wmask;    

    wire[31:0] inst_mem_adr_inst;
    wire[31:0] inst_mem_data_inst;
    
    wire interrutack;
    wire[pc_bit_size-1:0] interuptadr;
    wire instmemaccesing;

    wire inst_mem_enable;
    wire mem_inst_enable_inst;

    wire[31:0] mem_data_inst_in;
    wire[31:0] mem_data_inst_out;
    wire[31:0] mem_inst_adr;
    wire mem_inst_enable;
    wire[3:0] mem_inst_wrmsk;
    wire cpu_mem_busy;

    wire[31:0] wb_in_itc;
    wire[31:0] wb_out_itc;
    wire[31:0] wb_adr_itc;
    wire[3:0] wb_sel_itc;
    wire wb_cyc_itc;
    wire wb_stb_itc;
    wire wb_ack_itc;
    wire wb_stall_itc;
    wire wb_we_itc;

    wire[31:0] wb_in_m;
    wire[31:0] wb_out_m;
    wire[31:0] wb_adr_m;
    wire[3:0] wb_sel_m;
    wire wb_cyc_m;
    wire wb_stb_m;
    wire wb_ack_m;
    wire wb_stall_m;
    wire wb_we_m;
    
    wire cpu_irq;
    wire exitint;

    reg rst0;
    reg rst;
    
    initial begin
        rst <= 1;
        rst0 <= 1;
    end
    
    always @ (posedge clk)begin
        rst0 <= rstin;
        rst <= rst0;
    end

    assign wb_slave_rst = rst;
    assign wb_slave_clk = clk;
    
    wb_shared_bus #(
        .interupt_ctrl_adr(interupt_ctrl_adr),
        .interupt_ctrl_adr_size(interupt_ctrl_adr_size),
        .pc_bit_size(pc_bit_size)
    )wb_slave_itc(
        .ram_in(mem_data_inst_in),
        .ram_out(mem_data_inst_out),
        .ram_adr(mem_inst_adr),
        .ram_msk(mem_inst_wrmsk),
        .ram_enable(mem_inst_enable),
        .ram_busy(1'b0),

        .wb_in_itc(wb_in_itc),
        .wb_out_itc(wb_out_itc),
        .wb_adr_itc(wb_adr_itc),
        .wb_sel_itc(wb_sel_itc),
        .wb_cyc_itc(wb_cyc_itc),
        .wb_stb_itc(wb_stb_itc),
        .wb_ack_itc(wb_ack_itc),
        .wb_stall_itc(wb_stall_itc),
        .wb_we_itc(wb_we_itc),

        .wb_in_s0(wb_in),
        .wb_out_s0(wb_out),
        .wb_adr_s0(wb_adr),
        .wb_sel_s0(wb_sel),
        .wb_cyc_s0(wb_cyc),
        .wb_stb_s0(wb_stb),
        .wb_ack_s0(wb_ack),
        .wb_stall_s0(wb_stall),
        .wb_we_s0(wb_we),

        .wb_in_dma(wb_slave_in),
        .wb_out_dma(wb_slave_out),
        .wb_adr_dma(wb_slave_adr),
        .wb_sel_dma(wb_slave_sel),
        .wb_cyc_dma(wb_slave_cyc),
        .wb_stb_dma(wb_slave_stb),
        .wb_ack_dma(wb_slave_ack),
        .wb_stall_dma(wb_slave_stall),
        .wb_we_dma(wb_slave_wren),

        .wb_in_cpu(wb_in_m),
        .wb_out_cpu(wb_out_m),
        .wb_adr_cpu(wb_adr_m),
        .wb_sel_cpu(wb_sel_m),
        .wb_cyc_cpu(wb_cyc_m),
        .wb_stb_cpu(wb_stb_m),
        .wb_ack_cpu(wb_ack_m),
        .wb_stall_cpu(wb_stall_m),
        .wb_we_cpu(wb_we_m),

        .clk(clk),
        .rst(rst)
        );

//    wb_mux #(
//        .interupt_ctrl_adr(interupt_ctrl_adr),
//        .interupt_ctrl_adr_size(interupt_ctrl_adr_size),
//        .pc_bit_size(pc_bit_size)
//    )wb_slave_itc(
//        .ram_in(mem_data_inst_in),
//        .ram_out(mem_data_inst_out),
//        .ram_adr(mem_inst_adr),
//        .ram_msk(mem_inst_wrmsk),
//        .ram_enable(mem_inst_enable),
//        .ram_busy(0),

//        .wb_in_itc(wb_in_itc),
//        .wb_out_itc(wb_out_itc),
//        .wb_adr_itc(wb_adr_itc),
//        .wb_sel_itc(wb_sel_itc),
//        .wb_cyc_itc(wb_cyc_itc),
//        .wb_stb_itc(wb_stb_itc),
//        .wb_ack_itc(wb_ack_itc),
//        .wb_stall_itc(wb_stall_itc),
//        .wb_we_itc(wb_we_itc),

//        .wb_in_s0(wb_in),
//        .wb_out_s0(wb_out),
//        .wb_adr_s0(wb_adr),
//        .wb_sel_s0(wb_sel),
//        .wb_cyc_s0(wb_cyc),
//        .wb_stb_s0(wb_stb),
//        .wb_ack_s0(wb_ack),
//        .wb_stall_s0(wb_stall),
//        .wb_we_s0(wb_we),

//        .wb_in_cpu(wb_in_m),
//        .wb_out_cpu(wb_out_m),
//        .wb_adr_cpu(wb_adr_m),
//        .wb_sel_cpu(wb_sel_m),
//        .wb_cyc_cpu(wb_cyc_m),
//        .wb_stb_cpu(wb_stb_m),
//        .wb_ack_cpu(wb_ack_m),
//        .wb_stall_cpu(wb_stall_m),
//        .wb_we_cpu(wb_we_m),

//        .clk(clk),
//        .rst(rst)
//        );

    int_basic_perif #(
        .clk_hz(clk_hz),
        .boud_rate_debug(boud_rate_debug),
//        .boudgen_size(boudgen_size),
        .interrupt_number(interrupt_number),
        .pc_bit_size(pc_bit_size)
    ) itc_basic_perif(
        .gpioin(gpioin),
        .gpioout(gpioout),
        .gpiodir(gpiodir),
        .clk(clk),
        .rst(rst),
        .wb_in(wb_out_itc),
        .wb_out(wb_in_itc),
        .wb_wren(wb_we_itc),
        .wb_adr(wb_adr_itc),
        .wb_sel(wb_sel_itc),
        .wb_cyc(wb_cyc_itc),
        .wb_stb(wb_stb_itc),
        .wb_ack(wb_ack_itc),
        .wb_stall(wb_stall_itc),
        .interrup(interrupt),
        .cpu_irq(cpu_irq),
        .exitint(exitint),
        .irq_adr(interuptadr),
        .irq_ack(interrutack),
        .rx_serial(rx_serial),
        .tx_serial(tx_serial)
    );

    cpu_core #(
        .pc_bit_size(pc_bit_size),
        .data_mem_start_bits(data_mem_start_bits),
        .maxdatasize(maxdatasize),
        .data_mem_size_in_bits(data_mem_size_in_bits),
        .disable_pipelined_wb(disable_pipelined_wb)
    ) core(
        .clk(clk),
        .rst(rst),
        .wb_adr_m(wb_adr_m),
        .wb_in_m(wb_out_m),
        .wb_out_m(wb_in_m),
        .wb_sel_m(wb_sel_m),
        .wb_we_m(wb_we_m),
        .wb_stb_m(wb_stb_m),
        .wb_cyc_m(wb_cyc_m),
        .wb_ack_m(wb_ack_m),
        .wb_stall_m(wb_stall_m),
        .inst_mem_adr_inst(inst_mem_adr_inst),
        .inst_mem_data_inst(inst_mem_data_inst),
        .mem_inst_enable_inst(mem_inst_enable_inst),
        .cpu_irq(cpu_irq),
        .interuptadr(interuptadr),
        .interrutack(interrutack),
        .exitint(exitint),
        .enable(enable), // can use as memory_busy signal for dram controller
        .dbg_o(dbg_o)
    );

    memory code_memory (
          .clk(clk), // input clka
          .web(4'h0), // input [3 : 0] wea
          .enb(mem_inst_enable_inst),
          .addrb(inst_mem_adr_inst), // input [31 : 0] addra
          .dinb(32'h00000000), // input [31 : 0] dina
          .doutb(inst_mem_data_inst), // output [31 : 0] douta
          .wea(mem_inst_wrmsk), // input [3 : 0] web
          .ena(mem_inst_enable),
          .addra(mem_inst_adr), // input [31 : 0] addrb
          .dina(mem_data_inst_out), // input [31 : 0] dinb
          .douta(mem_data_inst_in) // output [31 : 0] doutb
        );
        
/*    blk_mem_gen_v7_3_0 code_memory (
          .clka(clk), // input clka
          .wea(4'h0), // input [3 : 0] wea
          .ena(mem_inst_enable_inst),
          .addra(inst_mem_adr_inst), // input [31 : 0] addra
          .dina(32'h00000000), // input [31 : 0] dina
          .douta(inst_mem_data_inst), // output [31 : 0] douta
          .clkb(clk), // input clkb
          .web(mem_inst_wrmsk), // input [3 : 0] web
          .enb(mem_inst_enable),
          .addrb(mem_inst_adr), // input [31 : 0] addrb
          .dinb(mem_data_inst_out), // input [31 : 0] dinb
          .doutb(mem_data_inst_in) // output [31 : 0] doutb
        );
*/        
endmodule
