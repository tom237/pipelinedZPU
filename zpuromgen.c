// compile with gcc zpuromgen.c -o zpuromgen -lm
#include <unistd.h>
#include <stdio.h>
#include <limits.h>
#include <sys/types.h>
#include <fcntl.h>
#include <math.h>

int main(int argc, char **argv)
{
	u_int8_t    opcode[4];
	int     fr;
	FILE    *fw;
	int linenumber;
	ssize_t s;
	int romsize;
	int program_size;
	int ram_size_in_bits;
	
	if(argc != 4)
	{
		printf("Usage: %s <binary_file> <verilog_file> <size>\n\n", argv[0]);
		return 1;
	}
	
	
	fr = open(argv[1], 0);
	fw = fopen(argv[2], "w");
	romsize = atoi(argv[3]);
	
	if(fr == -1)
	{
		printf("unable to input open file");
		return 2;
	}
	if(fw == NULL){
		printf("unable to output open file");
		return 3;
	}
	
	ram_size_in_bits = ceil(log2((double)romsize));
	romsize = romsize / 4; 
	printf("ram bit size: %d\n",ram_size_in_bits);
	
	fprintf(fw,"`timescale 1ns / 1ps\n");
	fprintf(fw,"`define data_mem_size_in_bits %d\n",ram_size_in_bits);
	fprintf(fw,"\nmodule memory(\n");
	fprintf(fw,"    input wire clk,\n"); 
	fprintf(fw,"    input wire[3:0] wea,\n"); 
	fprintf(fw,"    input wire[31:0] dina,\n"); 
	fprintf(fw,"    input wire ena,\n"); 
	fprintf(fw,"    output reg[31:0] douta,\n"); 
	fprintf(fw,"    input wire[31:0] addra,\n"); 
	
	fprintf(fw,"\n    output reg[31:0] doutb,\n");
	fprintf(fw,"    input wire[3:0] web,\n"); 
	fprintf(fw,"    input wire[31:0] dinb,\n"); 
	fprintf(fw,"    input wire enb,\n"); 
	fprintf(fw,"    input wire[31:0] addrb\n");
	fprintf(fw,");\n\n\n"); 
	
	fprintf(fw,"    reg[31:0] RAM[%d:0];\n",romsize);
	
	fprintf(fw,"\n    initial begin\n"); 
	linenumber = 0;
	while(1)
	{
		s = read(fr, opcode, 4);
		if(s == -1)
		{
			printf("error");
			return 4;
		}
		
		if(s == 0){
			break;
		}	       
		fprintf(fw,"        RAM[%d] = 32'h%02x%02x%02x%02x;\n",linenumber ,opcode[0], opcode[1],
                        opcode[2], opcode[3]);
		linenumber++;
	}
	program_size = linenumber * 4;
	while(linenumber < romsize){
		fprintf(fw,"        RAM[%d] = 32'h00000000;\n",linenumber);
		linenumber++;
	}
	fprintf(fw,"    end\n");
	
	fprintf(fw,"\n    always @ (posedge clk)begin\n"); 
	fprintf(fw,"        if(ena == 1)begin\n"); 
	fprintf(fw,"              if(wea[0] == 1)begin\n");
	fprintf(fw,"                 douta[7:0] <= dina[7:0];\n");
	fprintf(fw,"                 RAM[addra[`data_mem_size_in_bits-1:2]][7:0] <= dina[7:0];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 douta[7:0] <= RAM[addra[`data_mem_size_in_bits-1:2]][7:0];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(wea[1] == 1)begin\n");
	fprintf(fw,"                 douta[15:8] <= dina[15:8];\n");
	fprintf(fw,"                 RAM[addra[`data_mem_size_in_bits-1:2]][15:8] <= dina[15:8];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 douta[15:8] <= RAM[addra[`data_mem_size_in_bits-1:2]][15:8];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(wea[2] == 1)begin\n");
	fprintf(fw,"                 douta[23:16] <= dina[23:16];\n");
	fprintf(fw,"                 RAM[addra[`data_mem_size_in_bits-1:2]][23:16] <= dina[23:16];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 douta[23:16] <= RAM[addra[`data_mem_size_in_bits-1:2]][23:16];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(wea[3] == 1)begin\n");
	fprintf(fw,"                 douta[31:24] <= dina[31:24];\n");
	fprintf(fw,"                 RAM[addra[`data_mem_size_in_bits-1:2]][31:24] <= dina[31:24];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 douta[31:24] <= RAM[addra[`data_mem_size_in_bits-1:2]][31:24];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n        end\n");
	fprintf(fw,"   end\n");
	
	fprintf(fw,"\n    always @ (posedge clk)begin\n"); 
	fprintf(fw,"        if(enb == 1)begin\n"); 
	fprintf(fw,"              if(web[0] == 1)begin\n");
	fprintf(fw,"                 doutb[7:0] <= dinb[7:0];\n");
	fprintf(fw,"                 RAM[addrb[`data_mem_size_in_bits-1:2]][7:0] <= dinb[7:0];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 doutb[7:0] <= RAM[addrb[`data_mem_size_in_bits-1:2]][7:0];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(web[1] == 1)begin\n");
	fprintf(fw,"                 doutb[15:8] <= dinb[15:8];\n");
	fprintf(fw,"                 RAM[addrb[`data_mem_size_in_bits-1:2]][15:8] <= dinb[15:8];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 doutb[15:8] <= RAM[addrb[`data_mem_size_in_bits-1:2]][15:8];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(web[2] == 1)begin\n");
	fprintf(fw,"                 doutb[23:16] <= dinb[23:16];\n");
	fprintf(fw,"                 RAM[addrb[`data_mem_size_in_bits-1:2]][23:16] <= dinb[23:16];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 doutb[23:16] <= RAM[addrb[`data_mem_size_in_bits-1:2]][23:16];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n              if(web[3] == 1)begin\n");
	fprintf(fw,"                 doutb[31:24] <= dinb[31:24];\n");
	fprintf(fw,"                 RAM[addrb[`data_mem_size_in_bits-1:2]][31:24] <= dinb[31:24];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"              else begin\n");
	fprintf(fw,"                 doutb[31:24] <= RAM[addrb[`data_mem_size_in_bits-1:2]][31:24];\n");
	fprintf(fw,"              end\n");
	fprintf(fw,"\n        end\n");
	fprintf(fw,"   end\n");
	
	fprintf(fw,"endmodule\n");

	fclose(fw);
	close(fr);
	printf("\nrom generated at %s the rom size is %d\n",argv[2], program_size);
	return 0;
}

