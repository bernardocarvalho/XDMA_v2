###############################################################################
#
# project_create.tcl: Tcl script for implement the  project 
# Usage:
# source /home/Xilinx/Vivado/2017.4/settings64.sh
# vivado -mode batch -source ./synth_non_project.tcl 
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

source ./implement_non_project.tcl
# exit



