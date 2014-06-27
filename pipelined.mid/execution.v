`timescale 1ns / 1ps
`include "zpupkg.v"
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Kurucz Tamas
// 
// Create Date: 04/09/2014 04:43:50 PM
// Design Name: 
// Module Name: execution
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


module execution(
    output reg[31:0] data_mem_adr,
    output reg[31:0] data_mem_out,
    input wire[31:0] data_mem_in,
    output reg data_mem_enable,
    output reg[3:0] data_mem_wmask,
    input wire[31:0] data_mem_ain,
    input wire[data_mem_size_in_bits-1:0] destiny,
    output wire stall,
    output wire flushout,
    input wire clk,
    input wire rst,
    input wire[4:0] instin,
    input wire[6:0] instinvalue,
    input wire[data_mem_size_in_bits-1:0] offset,
    output reg[31:0] wb_adr,
    output reg[31:0] wb_out,
    input wire[31:0] wb_in,
    output reg[3:0] wb_sta,
    output reg wb_wena,
    output reg wb_stb,
    output reg wb_cyc,
    input wire wb_ack,
    output wire[data_mem_size_in_bits-1:0] tosout,
    input wire[pc_bit_size-1:0] pcin,
    output reg[pc_bit_size-1:0] newpc,
    input wire[data_mem_size_in_bits-1:0] spin,
    input wire wb_stall,
    input wire[7:0] instructiondbg,
    input wire[pc_bit_size-1:0] nextpcin,
    output reg[136:0] dbg_o //pc[31:0] sp[63:32] tos[95:64] nos[127:96] inst[135:128]    
    );
    parameter data_mem_start_bits = 26;
    parameter maxdatasize = 32'h1fff;
    parameter data_mem_size_in_bits = 26;
    parameter pc_bit_size = 32;
    parameter disable_pipelined_wb = 0;
 
    genvar i;
    
    reg[31:0] tos;

    reg[2:0] state;
    reg[2:0] nextloadstate;
    
    reg flush;

    reg[31:0] laststoreddat[1:0];
    reg[data_mem_size_in_bits-3:0] laststoredadr[1:0];
    reg laststore[1:0];
    wire[31:0] datain;

    wire[31:0] andexe;
    wire[31:0] orexe;
    wire[31:0] addexe;
    wire[31:0] notexe;
    wire[31:0] im0exe;
    wire[31:0] imnexe;
    wire[31:0] flipexe;
    wire[31:0] pushspexe; 
    wire[31:0] pushpcexe;
    wire[31:0] addspexe;
    wire[3:0] wrmaskb[3:0];
    reg[31:0] nos;

    wire signed[31:0] stos;
    wire signed[31:0] snos;
    wire[31:0] lessthenexe;
    wire[31:0] ulessthenexe;
    reg memorybusoperation;
    wire[31:0] eqexe;
    wire[31:0] subexe;
    wire[31:0] pushspaddexe;
    wire[pc_bit_size-1:0] pcrelexe;
    reg signed[31:0] multiplicationexe;
    reg signed[31:0] multiplicationexeout;

    wire[31:0] data_mem_inb[3:0];
    wire[31:0] wb_inb[3:0];
    wire[31:0] storespadr;
//    reg dbgok;
                    
    // the valid data from mem tougth a fifo
    assign datain = ((laststoredadr[0] == offset[data_mem_size_in_bits-1:2]) && (laststore[0] == 1)) ? laststoreddat[0] :
                    ((laststoredadr[1] == offset[data_mem_size_in_bits-1:2]) && (laststore[1] == 1)) ? laststoreddat[1] : data_mem_ain;

