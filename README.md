most of the core tested wisbone wait and stall state not

for memory have to use xilinx block ram with blk_mem_gen_v7_3_0 name

startup folder contain modified gcc files copy them to zpugcc toolchain/gcc/libgloss/zpu
then complie gcc
this modification is reguired if you want use priority interrupt and POPINT instruction

	-zpupkg.v (definitions for soc)

-zpu_control (use this as top level when implement)
	-zpu_core.v
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

zpuromcoegen is generate a .coe file from .bin for xilinx block ram generator
usage
zpuromcoegen <input file name>.bin <output file name>.coe
