there is a core that implement most of the instuction exepted DIV and MOD in pipelined folder

there is a core that implement some instruction in pipelined.mid folder

most of the core tested wisbone wait and stall state not

for memory have to use xilinx block ram with blk_mem_gen_v7_3_0 name

startup folder contain modified gcc files copy them to zpugcc toolchain/gcc/libgloss/zpu
then complie gcc

crt0.s is very dirty because i just this way can get ride of a lot of nop instruction

this modification is reguired if you want use priority interrupt and POPINT instruction or comment them out in zpupkg.v if don't vant to use.
in pic_example folder there is a priority vectored interupt example

	-zpupkg.v (definitions for soc and core)

	-zpu_control (use this as top level when implement)
		-zpu_core.v (real toplevel)
			-wb_shared_bus.v
			-int_basic_perif.v
				-debug_serial.v
			-cpu_core.v
				-execution.v
				-regfetch.v
				-decode.v
				-steck.v
			-block ram with enable pins
		
zpu_tb.v is an easy testbanch to drive the soc in it have to implement trace 

zpuromgencoe is generate a .coe file from .bin for xilinx block ram generator
usage
zpuromgencoe input_file_name.bin output_file_name.coe

zpuromgen is generate a verilog file from .bin for program memory
zpuromgen input_file_name.bin output_file_name.v ram size
 
	TODO list:
		-optimalisazion for size
		-debug core
		-SRAM ctrl and caches
		-work on documentation
		-comment and test a header for core