//import uvm_pkg::*;
//import llc_hn_sim_pkg::*; 
import chi_package::*;
import llc_config_pkg::*; 
import llc_common_pkg::*; 


module top; 

   logic clk,rstn;
   
   chi_channel_inf #(request_flit_t)       req_noc2hn_if(); 
   chi_channel_inf #(response_flit_t)      rsp_noc2hn_if(); 
   chi_channel_inf #(data_flit_t)          dat_noc2hn_if(); 
   chi_channel_inf #(request_flit_t)       req_hn2noc_if();
   chi_channel_inf #(response_flit_t)      rsp_hn2noc_if();
   chi_channel_inf #(data_flit_t)          dat_hn2noc_if();
   chi_channel_inf #(snoop_flit_t)         snp_hn2noc_if();
   
   //clk_rst_interface 			   clk_rst_intf();

   HN_controller dut(
    	       .clk(clk),
    	       .rstn(rstn),
    	       .rx_req(req_noc2hn_if.rx),
    	       .rx_rsp(rsp_noc2hn_if.rx),
    	       .rx_dat(dat_noc2hn_if.rx),
    	       .tx_req(req_hn2noc_if.tx), 
    	       .tx_rsp(rsp_hn2noc_if.tx), 
    	       .tx_dat(dat_hn2noc_if.tx),
    	       .tx_snp(snp_hn2noc_if.tx)
	       );
   
/* -----\/----- EXCLUDED -----\/-----
   initial begin 
      llc_hn_sim_pkg::global_clk_rst_if    = clk_rst_intf; 
      llc_hn_sim_pkg::global_req_noc2hn_if = req_noc2hn_if;
      llc_hn_sim_pkg::global_rsp_noc2hn_if = rsp_noc2hn_if;
      llc_hn_sim_pkg::global_dat_noc2hn_if = dat_noc2hn_if;
      llc_hn_sim_pkg::global_req_hn2noc_if = req_hn2noc_if;
      llc_hn_sim_pkg::global_rsp_hn2noc_if = rsp_hn2noc_if;
      llc_hn_sim_pkg::global_dat_hn2noc_if = dat_hn2noc_if;
      llc_hn_sim_pkg::global_snp_hn2noc_if = snp_hn2noc_if;

      run_test(); 
   end
 -----/\----- EXCLUDED -----/\----- */
     
   initial begin
      clk = 1'b0;
      forever begin
	 #CLK_2_5 clk = ~clk;
      end
   end

   initial begin
      rstn = 1'b1;
      #2 rstn = 1'b0;
      #4 rstn = 1'b1;
   end


   
   /*****************************************/
   initial begin
      #1 rx_opcode = 0;
      #200 rx_opcode = ReadShared;
      #50 rx_opcode = 0;
   end 


/* -----\/----- EXCLUDED -----\/-----
   initial begin
      #600 rx_opcode = SnpResp_I;
      #50 rx_opcode = rx_BLANK;
      #100 rx_opcode = SnpResp_I;
      #50 rx_opcode = rx_BLANK;
      #100 rx_opcode = SnpResp_I;
      #50 rx_opcode = rx_BLANK;
   end 
 -----/\----- EXCLUDED -----/\----- */
   
   initial begin
      #1 RX_RSPFLITPEND = 1;

      #600 RX_RSPFLITPEND = 0;
      #50 RX_RSPFLITPEND = 1;
      #100 RX_RSPFLITPEND = 0;
      #50 RX_RSPFLITPEND = 1;
      #100 RX_RSPFLITPEND = 0;
      #50 RX_RSPFLITPEND = 1;
   end

   initial begin
      #1500 rx_opcode = CompData_I;

      #1500 rx_opcode = CompAck;
      
   end

   initial begin
      #2000000 $stop;
      
   end
endmodule
