#*****************************************************************************
# This script is used to synthesize the fir filter, basic structure
#*****************************************************************************
#preserve name netlist
set power_preserve_rtl_hier_name true
#analyze all the used files
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/reg.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/MUX_4to1.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/Adder.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/mult.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/fir_package.vhd}
analyze -library WORK -format vhdl {/home/isa25/Desktop/lab1/fir_basic/src/fir.vhd}
#elaborate the top entity
elaborate fir -architecture behavioral -library WORK
#****************** CONSTRAINT THE SYNTHESIS (timing) ***********************
# create a clock signal to constraint the sequential paths
set WCP 17.8
create_clock -name "CLOCK" -period $WCP CLK
set_dont_touch_network CLOCK
#clock uncertainty
set_clock_uncertainty 0.07 [get_clocks CLOCK]
#verify the correct creation of the clock
report_clock > clock_test.rpt
#input delay
set_input_delay 0.5 -max -clock CLOCK [remove_from_collection [all_inputs] CLK]
#max output delay
set_output_delay 0.5 -max -clock CLOCK [all_outputs]
# output load
set OUT_LOAD [load_of NangateOpenCellLibrary/BUF_X4/A]
set_load $OUT_LOAD [all_outputs]
#compile  
compile
#timing, area and power report
report_timing > post_syn_timing.rpt
report_area > post_syn_area.rpt
report_power > post_syn_power.rpt
# #****************** generation file ***********************
ungroup -all -flatten
change_names -hierarchy -rules verilog

write_sdf post_syn_fir.sdf
write -f verilog -hierarchy -output post_syn_fir.v
write_sdc post_syn_fir.sdc
