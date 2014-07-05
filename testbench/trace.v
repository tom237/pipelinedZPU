`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/05/2014 04:05:18 PM
// Design Name: 
// Module Name: trace
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


module trace(
    input wire clk,
    input wire rst,
    input wire [136:0] dbg_i
    );
    
    wire[31:0] pc;
    wire[31:0] sp;
    wire[31:0] tos;
    wire[31:0] nos;
    wire[7:0] inst;
    wire valid_dbg;

    integer tracefile;
    
    assign pc = dbg_i[31:0]; //pc
    assign sp = dbg_i[63:32]; //sp
    assign tos = dbg_i[95:64]; //tos
    assign nos = dbg_i[127:96]; //nos
    assign inst = dbg_i[135:128]; //inst
    assign dbgok = dbg_i[136]; // valid data
    reg[31:0] counter;

    initial begin
        tracefile = $fopen("trace.log","w");
        $fwrite(tracefile,"#PC      Opcode    SP       A=[SP]    B=[SP+1]  Clk Counter\n");
        $fwrite(tracefile,"#----------------------------------------------------------\n");
        $fwrite(tracefile,"\n");
        counter <= 0;
    end
    
    always @ (posedge clk)begin
        if(rst == 1)begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
            if(dbgok == 1)begin
                $fwrite(tracefile,"0x%h     0x%h    0x%h    0x%h    0x%h    0x%h        \n",pc, inst, sp, tos, nos, counter);
            end
        end
    end
    
endmodule
