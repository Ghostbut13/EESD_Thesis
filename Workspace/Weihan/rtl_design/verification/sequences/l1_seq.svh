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

class l1_seq extends uvm_sequence #(l1_req);

  `uvm_object_utils(l1_seq)

  l1_req req;
  int req_id;
  int vict_id;
  string m_loop_count;
  int l_loop_count;
  uvm_cmdline_processor inst;

  
  function new(string name = "l1_seq");
    super.new(name);

    inst = uvm_cmdline_processor::get_inst();
    
    l_loop_count = inst.get_arg_value("+loop_arg=",m_loop_count)?m_loop_count.atoi():100;
    
  endfunction: new

  task body();

  repeat (20000) begin
    `send_random_req_noarg
  end
  
     
  endtask: body

endclass: l1_seq