//    wire[31:0] outarray[63:0];
//    assign outarray[`exe_and] = tos & datain;
//    assign outarray[`exe_or] = tos | datain;
//    assign outarray[`exe_add] = tos + datain;
//    assign outarray[`exe_not] = ~tos;
//    assign outarray[`exe_im0] = {{25{instinvalue[6]}},instinvalue};
//    assign outarray[`exe_imn] = {tos[24:0],instinvalue};
//    for(i=0;i<32;i=i+1)begin
//        assign outarray[`exe_flip][i] = tos[31-i]; 
//    end
//    assign outarray[`exe_pushsp] = destiny + 4;
//    assign outarray[`exe_pushpc] = pcin + 1;
//    assign outarray[`exe_mov] = datain;

    // the ressaults of operations       
    assign andexe = tos & nos;
    assign orexe = tos | nos;
    assign addexe = tos + nos;
    assign addspexe = tos + datain;
    assign notexe = ~tos;
    assign im0exe = {{25{instinvalue[6]}},instinvalue};
    assign imnexe = {tos[24:0],instinvalue};
    for(i=0;i<32;i=i+1)begin
        assign flipexe[i] = tos[31-i]; 
    end
    assign pushspexe = spin | (1 << data_mem_start_bits);
    assign pushpcexe = nextpcin;

    assign snos = nos;
    assign stos = tos;
    assign lessthenexe = (stos < snos) ? 1 : 0;
    assign ulessthenexe = (tos < nos) ? 1 : 0;
    assign eqexe = (tos == nos) ? 1 : 0;
    assign subexe = nos - tos;
    assign pushspaddexe = (spin | (1 << data_mem_start_bits)) + {tos[29:0],2'b00};
    assign pcrelexe = tos[pc_bit_size-1:0] + pcin;

    assign storespadr = spin + destiny;
    
    assign tosout = tos[data_mem_size_in_bits-1:0];

    // the stall system if operation get executad that require stall is stall the pipeline
    assign stall = (((state == `runstate_exec) && ((instin == `exe_load) || (instin == `exe_loadb) || (instin == `exe_poppc) || 
                    (instin == `exe_callrel) || (instin == `exe_mul) ||
                    ((instin == `exe_store2) && (memorybusoperation == 1) && (wb_stall == 1) ) )) || 
                    (state == `stateload) || (state == `statemul) ||
                    ((lastbusop == 1) && (wb_ack == 0)) ) ? 
                    1'b1 : 1'b0;
    
    // the flush signal tio clear pipeline when jump
    assign flushout = flush;

    //constants for half word / byte write or read
    assign wrmaskb[3] = 4'h1;
    assign wrmaskb[2] = 4'h2;
    assign wrmaskb[1] = 4'h4;
    assign wrmaskb[0] = 4'h8;

    assign data_mem_inb[3] = data_mem_in[7:0];    
    assign data_mem_inb[2] = data_mem_in[15:8];
    assign data_mem_inb[1] = data_mem_in[23:16];
    assign data_mem_inb[0] = data_mem_in[31:24];
    assign wb_inb[3] = wb_in[7:0];
    assign wb_inb[2] = wb_in[15:8];
    assign wb_inb[1] = wb_in[23:16];
    assign wb_inb[0] = wb_in[31:24];    

//    wire[data_mem_size_in_bits-1:0] laststoredadrs[1:0];
//    assign laststoredadrs[0] = laststoredadr[0] << 2;
//    assign laststoredadrs[1] = laststoredadr[1] << 2;

//    assign dbg_o[31:0] = pcin;//pc
//    assign dbg_o[63:32] = pushspexe; //sp
//    assign dbg_o[95:64] = tos; //tos
//    assign dbg_o[127:96] = nos; //nos
//    assign dbg_o[135:128] = instructiondbg; //inst
//    assign dbg_o[136] = dbgok;

    reg lastbusop;
    
    always @ (posedge clk)begin
        if(rst == 1)begin // reset everything;
            flush <= 0;
            data_mem_out <= 0;
            data_mem_wmask <= 0;
            wb_adr <= 0;
            wb_out <= 0;
            wb_sta <= 0;
            wb_wena <= 0;
            wb_stb <= 0;
            wb_cyc <= 0;
            data_mem_adr <= ((maxdatasize - 4) & 32'hfffffffc);
            tos <= data_mem_in;            
            state <= `runstate_exec;    
            laststoreddat[0] <= 0;
            laststoredadr[0] <= 0;
            laststore[0] <= 0;
            laststoreddat[1] <= 0;
            laststoredadr[1] <= 0;
            laststore[1] <= 0;
            nos <= 0;
            memorybusoperation <= 0;
            data_mem_enable <= 0;
            multiplicationexeout <= 0;
            multiplicationexe <= 0;
            nextloadstate <= `runstate_exec;
//            dbgok <= 0;
            dbg_o[31:0] <= 0;//pc
            dbg_o[63:32] <= 0; //sp
            dbg_o[95:64] <= 0; //tos
            dbg_o[127:96] <= 0; //nos
            dbg_o[135:128] <= 0; //inst
            dbg_o[136] <= 0;
            data_mem_enable <= 0;
            newpc <= 0;
            lastbusop <= 0; 
        end
        else begin                    
            if(lastbusop == 1)begin
                if(wb_ack == 1)begin
                    lastbusop <= 0;
                    wb_stb <= 0;
                    wb_cyc <= 0;
                end
            end
            else begin
                wb_stb <= 0;
                wb_cyc <= 0;
            end
            data_mem_enable <= 0;
            data_mem_wmask <= 0;
            laststoredadr[1] <= laststoredadr[0];
            laststoreddat[1] <= laststoreddat[0];
            laststore[1] <= laststore[0];
            laststore[0] <= 0;
            flush <= 0;
            multiplicationexe <= stos * snos;
            multiplicationexeout <= multiplicationexe;
//            dbgok <= 0;
            dbg_o[136] <= 0;
            if(flush == 1)begin
                if(instin == `exe_mov)begin
                    nos <= datain;
                    tos <= nos;
                end
            end
            else begin
                if(!((lastbusop == 1) && (wb_ack == 0)))begin
                    case(state)
                        default : begin//`runstate_exec : begin     // the main stage                                       
    //                      dbgok <= 1;
                            dbg_o[31:0] <= pcin;//pc
                            dbg_o[63:32] <= pushspexe; //sp
                            dbg_o[95:64] <= tos; //tos
                            dbg_o[127:96] <= nos; //nos
                            dbg_o[135:128] <= instructiondbg; //inst
                            if(instructiondbg != 8'h01)begin
                                dbg_o[136] <= 1;
                            end
                            case(instin)                // operations
                                `exe_loadsp : begin
                                    nos <= tos;
                                    tos <= datain;
                                    data_mem_out <= datain;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= datain;
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;                    
                                end
                                `exe_storesp : begin                                
                                    tos <= nos;
                                    data_mem_out <= tos;
                                    nos <= datain;
                                    data_mem_adr <= storespadr[data_mem_size_in_bits-1:0];
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= storespadr[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= tos;
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                end
                                `exe_storesp1 : begin // special case of storesp offset 1                                
                                    tos <= tos;
                                    data_mem_out <= tos;
                                    nos <= datain;
                                    data_mem_adr <= storespadr[data_mem_size_in_bits-1:0];
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= storespadr[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= tos;
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                end
                                `exe_storesp2 : begin // special case of storesp offset 2                               
                                    tos <= nos;
                                    data_mem_out <= tos;
                                    nos <= tos;
                                    data_mem_adr <= storespadr[data_mem_size_in_bits-1:0];
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= storespadr[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= tos;
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                end
                                `exe_load : begin
                                    nextloadstate <= `stateload2;
                                    if(tos[31:data_mem_start_bits] == 1)begin
                                        data_mem_adr <= tos[data_mem_start_bits-1:0];
                                        state <= `stateload;
                                        data_mem_enable <= 1;
                                        memorybusoperation <= 0;                                    
                                    end
                                    else begin
                                        wb_adr <= tos;
                                        wb_sta <= 4'hf;
                                        wb_wena <= 0;
                                        wb_stb <= 1;
                                        wb_cyc <= 1;
                                        state <= `stateload;
                                        memorybusoperation <= 1;
                                    end                                                    
                                end
                                `exe_store : begin
                                    tos <= datain;
                                    if(tos[31:data_mem_start_bits] == 1)begin
                                        data_mem_adr <= tos[data_mem_size_in_bits-1:0];
                                        data_mem_out <= nos;
                                        data_mem_wmask <= 4'hf;
                                        data_mem_enable <= 1;
                                        memorybusoperation <= 0;      
                                    end
                                    else begin
                                        memorybusoperation <= 1;
                                        wb_adr <= tos;
                                        wb_out <= nos;
                                        wb_sta <= 4'hf;
                                        wb_wena <= 1;
                                        wb_stb <= 1;
                                        wb_cyc <= 1;
                                    end
                                end                            
                                `exe_store2 : begin // 2nd stage of store reload nos and wait for bus if it is needed
                                    if(memorybusoperation == 1)begin
                                        if(wb_stall == 0)begin
    //                                        state <= `state_storeack;
                                            lastbusop <= 1;
                                        end
                                        else begin
                                            wb_stb <= 1;
                                        end                                                                    
                                        wb_stb <= disable_pipelined_wb;
                                        wb_cyc <= 1;
                                    end
                                    nos <= datain;
                                end
                                default : begin//`exe_nop : begin
    //                                tos <= tos;
                                end
                                `exe_poppc : begin
                                    newpc <= tos[pc_bit_size-1:0];                                
                                    nos <= datain;
                                    tos <= nos;
                                    flush <= 1;
                                end
                                `exe_mov : begin // for some operation tat change tos and nos too fe.: popsp, neqbrench, eqbrench
                                    nos <= datain;
                                    tos <= nos;
                                end                        
                                `exe_and : begin
                                    tos <= andexe;
                                    nos <= datain;
                                    data_mem_out <= andexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= andexe;
                                end
                                `exe_or : begin
                                    tos <= orexe;
                                    nos <= datain;;
                                    data_mem_out <= orexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= orexe;
                                end                            
                                `exe_add : begin
                                    tos <= addexe;
                                    nos <= datain;
                                    data_mem_out <= addexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= addexe;
                                end
                                `exe_not : begin
                                    tos <= notexe;
                                    data_mem_out <= notexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= notexe;
                                end
                                `exe_im0 : begin
                                    nos <= tos;
                                    tos <= im0exe;
                                    data_mem_out <= im0exe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= im0exe;
                                end
                                `exe_imn : begin
                                    tos <= imnexe;
                                    data_mem_out <= imnexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= imnexe;
                                end
                                `exe_flip : begin
                                    tos <= flipexe;
                                    data_mem_out <= flipexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= flipexe;
                                end
                                `exe_pushsp : begin
                                    nos <= tos;
                                    tos <= pushspexe;
                                    data_mem_out <= pushspexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= pushspexe;
                                end
                                `exe_pushpc : begin
                                    nos <= tos;
                                    tos <= pushpcexe;
                                    data_mem_out <= pushpcexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= pushpcexe;
                                end
                                `exe_addsp : begin
                                    tos <= addspexe;
                                    data_mem_out <= addspexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= addspexe;
                                end    
                                `exe_lessthen : begin
                                    nos <= datain;
                                    tos <= lessthenexe;
                                    data_mem_out <= lessthenexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= lessthenexe;
                                end
                                `exe_ulessthen : begin
                                    nos <= datain;
                                    tos <= ulessthenexe;
                                    data_mem_out <= ulessthenexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= ulessthenexe;
                                end                            
                                `exe_eq : begin
                                    nos <= datain;
                                    tos <= eqexe;
                                    data_mem_out <= eqexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= eqexe;
                                end
                                `exe_sub : begin
                                    nos <= datain;
                                    tos <= subexe;
                                    data_mem_out <= subexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_enable <= 1;
                                    data_mem_wmask <= 4'hf;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= subexe;
                                end                            
                                `exe_neqbench : begin
                                    nos <= datain;
                                    if(nos != 0)begin
                                        newpc <= pcrelexe;
                                        flush <= 1;
                                    end
                                end
                                `exe_pushspadd : begin
                                    tos <= pushspaddexe;
                                    data_mem_out <= pushspaddexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= pushspaddexe;
                                end
                                `exe_callrel : begin
                                    newpc <= pcrelexe;
                                    flush <= 1;                                
                                    tos <= pushpcexe;
                                    data_mem_out <= pushpcexe;
                                    data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                                    data_mem_wmask <= 4'hf;
                                    data_mem_enable <= 1;
                                    laststore[0] <= 1;
                                    laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                                    laststoreddat[0] <= pushpcexe;
                                end
                                `exe_mul : begin
                                    nos <= datain;
                                    state <= `statemul;
                                end                            
                                                                                                                                                                                                            
                                `exe_loadb : begin
                                    nextloadstate <= `stateload2b;
                                    if(tos[31:data_mem_start_bits] == 1)begin
                                        data_mem_adr <= tos[data_mem_start_bits-1:0];
                                        state <= `stateload;
                                        data_mem_enable <= 1;
                                        memorybusoperation <= 0;
                                    end
                                    else begin
                                        memorybusoperation <= 1;
                                        wb_adr <= tos;
                                        wb_sta <= wrmaskb[tos[1:0]];
                                        wb_wena <= 0;
                                        wb_stb <= 1;
                                        wb_cyc <= 1;
                                        state <= `stateload;
                                    end                                                    
                                end
                                `exe_storeb : begin
                                    nos <= datain;
                                    if(tos[31:data_mem_start_bits] == 1)begin
                                        data_mem_adr <= tos[data_mem_size_in_bits-1:0];
                                        data_mem_out <= {nos[7:0],nos[7:0],nos[7:0],nos[7:0]};
                                        data_mem_wmask <= wrmaskb[tos[1:0]];
                                        data_mem_enable <= 1;
                                        memorybusoperation <= 0;                                    
                                    end
                                    else begin
                                        memorybusoperation <= 1;
                                        wb_adr <= tos;
                                        wb_out <= {nos[7:0],nos[7:0],nos[7:0],nos[7:0]};
                                        wb_sta <= wrmaskb[tos[1:0]];
                                        wb_wena <= 1;
                                        wb_stb <= 1;
                                        wb_cyc <= 1;
                                    end
                                end
        
                                
                            endcase
                        end
                        `statemul : begin
                            state <= `statemul2;
                        end
                        `statemul2 : begin
                            tos <= multiplicationexeout;
                            data_mem_out <= multiplicationexeout;
                            data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                            data_mem_enable <= 1;
                            data_mem_wmask <= 4'hf;
                            laststore[0] <= 1;
                            laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];
                            laststoreddat[0] <= multiplicationexeout;
                            state <= `runstate_exec;
                        end
                        `stateload : begin //2nd stage of read operations wait for data ot bus
                            if(memorybusoperation == 1)begin
                                if(wb_stall == 0)begin
                                    state <= nextloadstate;
                                    lastbusop <= 1;
                                end
                                else begin
                                    wb_stb <= 1;
                                end
                                wb_stb <= disable_pipelined_wb;
                                wb_cyc <= 1;
                            end
                            else begin
                                state <= nextloadstate;
                            end                     
                        end
                        `stateload2 : begin //3rd stage of read operations
                            if(memorybusoperation == 0)begin
                                tos <= data_mem_in;
                                data_mem_out <= data_mem_in;
                                laststoreddat[0] <= data_mem_in;                          
                                data_mem_wmask <= 4'hf;
                                data_mem_enable <= 1;
                                laststore[0] <= 1;
                                state <= `runstate_exec;
                            end
                            else begin
                                tos <= wb_in;
                                data_mem_out <= wb_in;
                                laststoreddat[0] <= wb_in;
                                data_mem_wmask <= 4'hf;
                                data_mem_enable <= 1;
                                laststore[0] <= 1;
                                state <= `runstate_exec;
                            end
                            data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                            laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];                        
                        end
                        `stateload2b : begin //3rd stage of read operations
                            if(memorybusoperation == 0)begin
                                tos <= data_mem_inb[tos[1:0]];
                                data_mem_out <= data_mem_inb[tos[1:0]];
                                laststoreddat[0] <= data_mem_inb[tos[1:0]];                          
                                data_mem_wmask <= 4'hf;
                                data_mem_enable <= 1;
                                laststore[0] <= 1;
                                state <= `runstate_exec;
                            end
                            else begin
                                tos <= wb_inb[tos[1:0]];
                                data_mem_out <= wb_inb[tos[1:0]];
                                laststoreddat[0] <= wb_inb[tos[1:0]];
                                data_mem_wmask <= 4'hf;
                                data_mem_enable <= 1;
                                laststore[0] <= 1;
                                state <= `runstate_exec;
                            end
                            data_mem_adr <= destiny[data_mem_size_in_bits-1:0];
                            laststoredadr[0] <= destiny[data_mem_size_in_bits-1:2];                        
                        end
                    endcase
                end
            end
        end
    end
    
    
endmodule
