//decode unit
`define enable_POPINT 1 // enable POPINT instuction
`define enable_priority_int 1 //enable interrupt priority in interrupt controller will be 1 hight and 1 low priority interrupt

`define enable_itc 1 // enable interrupt controler
`define enable_64b_timer 1 // enable 64bit timer forclock measurement perfieria
`define enable_sys_timer 1 // enable system down counter/timer perfieria
`define enable_gpio 1 // enable gpio perfieria
`define enable_uart 1 // enable uart perfieria    

`define interruptadr 8'h20
`define interruptadr_low 8'h28

`define inst_IM 1
`define inst_STORESP 2'b10
`define inst_LOADSP 2'b11
`define inst_EMULATE 2'b01
`define inst_ADDSP 1
`define inst_POPPC 4'b0100
`define inst_LOAD 4'b1000
`define inst_STORE 4'b1100
`define inst_PUSHSP 4'b0010
`define inst_POPSP 4'b1101
`define inst_ADD 4'b0101
`define inst_AND 4'b0110
`define inst_OR 4'b0111
`define inst_NOT 4'b1001
`define inst_FLIP 4'b1010
`define inst_NOP 4'b1011
`define inst_BREAK 4'b0000
`define inst_POPINT 4'b0011

`define inst_LOADH 2
`define inst_STOREH 3
`define inst_LESSTHEN 4
`define inst_LESSTHENOREQUAL 5
`define inst_ULESSTHEN 6
`define inst_ULESSTHENOREQUAL 7
//`define inst_SWAP 8
`define inst_MULT 9
`define inst_LSHIFTRIGHT 10
`define inst_ASHIFTLEFT 11
`define inst_ASHIFTRIGHT 12
`define inst_CALL 13
`define inst_EQ 14
`define inst_NEQ 15
`define inst_NEG 16
`define inst_SUB 17
`define inst_XOR 18
`define inst_LOADB 19
`define inst_STOREB 20
//`define inst_DIV 21
//`define inst_MOD 22
`define inst_EQBRANCH 23
`define inst_NEQBRANCH 24
`define inst_POPPCREL 25
//`define inst_CONFIG 26
`define inst_PUSHPC 27
//`define inst_SYSCALL 28
`define inst_PUSHSPADD 29
//`define inst_HALFMUL 30
`define inst_CALLREL 31

//prefetch unit
`define runstate_pref 0
`define pref_store 1
`define pref_popsp 2
`define pref_popsp2 3
`define pref_branch 4

`define tos_sp_source 2
`define inc_sp_source 0
`define offset_sp_source 1
`define stay_sp_source 3

`define inc_sp 0
`define dec_sp 1
`define tos_sp 2
`define stay_sp 3

`define exe_popsp 6

// execution unit
`define exe_storesp 0 
`define exe_storesp1 1
`define exe_storesp2 2
`define exe_store 3
`define exe_storeb 4
`define exe_storeh 5 
`define exe_store2 6
`define exe_loadsp 7
`define exe_load 8
`define exe_nop 9
`define exe_poppc 10
`define exe_mov 11
`define exe_and 12
`define exe_or 13
`define exe_add 14
`define exe_addsp 15
`define exe_not 16
`define exe_im0 17
`define exe_imn 18
`define exe_flip 19 
`define exe_pushsp 20
`define exe_pushpc 21
`define exe_loadb 22
`define exe_loadh 23
`define exe_lessthen 24
`define exe_lessthenoreq 25
`define exe_ulessthen 26
`define exe_ulessthenoreq 27
`define exe_lshiftright 28
`define exe_ashiftleft 29
`define exe_ashiftright 30
`define exe_call 31
`define exe_eq 32
`define exe_neq 33
`define exe_neg 34
`define exe_sub 35
`define exe_xor 36
`define exe_eqbench 37
`define exe_neqbench 38
`define exe_poppcrel 39
`define exe_pushspadd 40
`define exe_callrel 41
`define exe_mul 42

`define runstate_exec 0

`define stateload 2
`define stateload2 3 
`define stateload2b 4
`define stateload2h 5
`define statemul 6
`define statemul2 7

//interrupt controler
`define sysgiereg 8
`define systimervalue 14
`define systimermax 13
`define systimerintf 12
`define systimerinte 11
`define counterl 5
`define counterh 6
`define uartintf 10
`define uartinte 9 
`define uarttx 3
`define uartrx 4
`define gpiodata 1
`define gpiodir 2
`define boudrate 15 
`define intpriobegin 7

`define counterreset 0
`define countersample 1
`define systimerintenable 0
`define systimerreset 1
`define systimerintfleg 0
`define uartrxintf 0
`define uarttxintf 1
`define uartrxinte 0
`define uarttxinte 1

`define gie 0
