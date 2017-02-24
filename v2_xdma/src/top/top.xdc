# Author: Andrzej Wojenski
# Modifications: Wojciech Zabolotny

create_clock -period 10.000 -name {sys_clk_clk_p[0]} -waveform {0.000 5.000} [get_ports {sys_clk_clk_p[0]}]

# Bank 116
set_property LOC GTPE2_CHANNEL_X1Y4 [get_cells {DMA_1/xdma_0/inst/DMA_core_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN E13 [get_ports {pcie_7x_mgt_rxn[0]}]
set_property LOC GTPE2_CHANNEL_X1Y5 [get_cells {DMA_1/xdma_0/inst/DMA_core_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[1].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN E15 [get_ports {pcie_7x_mgt_rxn[1]}]
set_property LOC GTPE2_CHANNEL_X1Y6 [get_cells {DMA_1/xdma_0/inst/DMA_core_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[2].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN C16 [get_ports {pcie_7x_mgt_rxn[2]}]
set_property LOC GTPE2_CHANNEL_X1Y7 [get_cells {DMA_1/xdma_0/inst/DMA_core_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[3].gt_wrapper_i/gtp_channel.gtpe2_channel_i}]
set_property PACKAGE_PIN E17 [get_ports {pcie_7x_mgt_rxn[3]}]

set_property PACKAGE_PIN H16 [get_ports {sys_clk_clk_p[0]}]
set_property LOC GTPE2_COMMON_X1Y1 [get_cells {DMA_1/xdma_0/inst/DMA_core_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/U0/inst/gt_top_i/pipe_wrapper_i/pipe_lane[0].pipe_quad.gt_common_enabled.gt_common_int.gt_common_i/qpll_wrapper_i/gtp_common.gtpe2_common_i}]

set_property PACKAGE_PIN AB1 [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS25 [get_ports sys_rst_n]

# SPI AFE link
# AFE_REG_CLK / DAC_SCK_B / A21 /
set_property PACKAGE_PIN AP29 [get_ports spi_clk_o]
set_property IOSTANDARD LVCMOS25 [get_ports spi_clk_o]

# AFE_REG_DAT/ DAC_DAT / A22
set_property PACKAGE_PIN AP30 [get_ports spi_mosi_o]
set_property IOSTANDARD LVCMOS25 [get_ports spi_mosi_o]

# AFE_REG_LATCH / DAC_SN_B / A23
set_property PACKAGE_PIN AP5 [get_ports spi_sel]
set_property IOSTANDARD LVCMOS25 [get_ports spi_sel]

# AFE_REG_DATA_OUT / DAC_SDO / A24
set_property PACKAGE_PIN AP6 [get_ports spi_miso_i]
set_property IOSTANDARD LVCMOS25 [get_ports spi_miso_i]

set_property PACKAGE_PIN AG1 [get_ports sel0]
set_property IOSTANDARD LVCMOS25 [get_ports sel0]

set_property PACKAGE_PIN AH1 [get_ports sel1]
set_property IOSTANDARD LVCMOS25 [get_ports sel1]

# Board ID
# pola12
set_property PACKAGE_PIN AM11 [get_ports {board_id[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {board_id[0]}]

# pola11
set_property PACKAGE_PIN AN11 [get_ports {board_id[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {board_id[1]}]

# pola10
set_property PACKAGE_PIN AM4 [get_ports {board_id[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {board_id[2]}]

# pola 9
set_property PACKAGE_PIN AL4 [get_ports {board_id[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {board_id[3]}]

# MLVDS pins
# FDE signals

set_property PACKAGE_PIN R8 [get_ports {mlvds_fde_o[0]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[0]}]

set_property PACKAGE_PIN T8 [get_ports {mlvds_fde_o[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[1]}]

set_property PACKAGE_PIN U2 [get_ports {mlvds_fde_o[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[2]}]

set_property PACKAGE_PIN U1 [get_ports {mlvds_fde_o[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[3]}]

set_property PACKAGE_PIN T7 [get_ports {mlvds_fde_o[4]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[4]}]

set_property PACKAGE_PIN U11 [get_ports {mlvds_fde_o[5]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[5]}]

set_property PACKAGE_PIN P10 [get_ports {mlvds_fde_o[6]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[6]}]

set_property PACKAGE_PIN R10 [get_ports {mlvds_fde_o[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {mlvds_fde_o[7]}]



