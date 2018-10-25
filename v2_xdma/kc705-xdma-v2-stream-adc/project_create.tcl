###############################################################################
#
# project_create.tcl: Tcl script for creating the VIVADO project 
# Usage:
# Open Vivado IDE 2017.4
# Menu Tools->Run Tcl Script-> (this file)
################################################################################

# Set the reference directory to where the script is
set origin_dir [file dirname [info script]]

cd $origin_dir
#
################################################################################
# define paths
################################################################################

set path_rtl hdl/design
set path_ip  ip
set path_sdc constrs

################################################################################
# setup the project
################################################################################

set part "xc7k325tffg900-2"

## Create project
create_project vivado_project "$origin_dir/vivado_project" -force -part $part

#set obj [current_project]
## set_property -name "board_part" -value "xilinx.com:kc705:part0:1.5" -objects $obj
#set_property -name "board_part" -value "xilinx.com:kc705:part0:1.5" [current_project]
set_property board_part "xilinx.com:kc705:part0:1.5" [current_project]

################################################################################
# read files:
# 1. RTL design sources
# 2. IP database files (and generate IP files)
# 3. constraints
################################################################################

add_files                             $path_rtl
#read_ip                               $path_ip/dcm_200/dcm_200.xci
read_ip                               $path_ip/xdma_0/xdma_0.xci
read_ip                               $path_ip/fifo_axi_stream_0/fifo_axi_stream_0.xci

set_property top_file {$path_rtl/xilinx_dma_pcie_ep.sv} [current_fileset]

generate_target  {synthesis implementation instantiation_template} [get_ips]

read_xdc                          $path_sdc/xilinx_pcie_xdma_ref_board.xdc

# Optional: to implement put on Tcl Console
# update_compile_order -fileset sources_1
# launch_runs impl_1 -to_step write_bitstream -jobs 4
#

puts "INFO: Project created: vivado_project"


