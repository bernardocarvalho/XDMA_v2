###############################################################################
	#
	# project_create.tcl: Tcl script for implement the  project 
# Usage:
# source /home/Xilinx/Vivado/2017.4/settings64.sh
# vivado -mode batch -source project_implement.tcl 
#
#https://hwjedi.wordpress.com/2017/01/04/vivado-non-project-mode-the-only-way-to-go-for-serious-fpga-designers/
#
################################################################################

# Set the reference directory to where the script is
#set origin_dir [file dirname [info script]]
#cd $origin_dir
#
################################################################################
# install UltraFast Design Methodology from TCL Store
#################################################################################

tclapp::install -quiet ultrafast

#################################################################################
# define paths
################################################################################

set path_rtl hdl/design
set path_ip  ip
set path_sdc constrs
set path_out out

file mkdir $path_out

################################################################################
# setup the project
################################################################################

set part "xc7k325tffg900-2"

## Create project
create_project -in_memory -part $part
#create_project vivado_project "$origin_dir/vivado_project" -force -part $part

set_property board_part "xilinx.com:kc705:part0:1.5" [current_project]

################################################################################
# read files:
# 1. RTL design sources
# 2. IP database files (and generate IP files)
# 3. constraints
################################################################################

add_files                             $path_rtl
read_ip                               $path_ip/xdma_0/xdma_0.xci
read_ip                               $path_ip/fifo_axi_stream_0/fifo_axi_stream_0.xci

set_property top_file {$path_rtl/xilinx_dma_pcie_ep.sv} [current_fileset]

generate_target  {synthesis implementation instantiation_template} [get_ips]

read_xdc                          $path_sdc/xilinx_pcie_xdma_ref_board.xdc

################################################################################
# run synthesis
# report utilization and timing estimates
# write checkpoint design (open_checkpoint filename)
################################################################################

set_param general.maxThreads 8

synth_design -top xilinx_dma_pcie_ep
#synth_design -top red_pitaya_top -flatten_hierarchy none -bufg 16 -keep_equivalent_registers

write_checkpoint         -force   $path_out/post_synth
report_timing_summary    -file    $path_out/post_synth_timing_summary.rpt
report_power             -file    $path_out/post_synth_power.rpt

################################################################################
# insert debug core
# 
################################################################################

source debug_core.tcl

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




# Optional: to implement put on Tcl Console
# update_compile_order -fileset sources_1
# launch_runs impl_1 -to_step write_bitstream -jobs 4
#

#puts "INFO: Project created: vivado_project"


