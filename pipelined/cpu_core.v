`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kurucz Tam?s
// 
// Create Date: 06/17/2014 12:00:40 PM
// Design Name: 
// Module Name: cpu_core
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


module cpu_core(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire[31:0] wb_in_m,
    output wire[31:0] wb_out_m,
    output wire[31:0] wb_adr_m,
    output wire[3:0] wb_sel_m,
    output wire wb_cyc_m,
    output wire wb_stb_m,
    input wire wb_ack_m,
    input wire wb_stall_m,
    output wire wb_we_m,
    output wire[31:0] inst_mem_adr_inst,
    input wire[31:0] inst_mem_data_inst,
    output wire mem_inst_enable_inst,
    input wire cpu_irq,
    input wire[pc_bit_size-1:0] interuptadr,
    output wire interrutack,
    output wire exitint,
    output wire[136:0] dbg_o
    
    );
    parameter data_mem_start_bits = 26; // have to greater then pc_bit_size
    parameter data_mem_size_in_bits = 11;// sp size smaller them data_mem_start_bits have to greater then 7
    parameter pc_bit_size = 25; //pc size have to less then data_mem_start_bits so the max value is 29 if                                  //data_mem_start_bits is 30 and in interupt_ctrl_adr MSB is 1
    parameter disable_pipelined_wb = 0; // if 1 use standard wb bus if 0 use pipelined wb bus as master
    parameter maxdatasize = (1 << data_mem_size_in_bits) - 1; // requred for initial addres to sp
    parameter enable_POPINT = 1; // enable POPINT instuction

    wire mem_enable_a;
    wire data_mem_enable;
    wire[31:0] data_mem_adr;
    wire[31:0] data_mem_out;
    wire[31:0] data_mem_in;
    wire[3:0] data_mem_wmask;
    wire[31:0] data_mem_ain;
    wire[31:0] data_mem_a_adr;

    wire flushout;
    wire[data_mem_size_in_bits-1:0] destinyexec;
    wire stallexe;
    wire[5:0] instexe; //??
    wire[6:0] instexevalue;
    wire[data_mem_size_in_bits-1:0] offsetexe;
    wire[data_mem_size_in_bits-1:0]tosout;
    wire[pc_bit_size-1:0] newpc;
    wire[pc_bit_size-1:0] pcinexe;
    wire[data_mem_size_in_bits-1:0] spexec;
    wire[7:0] instructiondbgexe;
    wire[pc_bit_size-1:0] nextpcexe;

    wire stalldeco;
    wire[5:0] decoinst;  // ???
    wire[1:0] secondoperandadrchange_sp;
    wire[1:0] spchange;
    wire[4:0] offsetdec;
    wire[6:0] instvaluedeco;
    wire[pc_bit_size-1:0] pcdec;
    wire[7:0] instructiondbg;    
    wire[pc_bit_size-1:0] nextpcdec;        

    execution #( 
        .pc_bit_size(pc_bit_size),
        .data_mem_start_bits(data_mem_start_bits),
        .maxdatasize(maxdatasize),
        .data_mem_size_in_bits(data_mem_size_in_bits),
        .disable_pipelined_wb(disable_pipelined_wb)
    ) execut(
        .data_mem_adr(data_mem_adr),
        .data_mem_out(data_mem_out),
        .data_mem_in(data_mem_in),
        .data_mem_wmask(data_mem_wmask),
        .data_mem_enable(data_mem_enable),
        .data_mem_ain(data_mem_ain),
        .destiny(destinyexec),
        .stall(stallexe),
        .flushout(flushout),
        .clk(clk),
        .rst(rst),
        .instin(instexe),
        .instinvalue(instexevalue),
        .offset(offsetexe),
        .wb_adr(wb_adr_m),
        .wb_out(wb_out_m),
        .wb_in(wb_in_m),
        .wb_sta(wb_sel_m),
        .wb_wena(wb_we_m),
        .wb_stb(wb_stb_m),
        .wb_cyc(wb_cyc_m),
        .wb_ack(wb_ack_m),
        .wb_stall(wb_stall_m),
        .tosout(tosout),
        .newpc(newpc),
        .pcin(pcinexe),
        .spin(spexec),
        .instructiondbg(instructiondbgexe),
        .nextpcin(nextpcexe),
        .dbg_o(dbg_o)
        );

    regfetch #( 
        .pc_bit_size(pc_bit_size),
        .data_mem_start_bits(data_mem_start_bits),
        .maxdatasize(maxdatasize),
        .data_mem_size_in_bits(data_mem_size_in_bits)
    ) registerfetch(
        .clk(clk),
        .rst(rst),
        .stall(stalldeco),
        .stallexe(stallexe),
        .flush(flushout),
        .mem_adr_a(data_mem_a_adr),
        .mem_enable_a(mem_enable_a),
        .decodedinst(decoinst),
        .spstateadr(secondoperandadrchange_sp),
        .spstate(spchange),
        .tos(tosout),
        .instofset(offsetdec),
        .instvalue(instvaluedeco),
        .instout(instexe),
        .instoutvalue(instexevalue),
        .offset(offsetexe),
        .pcin(pcdec),
        .pcout(pcinexe),
        .destiny(destinyexec),
        .spout(spexec),
        .instructiondbgout(instructiondbgexe),
        .instructiondbgin(instructiondbg),
        .nextpcin(nextpcdec),
        .nextpcout(nextpcexe)
        );
        
    decode #(
        .pc_bit_size(pc_bit_size)
    )decoder(
        .mem_inst_adr(inst_mem_adr_inst),
        .mem_inst_datin(inst_mem_data_inst),
        .mem_inst_enable(mem_inst_enable_inst),
        .decodedinst(decoinst),
        .offset(offsetdec),
        .spstate(spchange),
        .spstateadrdata(secondoperandadrchange_sp),
        .stall(stalldeco),
        .flush(flushout),
        .clk(clk),
        .rst(rst),
        .newpc(newpc),
        .instvalue(instvaluedeco),
        .pcout(pcdec),
        .interrupt(cpu_irq),
        .interuptadr(interuptadr),
        .interrutack(interrutack),
        .exitint(exitint),
        .enable(enable),
        .nextpcout(nextpcdec),
        .instructiondbg(instructiondbg)
        );        

    steck #(
        .data_mem_size_in_bits(data_mem_size_in_bits)
    )stack_data_memory (
          .clk(clk), // input clka
          .enb(mem_enable_a),
          .addrb(data_mem_a_adr), // input [31 : 0] addra
          .doutb(data_mem_ain), // output [31 : 0] douta
          .wea(data_mem_wmask), // input [3 : 0] web
          .ena(data_mem_enable),
          .addra(data_mem_adr), // input [31 : 0] addrb
          .dina(data_mem_out), // input [31 : 0] dinb
          .douta(data_mem_in) // output [31 : 0] doutb
        );

/*    blk_mem_gen_v7_3_1 code_memory (
          .clka(clk), // input clka
          .wea(4'h0), // input [3 : 0] wea
          .ena(mem_enable_a),
          .addra(data_mem_a_adr), // input [31 : 0] addra
          .dina(32'h00000000), // input [31 : 0] dina
          .douta(data_mem_ain), // output [31 : 0] douta
          .clkb(clk), // input clkb
          .web(data_mem_wmask), // input [3 : 0] web
          .enb(data_mem_enable),
          .addrb(data_mem_adr), // input [31 : 0] addrb
          .dinb(data_mem_out), // input [31 : 0] dinb
          .doutb(data_mem_in) // output [31 : 0] doutb
        );*/


endmodule
