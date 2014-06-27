#include <unistd.h>
#include <stdio.h>
#include <limits.h>
#include <sys/types.h>
#include <fcntl.h>


int main(int argc, char **argv)
{
	u_int8_t    opcode[4];
	int     fr;
	FILE    *fw;
	int linenumber;
	ssize_t s;

	if(argc != 3)
	{
		printf("Usage: %s <binary_file> <coe_file>\n\n", argv[0]);
		return 1;
	}
	fr = open(argv[1], 0);
	fw = fopen(argv[2], "w");
	fprintf(fw,"; Sample memory initialization file for Dual Port Block Memory,\n"); 
	fprintf(fw,";\n"); 
	fprintf(fw,"; This .COE file specifies the contents for a block memory\n"); 
	fprintf(fw,"; of depth=512, and width=8.  In this case, values are specified\n"); 
	fprintf(fw,"; in hexadecimal format. \n");
	fprintf(fw,"memory_initialization_radix=16;\n"); 
	fprintf(fw,"memory_initialization_vector= \n");
	if(fr == -1)
	{
		printf("unable to input open file");
		return 2;
	}
	if(fw == NULL){
		printf("unable to output open file");
		return 3;
	}
	linenumber = 1;
	while(1)
	{
		linenumber=linenumber+4;
		s = read(fr, opcode, 4);
		if(s == -1)
		{
			printf("error");
			return 4;
		}
		
		if(s == 0){
			break;
		}	       
		fprintf(fw,"%02x%02x%02x%02x,\n",opcode[0], opcode[1],
                        opcode[2], opcode[3]);
	}
	fprintf(fw,"00000000;\n");
	fclose(fw);
	close(fr);
	printf("\n program size %d byte greater rom required\n",linenumber);
	return 0;
}

