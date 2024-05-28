class l1_input extends uvm_transaction;
  `uvm_object_utils(l1_input)
  
  l1_op_e op;
  logic [L1C_ADDR_WIDTH-1:0] addr;
  logic [L1C_DATA_WIDTH-1:0] data;
  int src_id;
  
  function new(string name = "");
    super.new(name);
  endfunction : new

  function string convert2string();
    return $psprintf("op: %s addr: %0h",op.name(), addr);
  endfunction : convert2string

  function void do_copy(uvm_object rhs);
    l1_input RHS;
    super.do_copy(rhs);
    $cast(RHS,rhs);
    op = RHS.op;
    addr = RHS.addr;
    data = RHS.data;
    src_id = RHS.src_id;
    
  endfunction : do_copy

   function bit comp (uvm_object rhs);
      l1_input RHS;
      $cast (RHS,rhs);
      return ((RHS.op == op) && (RHS.addr == addr) && (RHS.data == data) && (RHS.src_id == src_id));
   endfunction : comp


  function void load_data (l1_op_e l1_op, logic [L1C_ADDR_WIDTH-1:0] l1_addr, logic [L1C_DATA_WIDTH-1:0] l1_data,int l1_id);
    op = l1_op;
    addr = l1_addr;
    data = l1_data;
    src_id = l1_id;
  endfunction : load_data
  
endclass : l1_input
