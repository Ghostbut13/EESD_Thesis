import chi_package::*;
import llc_config_pkg::*; 
import llc_common_pkg::*; 

class driver;
   virtual chi_channel_inf #(request_flit_t).rx req_noc2hn_vif;
   virtual chi_channel_inf #(response_flit_t).rx rsp_noc2hn_vif;
   virtual chi_channel_inf #(data_flit_t).rx dat_noc2hn_vif;
   logic   clk;
   
   function new(
		virtual chi_channel_inf #(request_flit_t).rx req_noc2hn_vif,
		virtual chi_channel_inf #(response_flit_t).rx rsp_noc2hn_vif,
		virtual chi_channel_inf #(data_flit_t).rx dat_noc2hn_vif,
		logic 	clk
		);
      this.req_noc2hn_vif = req_noc2hn_vif;
      this.rsp_noc2hn_vif = rsp_noc2hn_vif;
      this.dat_noc2hn_vif = dat_noc2hn_vif;
      this.clk = clk; // Assign clk
   endfunction





   
   // TEST: 
   task drive_req_RN_READ_SHARED_HN();
      // RN0 -> READ_SHARED -> HN
      req_noc2hn_vif.flit.opcode <= REQ_LCRD_RETURN ;
      #200 req_noc2hn_vif.flit.opcode <= READ_SHARED;
      #50 req_noc2hn_vif.flit.opcode <= REQ_LCRD_RETURN ;
   endtask // drive_req_RN_READ_SHARED_HN


   task drive_rsp_pend_when_HN_waiting();
      rsp_noc2hn_vif.flit_pend <= 1;
      #600 rsp_noc2hn_vif.flit_pend <= 0;
      #50 rsp_noc2hn_vif.flit_pend <= 1;
      #100 rsp_noc2hn_vif.flit_pend <= 0;
      #50 rsp_noc2hn_vif.flit_pend <= 1;
      #100 rsp_noc2hn_vif.flit_pend <= 0;
      #50 rsp_noc2hn_vif.flit_pend <= 1;
   endtask // drive_rsp_pend_when_HN_waiting
   
   
   task drive_rsp_RNx_SNP_SHARED_HN();  
      // RN1-3 -> RESP -> HN
      rsp_noc2hn_vif.flit.opcode <= RESP_LCRD_RETURN;
      #600 rsp_noc2hn_vif.flit.opcode <= SNP_RESP;
      #50  rsp_noc2hn_vif.flit.opcode <= RESP_LCRD_RETURN;
      #100 rsp_noc2hn_vif.flit.opcode <= SNP_RESP;
      #50  rsp_noc2hn_vif.flit.opcode <= RESP_LCRD_RETURN;
      #100 rsp_noc2hn_vif.flit.opcode <= SNP_RESP;
      #50  rsp_noc2hn_vif.flit.opcode <= RESP_LCRD_RETURN;
   endtask // drive_rsp_RNx_SNP_SHARED_HN
   

   task drive_dat_SN_COMPDATA_HN();
      // SN -> DATA -> HN
      dat_noc2hn_vif.flit.opcode <= DATA_LCRD_RETURN;
      #1500 dat_noc2hn_vif.flit.opcode <= COMP_DATA;
      
   endtask // drive_dat_SN_COMP_HN
   
   task drive_rsp_RN_COMP_ACK_HN();
      // RN0 -> ACK -> HN
      rsp_noc2hn_vif.flit.opcode <= RESP_LCRD_RETURN; 
      #3000 rsp_noc2hn_vif.flit.opcode <= COMP_ACK; 
   endtask 
   
   

   task run();
      fork
	 drive_req_RN_READ_SHARED_HN();
	 drive_rsp_pend_when_HN_waiting();
	 drive_rsp_RNx_SNP_SHARED_HN();  
	 drive_dat_SN_COMPDATA_HN();
	 drive_rsp_RN_COMP_ACK_HN();
      join
   endtask
endclass
