view signals all


# basic
add wave clk rstn

# input
#add wave -position insertpoint  sim:/top/drv
add wave -position end  /top/req_noc2hn_if/flit.opcode
add wave -position end  /top/rsp_noc2hn_if/flit.opcode
add wave -position end  /top/dat_noc2hn_if/flit.opcode
add wave -position end  /top/req_noc2hn_if/flit_pend
add wave -position end  /top/rsp_noc2hn_if/flit_pend
add wave -position end  /top/dat_noc2hn_if/flit_pend


# output
add wave       /top/req_hn2noc_if/flit.opcode 
add wave       /top/rsp_hn2noc_if/flit.opcode
add wave       /top/dat_hn2noc_if/flit.opcode
add wave       /top/snp_hn2noc_if/flit.opcode
# add wave trgID

# internal
add wave -position insertpoint /top/HN/cnt_lc_rsp
#add wave /top/HN/lc_req /top/HN/lc_rsp /top/HN/lc_dat
#add wave /top/HN/RX_RSPFLITPEND /top/HN/falling_edge_RespChannel
add wave /top/HN/coherency_state /top/HN/coherency_state_nxt
add wave /top/HN/cnt_SNP_RESP

#find instance /HN_tb/* 

run 8000000 