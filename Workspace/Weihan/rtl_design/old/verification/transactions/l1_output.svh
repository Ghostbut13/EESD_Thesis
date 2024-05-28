class l1_output extends uvm_transaction;
  `uvm_object_utils(l1_output)
  
  bit stall_pipeline = 0;
  
  int pending_entries = 0;
  
  function new(string name = "");
    super.new(name);
  endfunction : new

  function string convert2string();
    return $psprintf("stall: %h, pending_entries: %d", stall_pipeline, pending_entries);
  endfunction : convert2string

  function void do_copy(uvm_object rhs);
    l1_output RHS;
    super.do_copy(rhs);
    $cast(RHS,rhs);
    stall_pipeline = RHS.stall_pipeline;
    pending_entries = RHS.pending_entries;
  endfunction : do_copy

  function void load_data (bit s_p, int p_e);
    stall_pipeline = s_p;
    pending_entries = p_e;
  endfunction : load_data
  
endclass : l1_output
