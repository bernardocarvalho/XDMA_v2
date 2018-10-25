###############################################################################
#
# program_fpga.tcl: Tcl script for programming bit file
# Usage:
# source /home/Xilinx/Vivado/2017.4/settings64.sh
# vivado -mode tcl -source program_fpga.tcl
#
#https://www.xilinx.com/support/documentation/sw_manuals/xilinx2014_4/ug908-vivado-programming-debugging.pdf
#http://eng.umb.edu/~cuckov/classes/engin341/Labs/Debug%20Tutorial/Vivado%20Debugging%20Tutorial.pdf
#
################################################################################
open_hw

# Connect to the Digilent Cable on localhost:3121

connect_hw_server -url localhost:3121
#refresh_hw_server
#current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210203341302A]
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/2102033*]
open_hw_target

# Program and Refresh the XC7K325T Device

#set bit_file "vivado_project/vivado_project.runs/impl_1/xilinx_dma_pcie_ep.bit"
current_hw_device [get_hw_devices xc7k325t_1]
#[lindex [get_hw_devices] 0]
refresh_hw_device -update_hw_probes false [get_hw_devices xc7k325t_1]
#[lindex [get_hw_devices] 0]
#set_property PROGRAM.FILE $bit_file [lindex [get_hw_devices] 0]
#set_property PROGRAM.FILE {out/kc705.bit} [lindex [get_hw_devices] 0]
set_property PROGRAM.FILE {out/kc705.bit} [get_hw_devices xc7k325t_1]
#set_property PROBES.FILE  {out/kc705.ltx} [lindex [get_hw_devices] 0]
 
program_hw_devices [get_hw_devices xc7k325t_1]
refresh_hw_device [get_hw_devices xc7k325t_1]
#program_hw_devices [lindex [get_hw_devices] 0]
#refresh_hw_device [lindex [get_hw_devices] 0]

# exit

