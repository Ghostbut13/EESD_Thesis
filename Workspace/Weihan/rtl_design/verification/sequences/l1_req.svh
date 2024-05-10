class l1_req extends uvm_sequence_item;

  `uvm_object_utils(l1_req)
  
   rand l1_op_e op;
   rand int core_id;
   rand logic [L1C_ADDR_WIDTH-1:0] addr;
   rand logic [L1C_DATA_WIDTH-1:0] data;
   
   
   constraint core_id_c {core_id >= 0; core_id < NUM_SIM_CORES;};
//   constraint op_c {op inside {load, store, evict, nop};};
   //constraint addr_c {addr[13:6] == 8'b0000_0000;};
  
  function new();
    super.new();
  endfunction : new

  function string convert2string();
    return $psprintf("op: %s core_id: %0h addr: %0h", 
                            op.name(), core_id, addr);
  endfunction : convert2string

  function void do_copy(uvm_object rhs);
    l1_req  RHS;
    super.do_copy(rhs);
    $cast(RHS, rhs);
    op = RHS.op;
    core_id = RHS.core_id;
    addr = RHS.addr;
    data = RHS.data;
  endfunction : do_copy

  function void load_l1_req(l1_op_e l1_op, int coreid, logic [L1C_ADDR_WIDTH-1:0] l1_addr, logic [L1C_DATA_WIDTH-1:0] l1_data);
  
    op = l1_op;
    core_id = coreid;
    addr = l1_addr;
    data = l1_data;
  endfunction
  
endclass : l1_req
