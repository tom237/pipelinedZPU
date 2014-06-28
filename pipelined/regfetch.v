`timescale 1ns / 1ps
`include "zpupkg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kurucz Tamas
// 
// Create Date: 04/09/2014 04:43:50 PM
// Design Name: 
// Module Name: prefetch
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


module regfetch(
    input wire clk,
    input wire rst,
    output wire stall,
    input wire stallexe,
    input wire flush,
    output wire[31:0] mem_adr_a,
    output wire mem_enable_a,
    input wire[5:0] decodedinst,
    input wire[1:0] spstateadr,
    input wire[1:0] spstate,
    input wire[data_mem_size_in_bits-1:0] tos,
    input wire[4:0] instofset,
    input wire[6:0] instvalue,
    output reg[5:0] instout,
    output reg[6:0] instoutvalue,
    output reg[data_mem_size_in_bits-1:0] offset,
    input wire[pc_bit_size-1:0] pcin,
    output reg[pc_bit_size-1:0] pcout,
    output reg[data_mem_size_in_bits-1:0] destiny,
    output reg[data_mem_size_in_bits-1:0] spout,
    input wire[7:0] instructiondbgin,
    output reg[7:0] instructiondbgout,
    input wire[pc_bit_size-1:0] nextpcin,
    output reg[pc_bit_size-1:0] nextpcout
    );
    parameter data_mem_start_bits = 30;
    parameter maxdatasize = 32'h1fff;
    parameter data_mem_size_in_bits = 30;
    parameter pc_bit_size = 32;

    reg[data_mem_size_in_bits-1:0] sp;    
    reg[2:0] state;
    wire[data_mem_size_in_bits-1:0] sparray[3:0];
    wire[data_mem_size_in_bits-1:0] spdestarray[3:0];

    //signals for stack b adress 
    assign sparray[`stay_sp_source] = sp[data_mem_size_in_bits-1:0] + 4'h4;
    assign sparray[`inc_sp_source] = sp[data_mem_size_in_bits-1:0] + 4'h8;
    assign sparray[`offset_sp_source] = sp[data_mem_size_in_bits-1:0] + (instofset << 2);
    assign sparray[`tos_sp_source] = tos[data_mem_size_in_bits-1:0];
    assign mem_enable_a = (spstateadr == `stay_sp_source) ? 1'b0 : 1'b1;
    
    //signal for sp and destiny adress
    assign spdestarray[`inc_sp] = sp + 4'h4;
    assign spdestarray[`dec_sp] = sp - 4'h4;
    assign spdestarray[`tos_sp] = tos[data_mem_size_in_bits - 1:0];     
    assign spdestarray[`stay_sp] = sp;

    //stall if required
    assign stall = ((stallexe == 1) || (state == `pref_popsp) || 
                   ((state == `runstate_pref) && ((decodedinst == `exe_store) || (decodedinst == `exe_eqbench) || (decodedinst == `exe_neqbench) ||
                   (decodedinst == `exe_storeb) || (decodedinst == `exe_storeh) || (decodedinst == `exe_popsp)))) ? 
                   1'b1 : 1'b0;
    
    //take out sp or if popsp executed sp+4 to reload the stack
    assign mem_adr_a = (state == `pref_popsp2) ? sparray[`stay_sp_source] : sparray[spstateadr];
    
    always @ (posedge clk)begin
        if(rst == 1)begin
            sp <= ((maxdatasize - 4) & 32'hfffffffc);    
            state <= `runstate_pref;
            instout <= `exe_nop;
            instoutvalue <= 0;
            offset <= 0;
            pcout <= 0;
            nextpcout <= 0;
            destiny <= 0;
            spout <= ((maxdatasize - 4) & 32'hfffffffc);
            instructiondbgout <= 1;
        end
        else begin
            if(flush == 0)begin
                if(stallexe == 0)begin
                    spout <= sp;                    
                    pcout <= pcin;
                    nextpcout <= nextpcin;
                    instoutvalue <= instvalue;
                    instructiondbgout <= instructiondbgin;
                    case(state)
                        default : begin//`runstate_pref : begin //run executions and modifie some os instructions
                            offset <= sparray[spstateadr];                               
                            sp <= spdestarray[spstate];
                            case(decodedinst)
                                `exe_store : begin //some special instruction that read end write data diferent from other instruction
                                    destiny <= spdestarray[spstate];                                                    
                                    instout <= decodedinst;
                                    state <= `pref_store;
                                end
                                `exe_storeb : begin
                                    destiny <= spdestarray[spstate];                                                    
                                    instout <= decodedinst;
                                    state <= `pref_store;
                                end
                                `exe_storeh : begin
                                    destiny <= spdestarray[spstate];                                                    
                                    instout <= decodedinst;
                                    state <= `pref_store;
                                end
                                `exe_popsp : begin
                                    destiny <= spdestarray[spstate];                                        
                                    instout <= `exe_nop;                                    
                                    state <= `pref_popsp;
                                end
                                `exe_storesp : begin // storesp just push the offset value to seve an adder and the adress will be calculated in next stage
                                    destiny <= instofset << 2;
                                    instout <= decodedinst;
                                end
                                `exe_storesp1 : begin
                                    destiny <= instofset << 2;
                                    instout <= decodedinst;
                                end
                                `exe_storesp2 : begin
                                    destiny <= instofset << 2;
                                    instout <= decodedinst;
                                end
                                `exe_eqbench : begin
                                    destiny <= spdestarray[spstate];                                        
                                    instout <= decodedinst;                                    
                                    state <= `pref_branch;
                                end
                                `exe_neqbench : begin
                                    destiny <= spdestarray[spstate];                                        
                                    instout <= decodedinst;                                    
                                    state <= `pref_branch;
                                end
                                default : begin
                                    destiny <= spdestarray[spstate];                                                    
                                    instout <= decodedinst;
                                end
                            endcase
                        end
                        `pref_store : begin //store to fatch sp + 4
                            offset <= sparray[spstateadr];
                            sp <= spdestarray[spstate];
                            destiny <= spdestarray[spstate];
                            instout <= `exe_store2;
                            state <= `runstate_pref;
                        end
                        `pref_popsp : begin //popsp to pop the new stack
                            offset <= sparray[spstateadr];
                            sp <= spdestarray[spstate];
                            destiny <= spdestarray[spstate];
                            instout <= `exe_mov;
                            state <= `pref_popsp2;
                        end
                        `pref_popsp2 : begin //popsp to pop the new stack + 4
                            offset <= sparray[`stay_sp_source];
                            sp <= sp;
                            destiny <= spdestarray[`stay_sp_source];
                            instout <= `exe_mov;
                            state <= `runstate_pref;
                        end
                        `pref_branch : begin //pop sp +12 after banch instruction to reload top os stack and next of stack
                            offset <= sparray[spstateadr];
                            sp <= spdestarray[spstate];
                            destiny <= spdestarray[spstate];
                            instout <= `exe_mov;
                            state <= `runstate_pref;                            
                        end
                    endcase
                end
            end
            else begin
                instout <= `exe_nop; //if there is a flush send nop 
                offset <= sparray[`stay_sp_source];
                sp <= sp;
                state <= `runstate_pref;
                instructiondbgout <= 8'h01;
            end
        end
    end

endmodule
