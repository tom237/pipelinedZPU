`timescale 1ns / 1ps
`include "zpupkg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kurucz Tamas 
// 
// Create Date: 04/09/2014 04:43:50 PM
// Design Name: 
// Module Name: decode
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


module decode(
    output wire[31:0] mem_inst_adr,
    input wire[31:0] mem_inst_datin,
    output wire mem_inst_enable,
    output reg[5:0] decodedinst,
    output reg[4:0] offset,
    output reg[1:0] spstate, // it will be changed on sp
    output reg[1:0] spstateadrdata, // it will give as adress to memory
    input wire stall,
    input wire flush,
    input wire clk,
    input wire rst,
    input wire enable,
    input wire [pc_bit_size-1:0] newpc,
    output reg[6:0] instvalue,
    output reg[pc_bit_size-1:0] pcout,
    input wire interrupt,
    input wire[pc_bit_size-1:0] interuptadr,
    output wire interrutack,
    output reg[pc_bit_size-1:0] nextpcout,
    output wire exitint,
    output reg[7:0] instructiondbg
    );
    parameter pc_bit_size = 32;
    
    reg waitforinst;
    reg waitforinstpre;
    reg[pc_bit_size-1:0] pc;
    reg idim;
    reg interruptin;
    
    wire[pc_bit_size-1:0] nextpc;
    wire[7:0] opcodein;
    wire[4:0] inernaloffset;    
    wire[7:0] opcodearray[3:0];

    reg endofintpre;
    reg endofint;

    reg interruptinpre;
    
    assign interrutack = interruptin;
    
    assign opcodearray[3] = mem_inst_datin[7:0]; //signal for demux instructions
    assign opcodearray[2] = mem_inst_datin[15:8];
    assign opcodearray[1] = mem_inst_datin[23:16];
    assign opcodearray[0] = mem_inst_datin[31:24];
    
    assign opcodein = opcodearray[pc[1:0]]; 

    //instruction adr generation    
    assign mem_inst_adr = (flush == 1) ? newpc :
                          ((interrupt == 1) && (interruptinpre == 0) && (idim == 0)) ? interuptadr :
                          ((waitforinstpre == 1) || (stall == 1)) ? pc :
                          nextpc; 
    assign mem_inst_enable = (((stall == 1) && (flush == 0) && (waitforinstpre == 0)) || (enable == 0)) ? 1'b0 : 1'b1; // enable inst mem 
    
    assign nextpc = pc + 4'b1;

    assign inernaloffset = {~opcodein[4],opcodein[3:0]};

    assign exitint = endofint;
    
    always @ (posedge clk)begin
        if(rst == 1)begin
            decodedinst <= `exe_nop;
            offset <= 0;
            spstateadrdata <= `stay_sp_source;
            spstate <= `stay_sp;
            instvalue <= 0;
            pcout <= 0;
            nextpcout <= 0;
            waitforinst <= 1;
            waitforinstpre <= 1;
            pc <= 0;
            idim <= 0;
            interruptin <= 0;
            instructiondbg <= 1;
            `ifdef enable_POPINT            
                endofintpre <= 0;
                endofint <= 0;
                interruptinpre <= 0;
            `endif
        end
        else begin
            `ifdef enable_POPINT // enable popint will generate only 1 cycle long ack signal
                if(interruptin == 1)begin
                    interruptin <= 0;
                    interruptinpre <= 0;
                end                
                endofintpre <= 0;
                endofint <= 0;
            `else
                if(interrupt == 0)begin // interrupt ack fleg clear
                    interruptin <= 0;
                end 
            `endif
            waitforinstpre <= 0; // 2 cycle delay for wait for memory if pc changed
            waitforinst <= waitforinstpre;
            if(flush == 0)begin
                if(stall == 0)begin
                    if((waitforinst == 0) && (enable == 1))begin // decode instructions
                        `ifdef enable_POPINT
                            endofint <=  endofintpre;// delay for 2 pipeline stage to send ack when ther interrupt executrd                            
                            if(interruptin == 0)begin
                                interruptin <= interruptinpre;
                            end
                        `else
                            interruptin <= interruptinpre;
                        `endif
                        pcout <= pc;
                        instvalue <= opcodein[6:0];
                        offset <= inernaloffset;
                    `ifdef enable_POPINT
                        if((interrupt == 1) && (interruptinpre == 0) && (idim == 0) && (endofint == 0)) begin //if there is an interrupt execute that
                    `else
                        if((interrupt == 1) && (interruptinpre == 0) && (idim == 0)) begin //if there is an interrupt execute that
                    `endif
                            interruptinpre <= 1;  // jump to interrupt adress default 0x20 and pushpc
                            spstateadrdata <= `stay_sp_source;
                            spstate <= `dec_sp;
                            decodedinst <= `exe_pushpc;
                            waitforinst <= 1;
                            waitforinstpre <= 1; 
                            pc <= interuptadr;
                            instructiondbg <= 8'h03;
                            nextpcout <= pc; // save the curet pc for pushpc in interrupt                                                    
                        end
                        else begin
                            nextpcout <= nextpc; //send next pc for other operations                                                
                            instructiondbg <= opcodein;
                            if(opcodein[7] == `inst_IM)begin  // decode im
                                idim <= 1;
                                if(idim == 0)begin
                                    spstateadrdata <= `stay_sp_source;
                                    spstate <= `dec_sp;
                                    decodedinst <= `exe_im0;    
                                end
                                else begin
                                    spstateadrdata <= `stay_sp_source;
                                    spstate <= `stay_sp;
                                    decodedinst <= `exe_imn;
                                end
                                pc <= nextpc;    
                            end
                            else begin
                                idim <= 0;
                                case(opcodein[6:5])
                                    `inst_STORESP : begin // decode store sp
                                        spstateadrdata <= `inc_sp_source;
                                        if(inernaloffset == 5'b00001)begin //decode special case of storesp store to tos and read new nos 
                                            decodedinst <= `exe_storesp1;
                                        end
                                        else if(inernaloffset == 5'b00010)begin //decode special case of storesp flip nos and tos
                                            decodedinst <= `exe_storesp2;
                                        end
                                        else begin
                                            decodedinst <= `exe_storesp;
                                        end
                                        spstate <= `inc_sp;                                        
                                        pc <= nextpc;
                                    end
                                    `inst_LOADSP : begin // decode loadsp
                                        spstateadrdata <= `offset_sp_source;
                                        decodedinst <= `exe_loadsp;
                                        spstate <= `dec_sp;                                        
                                        pc <= nextpc;
                                    end
                                    `inst_EMULATE : begin // decode emulate
                                        case(opcodein[4:0])
                                            `inst_LOADH : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_loadh;                                                    
                                            end
                                            `inst_STOREH : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_storeh;    
                                            end
                                            `inst_LOADB : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_loadb;                                                    
                                            end
                                            `inst_STOREB : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_storeb;    
                                            end
                                            `inst_LESSTHEN : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_lessthen;
                                            end
                                            `inst_LESSTHENOREQUAL : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_lessthenoreq;
                                            end
                                            `inst_ULESSTHEN : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_ulessthen;
                                            end
                                            `inst_ULESSTHENOREQUAL : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_ulessthenoreq;
                                            end
                                            `inst_LSHIFTRIGHT : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_lshiftright;
                                            end
                                            `inst_ASHIFTLEFT : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_ashiftleft;
                                            end
                                            `inst_ASHIFTRIGHT : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_ashiftright;
                                            end
                                            `inst_CALL : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_call;
                                            end
                                            `inst_EQ : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_eq;
                                            end
                                            `inst_NEQ : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_neq;
                                            end
                                            `inst_NEG : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_neg;
                                            end
                                            `inst_SUB : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_sub;
                                            end
                                            `inst_XOR : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_xor;
                                            end                                            
                                            `inst_EQBRANCH : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_eqbench;    
                                            end
                                            `inst_NEQBRANCH : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_neqbench;    
                                            end
                                            `inst_POPPCREL : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_poppcrel;    
                                            end
                                            `inst_PUSHPC : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `dec_sp;
                                                decodedinst <= `exe_pushpc;                                                        
                                            end
                                            `inst_PUSHSPADD : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;    
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_pushspadd;
                                            end
                                            `inst_CALLREL : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `stay_sp;
                                                decodedinst <= `exe_callrel;
                                            end
                                            `inst_MULT : begin
                                                pc <= nextpc;
                                                spstateadrdata <= `inc_sp_source;
                                                spstate <= `inc_sp;
                                                decodedinst <= `exe_mul;
                                            end
                                                                                                                                                                                                                                                                                                                                                                                                                                                       
                                            default : begin
                                                spstateadrdata <= `stay_sp_source;
                                                spstate <= `dec_sp;
                                                decodedinst <= `exe_pushpc;
                                                waitforinst <= 1;
                                                waitforinstpre <= 1;
                                                pc <= opcodein[4:0] << 5;
                                            end
                                        endcase
                                    end
                                    default : begin
                                        pc <= nextpc;
                                        if(opcodein[4] == `inst_ADDSP)begin // decode addsp
                                            spstateadrdata <= `offset_sp_source;    
                                            spstate <= `stay_sp;
                                            decodedinst <= `exe_addsp;
                                        end
                                        else begin
                                            case(opcodein[3:0])
                                                `inst_POPPC : begin // decode poppc
                                                    spstateadrdata <= `inc_sp_source;
                                                    spstate <= `inc_sp;
                                                    decodedinst <= `exe_poppc;    
                                                end
                                                `inst_LOAD : begin // decode load
                                                    spstateadrdata <= `stay_sp_source;
                                                    spstate <= `stay_sp;
                                                    decodedinst <= `exe_load;                                                    
                                                end
                                                `inst_STORE : begin // decode store
                                                    spstateadrdata <= `inc_sp_source; // add sp+8 for memory address 2 times it wil read the original sp + 8 and sp +12 
                                                    spstate <= `inc_sp; // add sp+4 to sp 2 times it will give sp + 4
                                                    decodedinst <= `exe_store;    
                                                end
                                                `inst_PUSHSP : begin // decode pushsp
                                                    spstateadrdata <= `stay_sp_source;
                                                    spstate <= `dec_sp;
                                                    decodedinst <= `exe_pushsp;                                                        
                                                end
                                                `inst_POPSP : begin // decode popsp
                                                    spstateadrdata <= `tos_sp_source;
                                                    spstate <= `tos_sp;
                                                    decodedinst <= `exe_popsp;
                                                end 
                                                `inst_ADD : begin // decode add
                                                    spstateadrdata <= `inc_sp_source;
                                                    spstate <= `inc_sp;
                                                    decodedinst <= `exe_add;
                                                end
                                                `inst_AND : begin // decode and
                                                    spstateadrdata <= `inc_sp_source;
                                                    spstate <= `inc_sp;
                                                    decodedinst <= `exe_and;
                                                end
                                                `inst_OR : begin // decode or
                                                    spstateadrdata <= `inc_sp_source;
                                                    spstate <= `inc_sp;
                                                    decodedinst <= `exe_or;
                                                end
                                                `inst_NOT : begin // decode not
                                                    spstateadrdata <= `stay_sp_source;
                                                    spstate <= `stay_sp;
                                                    decodedinst <= `exe_not;
                                                end
                                                `inst_FLIP : begin // decode flip
                                                    spstateadrdata <= `stay_sp_source;
                                                    spstate <= `stay_sp;
                                                    decodedinst <= `exe_flip;
                                                end
                                                `inst_NOP : begin // decode not
                                                    spstateadrdata <= `stay_sp_source;
                                                    spstate <= `stay_sp;
                                                    decodedinst <= `exe_nop;
                                                end
                                                `inst_POPINT : begin // decode popint if not enabled it is the same as poppc
                                                    spstateadrdata <= `inc_sp_source;
                                                    spstate <= `inc_sp;
                                                    decodedinst <= `exe_poppc;
                                                    `ifdef enable_POPINT
                                                         endofintpre <= 1;                                                                      
                                                    `endif 
                                                end

                                                default : begin//`inst_BREAK : begin 
                                                //    pc <= pc;
                                                    decodedinst <= `exe_nop;
                                                    spstate <= `stay_sp;
                                                    spstateadrdata <= `stay_sp_source;                                                      
                                                    instructiondbg <= 8'h00;  
                                                end
                                            endcase
                                        end
                                    end        
                                endcase
                            end                            
                        end
                    end
                    else begin // send nop instruction while load from memory or disabled
                        instructiondbg <= 8'h01;
                        decodedinst <= `exe_nop;
                        spstate <= `stay_sp;
                        spstateadrdata <= `stay_sp_source;
                    end
                end 
            end
            else begin // after jump send nop instruction
                instructiondbg <= 8'h01;
                idim <= 0;
                waitforinst <= 0;
                pc <= newpc;
                decodedinst <= `exe_nop;
                spstate <= `stay_sp;
                spstateadrdata <= `stay_sp_source;
                `ifdef enable_POPINT
                    endofintpre <= 0;
                    endofint <= 0;
                    interruptin <= 0;
                    interruptinpre <= 0;
                `else
                    if(interruptin == 0)begin
                        interruptinpre <= 0;
                    end
                `endif
            end
        end
    end

endmodule
