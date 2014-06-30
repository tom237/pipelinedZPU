/*
 * Shows usage of interrupts. Goes along with zpu_core_small_wip.vhd.
 */
#include <stdio.h>

#define GPIO_DIR    *(volatile unsigned int *) 0x080a0008
#define INT_PRIO    *(volatile unsigned int *) 0x080a001c
#define INT_GIE    *(volatile unsigned int *) 0x080a0020
#define TIMER_INT_EN    *(volatile unsigned int *) 0x080a002c
#define TIMER_INT_FLEG    *(volatile unsigned int *) 0x080a0030
#define TIMER_PERIOD    *(volatile unsigned int *) 0x080a0034
#define UARTRX    *(volatile unsigned int *) 0x080a0010
#define UARTTX    *(volatile unsigned int *) 0x080a000c
#define UART_INT_FLEG    *(volatile unsigned int *) 0x080a0028
#define UART_INT_EN    *(volatile unsigned int *) 0x080a0024

void  _zpu_interrupt(void)
{
	/* interrupts are enabled so we need to finish up quickly,
	 * lest we will get infinite recursion!*/
//	puts("interrupt HI\n");
	INT_GIE = 3;
	while(1);

}

void  muhaha(void);
void varj(void);
void echo(void);

const void *_vector_table_base[32] = {
	muhaha,        //32  bit system timer
	echo,		//uart rx
	_zpu_interrupt,	//uart tx
	varj,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
	_zpu_interrupt,
};

volatile int out;

/* Example of single, fixed interval non-maskable, nested interrupt. The interrupt signal is
 * held high for enough cycles to guarantee that it will be noticed, i.e. longer than
 * any io access + 4 cycles roughly.
 * 
 * Any non-trivial interrupt controller would have support for
 * acknowledging interrupts(i.e. keep interrupts asserted until
 * software acknowledges them via memory mapped IO).
 */

void varj(void){
	TIMER_INT_FLEG = 1;	
}

void  muhaha(void)
{
	puts("\ninterrupt timer\n");
	TIMER_INT_FLEG = 1;
	//INT_PRIO ^= (1 << 29);
}

void echo(void){
	//INT_PRIO ^= (1 << 30);
	while((UARTTX & 0x100) == 0);
	UARTTX = UARTRX & 0xff;
	UART_INT_FLEG = 1;
}

//void  _zpu_interrupt_low(void)
//{
	/* interrupts are enabled so we need to finish up quickly,
	 * lest we will get infinite recursion!*/
//	puts("interrupt LOW\n");
//	out = out ^ 0x02;
//	GPIO_DIR = out;
//	TIMER_INT_FLEG = 1;
//	INT_PRIO &= ~(1 << 29);
//}

int main(int argc, char **argv)
{
	int t;
	INT_GIE=3;

	


	TIMER_PERIOD=0x03ffffff;
	TIMER_INT_FLEG=0x03;
	TIMER_INT_EN=1;
	UART_INT_EN = 1;
	INT_PRIO = 1; 
	
	INT_GIE=0;
	while(1){
	}
    
}
