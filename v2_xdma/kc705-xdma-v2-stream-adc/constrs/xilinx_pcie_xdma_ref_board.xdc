##-----------------------------------------------------------------------------
##
## (c) Copyright 2012-2012 Xilinx, Inc. All rights reserved.
##
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
##
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
##
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
##
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES.
##
##-----------------------------------------------------------------------------
##
## Project    : The Xilinx PCI Express DMA
## File       : xilinx_pcie_xdma_ref_board.xdc
## Version    : 4.0
##-----------------------------------------------------------------------------
#
###############################################################################
# User Configuration
# Link Width   - x4
# Link Speed   - gen1
# Family       - kintex7
# Part         - xc7k325t
# Package      - ffg900
# Speed grade  - -2
# PCIe Block   - X0Y0

###############################################################################
#
#########################################################################################################################
# User Constraints
#########################################################################################################################

###############################################################################
# User Time Names / User Time Groups / Time Specs
###############################################################################
create_clock -period 10.000 -name sys_clk [get_ports sys_clk_p]

set_false_path -from [get_ports sys_rst_n]

#IMPLEMENTATION critical warning 
#[Vivado 12-4739] set_false_path:No valid object(s) found for '-through [get_pins xdma_0_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*]'. ["/home/bernardo/XDMA/GIT/XDMA_v2/v2_xdma/kc705-xdma-v2-stream-adc/constrs/xilinx_pcie_xdma_ref_board.xdc":79]
set_false_path -through [get_pins xdma_0_i/inst/pcie3_ip_i/inst/pcie3_uscale_top_inst/pcie3_uscale_wrapper_inst/PCIE_3_1_inst/CFGMAX*]
set_false_path -through [get_nets xdma_0_i/inst/cfg_max*]

################################################################################
#### KC705 200 MHz input clk
################################################################################
set_property IOSTANDARD LVDS [get_ports clk_200_*]
#set_property IOSTANDARD LVDS [get_ports Clk200_N]
set_property PACKAGE_PIN AD12 [get_ports clk_200_p]
set_property PACKAGE_PIN AD11 [get_ports clk_200_n]

create_clock -name clk_200 -period 5.00 [get_ports clk_200_p]

###############################################################################
# User Physical Constraints
###############################################################################

###############################################################################
# Pinout and Related I/O Constraints
###############################################################################


###############################################################################
# Pinout and Related I/O Constraints
###############################################################################
##### SYS RESET###########
set_property PACKAGE_PIN G25 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]
set_property LOC IBUFDS_GTE2_X0Y1 [get_cells refclk_ibuf]

set_property IOSTANDARD LVCMOS15 [get_ports led_0]
set_property IOSTANDARD LVCMOS15 [get_ports led_1]
set_property IOSTANDARD LVCMOS15 [get_ports led_2]
set_property IOSTANDARD LVCMOS15 [get_ports led_3]

set_property PACKAGE_PIN AB8 [get_ports led_0]
set_property PACKAGE_PIN AA8 [get_ports led_1]
set_property PACKAGE_PIN AC9 [get_ports led_2]
# USER CLK HEART BEAT = led_3
set_property PACKAGE_PIN AB9 [get_ports led_3]

set_property IOSTANDARD LVCMOS25 [get_ports led_4]
set_property IOSTANDARD LVCMOS25 [get_ports led_5]
set_property IOSTANDARD LVCMOS25 [get_ports led_6]
set_property IOSTANDARD LVCMOS25 [get_ports led_7]
set_property PACKAGE_PIN AE26 [get_ports led_4]
set_property PACKAGE_PIN G19 [get_ports led_5]
set_property PACKAGE_PIN E18 [get_ports led_6]
set_property PACKAGE_PIN F16 [get_ports led_7]

######################################################################
#DEBUG CORES
# XILINX UG936 (v2017.2)
# https://forums.xilinx.com/t5/Vivado-TCL-Community/Probing-in-Vivado/td-p/331293
###########################
#create_debug_core  u_ila_0 ila
#set_property       C_DATA_DEPTH     8192  [get_debug_cores u_ila_0]
#set_property       port_width 1     [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk      [get_nets [list user_clk]]

#set_property       port_width 1     [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0   [get_nets [list m_axis_h2c_tready_0]]

