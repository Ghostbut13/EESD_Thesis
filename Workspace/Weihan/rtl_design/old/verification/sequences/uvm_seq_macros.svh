// Testbench Macros

`define send_req(OP,CORE_ID,ADDR) \
  req = new(); \
  start_item(req); \
  req.op = OP; \
  req.core_id = CORE_ID; \
  req.addr = ADDR; \
  `uvm_info(get_type_name(), {"Sending transaction ",req.convert2string()}, 500); \
  finish_item(req);

`define send_req_with_data(OP,CORE_ID,ADDR,DATA) \
  req = new(); \
  start_item(req); \
  req.op = OP; \
  req.core_id = CORE_ID; \
  req.addr = ADDR; \
  req.data = DATA; \
  `uvm_info(get_type_name(), {"Sending transaction ",req.convert2string()}, 500); \
  finish_item(req);

`define send_random_req(EXPR) \
  req = new(); \
  start_item(req); \
  assert(req.randomize() with EXPR); \
  `uvm_info(get_type_name(), {"Sending transaction ",req.convert2string()}, 500); \
  finish_item(req);

`define send_random_req_noarg \
  req = new(); \
  start_item(req); \
  assert(req.randomize()); \
  `uvm_info(get_type_name(), {"Sending transaction ",req.convert2string()}, 500); \
  finish_item(req);

