#ifndef pipelZPU
#define pipelZPU

//------------------------------------------------------ interrupt ------------------------------------

#define GLOBAL_INTERRUPT_MASK_REG *(volatile unsigned int *) 0x080a0020
#define GIE 0x3
#define GIEH 0x1
#define GIEL 0x2

#define INTERRUPT_PRIORITY_MASK_REG *(volatile unsigned int *) 0x080a001c
#define TIMER_INT_PRI 0x00000001
#define UART_RX_INT_PRI 0x00000002 
#define UART_TX_INT_PRI 0x00000004
#define INT3_INT_PRI 0x00000008
#define INT4_INT_PRI 0x00000010
#define INT5_INT_PRI 0x00000020
#define INT6_INT_PRI 0x00000040
#define INT7_INT_PRI 0x00000080
#define INT8_INT_PRI 0x00000100
#define INT9_INT_PRI 0x00000200
#define INT10_INT_PRI 0x00000400
#define INT11_INT_PRI 0x00000800
#define INT12_INT_PRI 0x00001000
#define INT13_INT_PRI 0x00002000
#define INT14_INT_PRI 0x00004000
#define INT15_INT_PRI 0x00008000
#define INT16_INT_PRI 0x00010000
#define INT17_INT_PRI 0x00020000
#define INT18_INT_PRI 0x00040000
#define INT19_INT_PRI 0x00080000
#define INT20_INT_PRI 0x00100000
#define INT21_INT_PRI 0x00200000
#define INT22_INT_PRI 0x00400000
#define INT23_INT_PRI 0x00800000
#define INT24_INT_PRI 0x01000000
#define INT25_INT_PRI 0x02000000
#define INT26_INT_PRI 0x04000000
#define INT27_INT_PRI 0x08000000
#define INT28_INT_PRI 0x10000000
#define INT29_INT_PRI 0x20000000
#define INT30_INT_PRI 0x40000000
#define INT31_INT_PRI 0x80000000

#define Enable_Master_INT() GLOBAL_INTERRUPT_MASK_REG = ~GIE
#define Disable_Master_INT() GLOBAL_INTERRUPT_MASK_REG = GIE
#define INT_Priority_Set_Low(INT) INTERRUPT_PRIORITY_MASK_REG |= INT
#define INT_Priority_Set_High(INT) INTERRUPT_PRIORITY_MASK_REG &= ~INT
#define INT_Priority_Status() INTERRUPT_PRIORITY_MASK_REG

//------------------------------------------------------ countr ------------------------------------

#define COUNTER1_REG *(volatile unsigned int *) 0x080a0014
#define COUNTER_RESET 0x1
#define COUNTER_SAMPLE 0x1

#define COUNTER2_REG *(volatile unsigned int *) 0x080a0018

#define Counter_Set(ctr) COUNTER1_REG = ctr
#define Counter_Read_Low() COUNTER1_REG
#define Counter_Read_High() COUNTER2_REG
#define Counter_Read() _readCycles()

//------------------------------------------------------ timer ------------------------------------

#define TIMER_INERRUPT_ENABLE_REG *(volatile unsigned int *) 0x080a002c
#define TIMER_INT_ENABLE 0x1

#define TIMER_INTERRUPT_REG *(volatile unsigned int *) 0x080a0030
#define TIMER_INT_FLEG 0x1
#define TIMER_RESET 0x2

#define TIMER_PERIOD_REG *(volatile unsigned int *) 0x080a0034

#define TIMER_COUNTER_REG *(volatile unsigned int *) 0x080a0038

#define Timer_Enable_INT() TIMER_INERRUPT_ENABLE_REG = TIMER_INT_ENABLE
#define Timer_Disable_INT() TIMER_INERRUPT_ENABLE_REG = 0
#define Timer_Reset() TIMER_INTERRUPT_REG = TIMER_RESET
#define Timer_INT_Satatus() TIMER_INTERRUPT_REG
#define Timer_INT_Clear() TIMER_INTERRUPT_REG = TIMER_INT_FLEG
#define Timer_Set_Period(prd) TIMER_PERIOD_REG = prd
#define Timer_Value() TIMER_COUNTER_REG 
//------------------------------------------------------ GPIO ------------------------------------

