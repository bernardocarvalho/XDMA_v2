# source after synth_design step
#Create the debug core
create_debug_core u_ila_0 ila
#set debug core properties
set_property C_DATA_DEPTH 8192   [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false   [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false  [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0   [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true    [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true  [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
#connect the probe ports in the debug core to the signals being probed in the design 
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list user_clk ]]

set_property port_width 1 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list s_axis_c2h_tready_0]] 
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list s_axis_c2h_tvalid_0]] 
create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list s_axis_c2h_tlast_0]]
create_debug_port u_ila_0 probe
set_property port_width 64 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list s_axis_c2h_tdata_0[*]]]

create_debug_port u_ila_0 probe
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list dma_rstn_i]]

create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 1 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list dma_ena_i]]

create_debug_port u_ila_0 probe
connect_debug_port u_ila_0/probe6 [get_nets [list state_i]]

create_debug_port u_ila_0 probe
set_property port_width 2 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list data_producer_inst/state[*]]]

create_debug_port u_ila_0 probe
connect_debug_port u_ila_0/probe8 [get_nets [list data_producer_inst/c2h_data_tlast]]

create_debug_port u_ila_0 probe
connect_debug_port u_ila_0/probe9 [get_nets [list data_producer_inst/c2h_data_tready]]

#source implement_non_project.tcl

#set_property port_width 1 [get_debug_ports u_ila_0/probe0]
#connect_debug_port u_ila_0/probe0 [get_nets [list m_axis_h2c_tready_0]] 
#create_debug_port u_ila_0 probe
#set_property port_width 1 [get_debug_ports u_ila_0/probe1]
#connect_debug_port u_ila_0/probe1 [get_nets [list m_axis_h2c_tvalid_0]] 
#create_debug_port u_ila_0 probe
#set_property port_width 1 [get_debug_ports u_ila_0/probe2]
#connect_debug_port u_ila_0/probe2 [get_nets [list m_axis_h2c_tlast_0]]

#create_debug_port u_ila_0 probe

#set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0]
#Optionally, create more probe ports, set their width,
# and connect them to the nets you want to debug
#Implement design

