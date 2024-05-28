// =============================================================================
//
//            Copyright (c) 2019 CHALMERS University of Technology
//                             All rights reserved
//
// This file contains CHALMERS proprietary and confidential information 
// and has been developed by CHALMERS within the EPI-SGA1 Project (GA 826647). 
// The permission rights for this file are governed by the EPI Grant Agreement 
// and the EPI Consortium Agreement.
//
// ===============================[ INFORMATION ]===============================
//
// Author(s)  : Bhavishya Goel and Madhavan Manivannan
// Contact(s) : goelb@chalmers.se, madhavan@chalmers.se
//
// Summary    : HN UVM test sequence
// Created    : 14/10/2019
// Modified   : 29/08/2022
//
// ===============================[ DESCRIPTION ]===============================
//
// HN UVM test sequence
//
// =============================================================================

class l1_seq1 extends l1_seq;

  `uvm_object_utils(l1_seq1)

  function new(string name = "l1_seq1");
    super.new(name);
  endfunction: new

  task body();
  
    int i = 0;
    
    `uvm_info(get_type_name(), $psprintf("addr_width: %d index width: %d tag width: %d offset width: %d", L1C_ADDR_WIDTH, L1C_INDEX_WIDTH, L1C_TAG_WIDTH, L1C_OFFSET),500);
    
    #20; 
    // -----  Clean Data in RN
    `send_req(load,0,'h50)
    `send_req(evict, 0,'h50)
    `send_req(load,0,'h50)
    
    // ----- Updated Data in RN
    `send_req(store,0,'h50)

    // ----- Clean Victim with SNP_RESP_DATA
    `send_req(load,0,'h100050)
    `send_req(evict, 0,'h100050)
    `send_req(load,0,'h100050)

    // ----- Clean Victim with SNP_RESP
    `send_req(load,0,'h50)
    `send_req(evict, 0,'h50)
    

    /*
    i=0;
    repeat (100) begin
      `send_random_req({op==load;addr[L1C_ADDR_WIDTH-1:L1C_IDXOFFSET_WIDTH]==i;addr[L1C_IDXOFFSET_WIDTH-1:L1C_OFFSET_WIDTH]==L1C_INDEX_WIDTH'(11110000);core_id==0;})
      i++;
    end
    */
    
    // clear out all the instructions from core internal queues
    `send_req(fence,0,'h50)

    // work-around so that test doesn't finish before all the queues have been emptied
    repeat(50) begin
      `send_req(evict,0,'h90)
    end
     
  endtask: body

endclass: l1_seq1
