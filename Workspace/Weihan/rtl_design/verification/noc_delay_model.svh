class noc_delay_model extends uvm_component;
  `uvm_component_utils(noc_delay_model)
  
   uvm_get_port #(req_trans)     req_rn2nocdelay_port_i;

   uvm_put_port #(req_trans)     req_nocdelay2noc_port_o;
   
   int src_id = 0;
   
   function new (string name, uvm_component parent, int id = 0);
      super.new(name,parent);
      src_id = id;
   endfunction : new
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      req_nocdelay2noc_port_o = new("req_nocdelay2noc_port_o",this);
      req_rn2nocdelay_port_i = new("req_rn2nocdelay_port_i",this);
   endfunction: build_phase

   task run_phase(uvm_phase phase);
      handle_l1_req;
   endtask : run_phase
   
   task handle_l1_req;
     req_trans l1_req;
      forever begin
        req_trans l2_req_cln;
        req_rn2nocdelay_port_i.get(l1_req);
        l1_req.req_flit.src_id = src_id;
        for(int i=0;i<src_id;i++)
          #40;
        $cast(l2_req_cln, l1_req.clone());
        req_nocdelay2noc_port_o.put(l2_req_cln);
          
      end // forever loop
   
   endtask : handle_l1_req
   
endclass : noc_delay_model