#create_debug_core u_ila_0 ila
#set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
#set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
#set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
#set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
#set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
#set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
#set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
#set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
#set_property port_width 1 [get_debug_ports u_ila_0/clk]
#connect_debug_port u_ila_0/clk [get_nets [list xdma_0_i/inst/xdma_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/CLK]]
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
#set_property port_width 64 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list {m_axis_h2c_tdata_0[0]} {m_axis_h2c_tdata_0[1]} {m_axis_h2c_tdata_0[2]} {m_axis_h2c_tdata_0[3]} {m_axis_h2c_tdata_0[4]} {m_axis_h2c_tdata_0[5]} {m_axis_h2c_tdata_0[6]} {m_axis_h2c_tdata_0[7]} {m_axis_h2c_tdata_0[8]} {m_axis_h2c_tdata_0[9]} {m_axis_h2c_tdata_0[10]} {m_axis_h2c_tdata_0[11]} {m_axis_h2c_tdata_0[12]} {m_axis_h2c_tdata_0[13]} {m_axis_h2c_tdata_0[14]} {m_axis_h2c_tdata_0[15]} {m_axis_h2c_tdata_0[16]} {m_axis_h2c_tdata_0[17]} {m_axis_h2c_tdata_0[18]} {m_axis_h2c_tdata_0[19]} {m_axis_h2c_tdata_0[20]} {m_axis_h2c_tdata_0[21]} {m_axis_h2c_tdata_0[22]} {m_axis_h2c_tdata_0[23]} {m_axis_h2c_tdata_0[24]} {m_axis_h2c_tdata_0[25]} {m_axis_h2c_tdata_0[26]} {m_axis_h2c_tdata_0[27]} {m_axis_h2c_tdata_0[28]} {m_axis_h2c_tdata_0[29]} {m_axis_h2c_tdata_0[30]} {m_axis_h2c_tdata_0[31]} {m_axis_h2c_tdata_0[32]} {m_axis_h2c_tdata_0[33]} {m_axis_h2c_tdata_0[34]} {m_axis_h2c_tdata_0[35]} {m_axis_h2c_tdata_0[36]} {m_axis_h2c_tdata_0[37]} {m_axis_h2c_tdata_0[38]} {m_axis_h2c_tdata_0[39]} {m_axis_h2c_tdata_0[40]} {m_axis_h2c_tdata_0[41]} {m_axis_h2c_tdata_0[42]} {m_axis_h2c_tdata_0[43]} {m_axis_h2c_tdata_0[44]} {m_axis_h2c_tdata_0[45]} {m_axis_h2c_tdata_0[46]} {m_axis_h2c_tdata_0[47]} {m_axis_h2c_tdata_0[48]} {m_axis_h2c_tdata_0[49]} {m_axis_h2c_tdata_0[50]} {m_axis_h2c_tdata_0[51]} {m_axis_h2c_tdata_0[52]} {m_axis_h2c_tdata_0[53]} {m_axis_h2c_tdata_0[54]} {m_axis_h2c_tdata_0[55]} {m_axis_h2c_tdata_0[56]} {m_axis_h2c_tdata_0[57]} {m_axis_h2c_tdata_0[58]} {m_axis_h2c_tdata_0[59]} {m_axis_h2c_tdata_0[60]} {m_axis_h2c_tdata_0[61]} {m_axis_h2c_tdata_0[62]} {m_axis_h2c_tdata_0[63]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
#set_property port_width 8 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list {m_axis_h2c_tkeep_0[0]} {m_axis_h2c_tkeep_0[1]} {m_axis_h2c_tkeep_0[2]} {m_axis_h2c_tkeep_0[3]} {m_axis_h2c_tkeep_0[4]} {m_axis_h2c_tkeep_0[5]} {m_axis_h2c_tkeep_0[6]} {m_axis_h2c_tkeep_0[7]}]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
#set_property port_width 1 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list dma_ena_i]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
#set_property port_width 1 [get_debug_ports u_ila_0/probe3]
#connect_debug_port u_ila_0/probe3 [get_nets [list dma_rstn_i]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
#set_property port_width 1 [get_debug_ports u_ila_0/probe4]
#connect_debug_port u_ila_0/probe4 [get_nets [list m_axis_h2c_tlast_0]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
#set_property port_width 1 [get_debug_ports u_ila_0/probe5]
#connect_debug_port u_ila_0/probe5 [get_nets [list m_axis_h2c_tready_0]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
#set_property port_width 1 [get_debug_ports u_ila_0/probe6]
#connect_debug_port u_ila_0/probe6 [get_nets [list m_axis_h2c_tvalid_0]]
#create_debug_port u_ila_0 probe
#set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
#set_property port_width 1 [get_debug_ports u_ila_0/probe7]
#connect_debug_port u_ila_0/probe7 [get_nets [list user_clk]]
#set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
#set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
#set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
#connect_debug_port dbg_hub/clk [get_nets user_clk]
