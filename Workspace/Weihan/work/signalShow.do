view signals all


# basic
add wave clk rstn

# input
add wave rx_opcode

# output
add wave tx_opcode trgID

# internal
add wave /HN_tb/HN/cnt_lc_rsp /HN_tb/HN/cnt_SnpResp_I
add wave /HN_tb/HN/lc_req /HN_tb/HN/lc_rsp /HN_tb/HN/lc_dat
add wave /HN_tb/HN/RX_RSPFLITPEND /HN_tb/HN/falling_edge_RespChannel
add wave /HN_tb/HN/coherency_state /HN_tb/HN/coherency_state_nxt





#find instance /HN_tb/* 

run 8000000 