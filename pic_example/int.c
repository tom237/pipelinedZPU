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

volatile int out;

/* Example of single, fixed interval non-maskable, nested interrupt. The interrupt signal is
 * held high for enough cycles to guarantee that it will be noticed, i.e. longer than
 * any io access + 4 cycles roughly.
 * 
 * Any non-trivial interrupt controller would have support for
 * acknowledging interrupts(i.e. keep interrupts asserted until
 * software acknowledges them via memory mapped IO).
 */
void  _zpu_interrupt(void)
{
	/* interrupts are enabled so we need to finish up quickly,
	 * lest we will get infinite recursion!*/
	puts("interrupt HI\n");
	out = out ^ 0x01;
	GPIO_DIR = out;
	TIMER_INT_FLEG = 1;
	INT_PRIO |= (1 << 29);
}

void  _zpu_interrupt_low(void)
{
	/* interrupts are enabled so we need to finish up quickly,
	 * lest we will get infinite recursion!*/
	puts("interrupt LOW\n");
	out = out ^ 0x02;
	GPIO_DIR = out;
	TIMER_INT_FLEG = 1;
	INT_PRIO &= ~(1 << 29);
}

int main(int argc, char **argv)
{
	int t;
	INT_GIE=1;

	


	TIMER_PERIOD=0x00ffffff;
	TIMER_INT_FLEG=0x03;
	TIMER_INT_EN=1;
	INT_GIE=0;
	while(1){
		out = out ^ 0x04;
	}
    
}
