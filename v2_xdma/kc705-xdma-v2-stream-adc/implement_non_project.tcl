###############################################################################
#
# project_create.tcl: Tcl script for implement the  project 
# Usage:
# source /home/Xilinx/Vivado/2017.4/settings64.sh
# vivado -mode batch -source ./implement_non_project.tcl 
#

set path_out out

################################################################################
# run placement and logic optimization
# report utilization and timing estimates
# write checkpoint design
################################################################################

opt_design
power_opt_design
place_design
phys_opt_design
write_checkpoint         -force   $path_out/post_place
report_timing_summary    -file    $path_out/post_place_timing_summary.rpt
#write_hwdef              -file    $path_sdk/red_pitaya.hwdef

################################################################################
# run router
# report actual utilization and timing,
# write checkpoint design
# run drc, write verilog and xdc out
################################################################################

route_design
write_checkpoint         -force   $path_out/post_route
report_timing_summary    -file    $path_out/post_route_timing_summary.rpt
report_timing            -file    $path_out/post_route_timing.rpt -sort_by group -max_paths 100 -path_type summary
report_clock_utilization -file    $path_out/clock_util.rpt
report_utilization       -file    $path_out/post_route_util.rpt
report_power             -file    $path_out/post_route_power.rpt
report_drc               -file    $path_out/post_imp_drc.rpt
report_io                -file    $path_out/post_imp_io.rpt
#write_verilog            -force   $path_out/bft_impl_netlist.v
#write_xdc -no_fixed_only -force   $path_out/bft_impl.xdc

xilinx::ultrafast::report_io_reg -verbose -file $path_out/post_route_iob.rpt

################################################################################
# generate a bitstream
################################################################################

write_debug_probes -force            $path_out/kc705.ltx

write_bitstream -force            $path_out/kc705.bit

close_project

#write_cfgmem -force -format MCS -size 256 -interface SPIx4 -loadbit "up 0x0 $path_out/kc705.bit" -verbose $path_out/kc705.mcs

exit

