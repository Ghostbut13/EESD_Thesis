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

class l1_seq3 extends l1_seq;

  `uvm_object_utils(l1_seq3)

  function new(string name = "l1_seq3");
    super.new(name);
  endfunction: new

  function logic [L1C_ADDR_WIDTH-1:0] get_rand_addr(logic [L1C_INDEX_WIDTH-1:0] index); 
    logic [L1C_TAG_WIDTH-1:0] tag = $urandom(); 
    logic [L1C_OFFSET-1:0]    offset = $urandom(); 
    return {tag, index, offset}; 
  endfunction: get_rand_addr

  task do_clean_clean_scen(); 
    // both HN and RN clean
    logic [L1C_INDEX_WIDTH-1:0] index = $urandom();
    logic [L1C_ADDR_WIDTH-1:0]  addr1 = get_rand_addr(index);
    logic [L1C_ADDR_WIDTH-1:0]  addr2 = get_rand_addr(index);
    
    `send_req(load,0,addr1)
    `send_req(load,0,addr2)
  endtask

  task do_dirty_clean_scen(); 
    // RN dirty, HN clean
    logic [L1C_INDEX_WIDTH-1:0] index = $urandom();
    logic [L1C_ADDR_WIDTH-1:0]  addr1 = get_rand_addr(index);
    logic [L1C_ADDR_WIDTH-1:0]  addr2 = get_rand_addr(index);
    
    `send_req(load,0,addr1)
    `send_req(store,0,addr1)
    `send_req(load,0,addr2)
  endtask

  task do_clean_dirty_scen(); 
    // RN clean, HN dirty
    logic [L1C_INDEX_WIDTH-1:0] index = $urandom();
    logic [L1C_ADDR_WIDTH-1:0]  addr1 = get_rand_addr(index);
    logic [L1C_ADDR_WIDTH-1:0]  addr2 = get_rand_addr(index);
    
    `send_req(load,0,addr1)
    `send_req(store,0,addr1)
    `send_req(evict,0,addr1)
    `send_req(load,0,addr1)
    `send_req(load,0,addr2)
  endtask

  task do_dirty_dirty_scen(); 
    // RN drity, HN dirty
    logic [L1C_INDEX_WIDTH-1:0] index = $urandom();
    logic [L1C_ADDR_WIDTH-1:0]  addr1 = get_rand_addr(index);
    logic [L1C_ADDR_WIDTH-1:0]  addr2 = get_rand_addr(index);
    
    `send_req(load,0,addr1)
    `send_req(store,0,addr1)
    `send_req(evict,0,addr1)
    `send_req(load,0,addr1)
    `send_req(store,0,addr1)

    `send_req(load,0,addr2)
  endtask
  
  task body();

    int i = 0;

    `uvm_info(get_type_name(), $psprintf("addr_width: %d index width: %d tag width: %d offset width: %d", L1C_ADDR_WIDTH, L1C_INDEX_WIDTH, L1C_TAG_WIDTH, L1C_OFFSET),500);

    #20;

    repeat (1000) begin
      int r = $urandom()%4; 
      //$display("SeqScen: %d", r);
      case(r) 
        0 : do_clean_clean_scen; 
        1 : do_clean_dirty_scen; 
        2 : do_dirty_clean_scen; 
        3 : do_dirty_dirty_scen;
      endcase 
    end
    

    // clear out all the instructions from core internal queues
    `send_req(fence,0,'h50)

    // work-around so that test doesn't finish before all the queues have been emptied
    repeat(50) begin
      `send_req(evict,0,'h90)
    end

  endtask: body

endclass: l1_seq3