#define GPIO_DATA_REG *(volatile unsigned int *) 0x080a0004

#define GPIO_DIRECTION_REG *(volatile unsigned int *) 0x080a0008

#define GPIO_PIN0 0x00000001
#define GPIO_PIN1 0x00000002
#define GPIO_PIN2 0x00000004
#define GPIO_PIN3 0x00000008
#define GPIO_PIN4 0x00000010
#define GPIO_PIN5 0x00000020
#define GPIO_PIN6 0x00000040
#define GPIO_PIN7 0x00000080
#define GPIO_PIN8 0x00000100
#define GPIO_PIN9 0x00000200
#define GPIO_PIN10 0x00000400
#define GPIO_PIN11 0x00000800
#define GPIO_PIN12 0x00001000
#define GPIO_PIN13 0x00002000
#define GPIO_PIN14 0x00004000
#define GPIO_PIN15 0x00008000
#define GPIO_PIN16 0x00010000
#define GPIO_PIN17 0x00020000
#define GPIO_PIN18 0x00040000
#define GPIO_PIN19 0x00080000
#define GPIO_PIN20 0x00100000
#define GPIO_PIN21 0x00200000
#define GPIO_PIN22 0x00400000
#define GPIO_PIN23 0x00800000
#define GPIO_PIN24 0x01000000
#define GPIO_PIN25 0x02000000
#define GPIO_PIN26 0x04000000
#define GPIO_PIN27 0x08000000
#define GPIO_PIN28 0x10000000
#define GPIO_PIN29 0x20000000
#define GPIO_PIN30 0x40000000
#define GPIO_PIN31 0x80000000

#define GPIO_Set_Output_Raw(dir) GPIO_DIRECTION_REG = ~dir
#define GPIO_Set_Input_Raw(dir) GPIO_DIRECTION_REG = dir
#define GPIO_Set_Output(mask, dir) GPIO_DIRECTION_REG &= ~(dir & mask)
#define GPIO_Set_Input(mask, dir) GPIO_DIRECTION_REG |= (dir & mask)
#define GPIO_Read_raw() GPIO_DATA_REG
#define GPIO_Read(mask) (GPIO_DATA_REG & mask)
#define GPIO_Write_Raw(dat) GPIO_DATA_REG = dat
#define GPIO_Write(mask ,dat) GPIO_DATA_REG = (GPIO_DATA_REG & (~mask)) | dat

//------------------------------------------------------ UART ------------------------------------

#define UART_TX_REG *(volatile unsigned int *) 0x080a000c
#define BUFFER_READY 0x100

#define UART_RX_REG *(volatile unsigned int *) 0x080a000c
#define BUFFER_VALID 0x100

#define UART_INTERRUPT_ENABLE_REG *(volatile unsigned int *) 0x080a0024
#define UART_RX_INTERRUPT 0x1
#define UART_TX_INTERRUPT 0x2

#define UART_INTERRUPT_REG *(volatile unsigned int*) 0x080a0028
#define UART_RX_FLEG 0x1
#define UART_TX_FLEG 0x2

#define UART_INT_Enable(int) UART_INTERRUPT_ENABLE_REG |= int
#define UART_INT_Disable(int) UART_INTERRUPT_ENABLE_REG &= ~int
#define UART_INT_Status() UART_INTERRUPT_REG
#define UART_INT_Clear(int) UART_INTERRUPT_REG = int
#define UART_Write(dat) outbyte(dat)
#define UART_Read() inbyte() // blocking
#define UART_Read_NoBlock() inbyte_noblock() // non blocking

#endif pipelZPU
