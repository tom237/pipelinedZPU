`timescale 1ns / 1ps

module steck(
    input wire clk,
    input wire[3:0] wea,
    input wire[31:0] dina,
    input wire ena,
    output reg[31:0] douta,
    input wire[31:0] addra,
    
    output reg[31:0] doutb,
    input wire enb,
    input wire[31:0] addrb
);

    //simle write first dual port ram

    parameter data_mem_size_in_bits = 10;
    parameter data_size = (1 << data_mem_size_in_bits) - 1;

    reg[31:0] RAM[data_size:0];

    always @ (posedge clk)begin
        if(ena == 1)begin
              if(wea[0] == 1)begin
                 douta[7:0] <= dina[7:0];
                 RAM[addra[data_mem_size_in_bits+1:2]][7:0] <= dina[7:0];
              end
              else begin
                 douta[7:0] <= RAM[addra[data_mem_size_in_bits+1:2]][7:0]; 
              end
              
              if(wea[1] == 1)begin
                 douta[15:8] <= dina[15:8];
                 RAM[addra[data_mem_size_in_bits+1:2]][15:8] <= dina[15:8];
              end
              else begin
                 douta[15:8] <= RAM[addra[data_mem_size_in_bits+1:2]][15:8]; 
              end
              
              if(wea[2] == 1)begin
                 douta[23:16] <= dina[23:16];
                 RAM[addra[data_mem_size_in_bits+1:2]][23:16] <= dina[23:16];
              end
              else begin
                 douta[23:16] <= RAM[addra[data_mem_size_in_bits+1:2]][23:16]; 
              end
                            
              if(wea[3] == 1)begin
                 douta[31:24] <= dina[31:24];
                 RAM[addra[data_mem_size_in_bits+1:2]][31:24] <= dina[31:24];
              end
              else begin
                 douta[31:24] <= RAM[addra[data_mem_size_in_bits+1:2]][31:24]; 
              end
              
        end
   end

    always @ (posedge clk)begin
        if(enb == 1)begin
              doutb <= RAM[addrb[data_mem_size_in_bits+1:2]];
        end
    end
endmodule