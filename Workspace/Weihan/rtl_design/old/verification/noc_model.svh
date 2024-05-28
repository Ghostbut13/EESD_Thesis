class noc_ref_model extends uvm_agent;
  `uvm_component_utils(noc_ref_model)
   
   // RN ports
   uvm_get_port #(req_trans)     req_rn2noc_port_i[NUM_SIM_CORES-1:0];
   uvm_get_port #(rsp_trans)     rsp_rn2noc_port_i[NUM_SIM_CORES-1:0];
   uvm_get_port #(dat_trans)     dat_rn2noc_port_i[NUM_SIM_CORES-1:0];
 
   uvm_put_port #(rsp_trans)     rsp_noc2rn_port_o[NUM_SIM_CORES-1:0];
   uvm_put_port #(dat_trans)     dat_noc2rn_port_o[NUM_SIM_CORES-1:0];
   uvm_put_port #(snp_trans)     snp_noc2rn_port_o[NUM_SIM_CORES-1:0];

   //SN ports
   uvm_get_port #(dat_trans)     dat_sn2noc_port_i;
   uvm_get_port #(rsp_trans)     rsp_sn2noc_port_i;

   uvm_put_port #(req_trans)     req_noc2sn_port_o;
   uvm_put_port #(dat_trans)     dat_noc2sn_port_o;

   //HN ports
   uvm_put_port #(req_trans)     req_noc2hn_port_o;
   uvm_put_port #(rsp_trans)     rsp_noc2hn_port_o;
   uvm_put_port #(dat_trans)     dat_noc2hn_port_o;
   
   uvm_get_port #(req_trans)     req_hn2noc_port_i;
   uvm_get_port #(rsp_trans)     rsp_hn2noc_port_i;
   uvm_get_port #(dat_trans)     dat_hn2noc_port_i;
   uvm_get_port #(snp_trans)     snp_hn2noc_port_i;

   uvm_tlm_fifo #(req_trans)     req_nocdelay2noc_fifo[NUM_SIM_CORES-1:0];
   
   noc_delay_model delay_model[NUM_SIM_CORES-1:0];

   semaphore rsp_noc2hn_port_sema;
   semaphore dat_noc2hn_port_sema;

   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      req_noc2hn_port_o = new("req_noc2hn_port_o",this);
      rsp_noc2hn_port_o = new("rsp_noc2hn_port_o",this);
      dat_noc2hn_port_o = new("dat_noc2hn_port_o",this);
      rsp_hn2noc_port_i = new("rsp_hn2noc_port_i",this);
      dat_hn2noc_port_i = new("dat_hn2noc_port_i",this);
      snp_hn2noc_port_i = new("snp_hn2noc_port_i",this);
      req_hn2noc_port_i = new("req_hn2noc_port_i", this);
      
      dat_sn2noc_port_i = new("dat_sn2noc_port_i", this);
      rsp_sn2noc_port_i = new("rsp_sn2noc_port_i", this);
      req_noc2sn_port_o = new("req_noc2sn_port_o", this);
      dat_noc2sn_port_o = new("dat_noc2sn_port_o", this);
      
      for (int i=0;i<NUM_SIM_CORES;i++) begin

        req_nocdelay2noc_fifo[i] = new($psprintf("req_nocdelay2noc_fifo_%0d", i),this);

        req_rn2noc_port_i[i] = new($psprintf("req_rn2noc_port_i_%0d", i), this);
        rsp_rn2noc_port_i[i] = new($psprintf("rsp_rn2noc_port_i_%d", i),this);

        dat_rn2noc_port_i[i] = new($psprintf("dat_rn2noc_port_i_%d", i),this);
        rsp_noc2rn_port_o[i] = new($psprintf("rsp_noc2rn_port_o_%d", i),this);
        dat_noc2rn_port_o[i] = new($psprintf("dat_noc2rn_port_o_%d", i),this);
        snp_noc2rn_port_o[i] = new($psprintf("snp_noc2rn_port_o_%d", i),this);
        
        delay_model[i]  = new($psprintf("delay_model_%d", i),this,i);
      end

      rsp_noc2hn_port_sema = new(1);
      dat_noc2hn_port_sema = new(1);
      
   endfunction: build_phase
   
   function void connect_phase(uvm_phase phase);

      for(int i=0;i<NUM_SIM_CORES;i++) begin
        
        //Delay Model<->NOC connections
        delay_model[i].req_nocdelay2noc_port_o.connect(req_nocdelay2noc_fifo[i].put_export);
        req_rn2noc_port_i[i].connect(req_nocdelay2noc_fifo[i].get_export);

      end
   endfunction : connect_phase

   task run_phase(uvm_phase phase);
      fork
        handle_rn_req;
        handle_rn_rsp;
        handle_rn_dat;

        handle_hn_req;
        handle_hn_rsp;
        handle_hn_dat;
        handle_hn_snp;

        handle_sn_rsp;
        handle_sn_dat;
      join
   endtask : run_phase
   
   task handle_rn_req;
     req_trans rn_req [NUM_SIM_CORES-1:0];
      forever begin
        req_trans rn_req_cln;
        for(int i=0;i<NUM_SIM_CORES;i++) begin
          if(req_rn2noc_port_i[i].try_get(rn_req[i])) begin  
            `uvm_info (get_type_name(), $psprintf("handle_rn_req: Core %d RN req %s",i, rn_req[i].convert2string()),500);
          
            $cast(rn_req_cln, rn_req[i].clone());
            req_noc2hn_port_o.put(rn_req_cln);
            `uvm_info (get_type_name(),{"handle_rn_req sent: ", rn_req_cln.convert2string()},500);
            
          end else begin
            #1;
          end // if l1_received
        end // NUM_SIM_CORES loop
      end // forever loop
   
   endtask : handle_rn_req

   task handle_rn_rsp;
     rsp_trans rn_rsp [NUM_SIM_CORES-1:0];
      forever begin
        rsp_trans rn_rsp_cln;
        for(int i=0;i<NUM_SIM_CORES;i++) begin
          if(rsp_rn2noc_port_i[i].try_get(rn_rsp[i])) begin
            `uvm_info (get_type_name(), $psprintf("handle_rn_rsp: Core %d RN rsp %s",i, rn_rsp[i].convert2string()),500);
            rn_rsp[i].rsp_flit.src_id = i;
          
            $cast(rn_rsp_cln, rn_rsp[i].clone());
            rsp_noc2hn_port_sema.get();
            rsp_noc2hn_port_o.put(rn_rsp_cln);
            rsp_noc2hn_port_sema.put();
            `uvm_info (get_type_name(),{"handle_rn_rsp sent: ", rn_rsp_cln.convert2string()},500);
            
          end else begin
            #1;
          end // if l1_received
        end // NUM_SIM_CORES loop
      end // forever loop
   
   endtask : handle_rn_rsp

   task handle_rn_dat;
     dat_trans rn_dat [NUM_SIM_CORES-1:0];
      forever begin
        dat_trans rn_dat_cln;
        for(int i=0;i<NUM_SIM_CORES;i++) begin
          if(dat_rn2noc_port_i[i].try_get(rn_dat[i])) begin
            `uvm_info (get_type_name(), $psprintf("handle_rn_dat: Core %d RN dat %s",i, rn_dat[i].convert2string()),500);
            rn_dat[i].dat_flit.src_id = i;
          
            $cast(rn_dat_cln, rn_dat[i].clone());
            dat_noc2hn_port_sema.get();
            dat_noc2hn_port_o.put(rn_dat_cln);
            dat_noc2hn_port_sema.put();
            `uvm_info (get_type_name(),{"handle_rn_dat sent: ", rn_dat_cln.convert2string()},500);
            
          end else begin
            #1;
          end // if l1_received
        end // NUM_SIM_CORES loop
      end // forever loop
   
   endtask : handle_rn_dat

   task handle_hn_req;
     req_trans hn_req;
      forever begin
        req_trans hn_req_cln;
          if(req_hn2noc_port_i.try_get(hn_req)) begin
            `uvm_info (get_type_name(), $psprintf("handle_hn_req: HN req %s", hn_req.convert2string()),500);
          
            $cast(hn_req_cln, hn_req.clone());
            req_noc2sn_port_o.put(hn_req_cln);
            `uvm_info (get_type_name(),{"handle_hn_req sent: ", hn_req_cln.convert2string()},500);
            
          end else begin
            #1;
          end 
      end // forever loop
   endtask : handle_hn_req

   task handle_hn_rsp;
      rsp_trans hn_received;
      forever begin
        rsp_trans cln;
        rsp_hn2noc_port_i.get(hn_received);
        `uvm_info (get_type_name(),{"handle_hn_rsp: got ",hn_received.convert2string()},500);

        $cast(cln, hn_received.clone());
        rsp_noc2rn_port_o[hn_received.rsp_flit.tgt_id].put(cln);
        `uvm_info (get_type_name(),{"handle_hn_rsp: sent ",cln.convert2string()},500);

      end
   endtask : handle_hn_rsp
   
   task handle_hn_dat;
      dat_trans hn_received;
      forever begin
        dat_trans cln;
        dat_hn2noc_port_i.get(hn_received);
        `uvm_info (get_type_name(),{"handle_hn_dat: got ",hn_received.convert2string()},500);

        $cast(cln, hn_received.clone());
        if(hn_received.dat_flit.tgt_id < 32) begin 
          dat_noc2rn_port_o[hn_received.dat_flit.tgt_id].put(cln);
        end else begin 
          dat_noc2sn_port_o.put(cln);
        end
        // (MN) data target may be either SN or RN
        
        `uvm_info (get_type_name(),{"handle_hn_dat: sent ",cln.convert2string()},500);

      end
   endtask : handle_hn_dat
   
   task handle_hn_snp;
      snp_trans hn_received;
      forever begin
        snp_trans cln;
        snp_hn2noc_port_i.get(hn_received);
        `uvm_info (get_type_name(),{"handle_hn_snp: got ",hn_received.convert2string()},500);
        #100;
        $cast(cln, hn_received.clone());
        snp_noc2rn_port_o[hn_received.snp_flit.tgt_id].put(cln);
        
        `uvm_info (get_type_name(),{"handle_hn_snp: sent ",cln.convert2string()},500);

      end
   endtask : handle_hn_snp
   
   task handle_sn_rsp;
     rsp_trans sn_rsp;
      forever begin
        rsp_trans sn_rsp_cln;
          if(rsp_sn2noc_port_i.try_get(sn_rsp)) begin
            `uvm_info (get_type_name(), $psprintf("handle_sn_rsp: L1 rsp %s", sn_rsp.convert2string()),500);
          
            $cast(sn_rsp_cln, sn_rsp.clone());
            rsp_noc2hn_port_sema.get();
            rsp_noc2hn_port_o.put(sn_rsp_cln);
            rsp_noc2hn_port_sema.put();
            `uvm_info (get_type_name(),{"handle_sn_rsp sent: ", sn_rsp_cln.convert2string()},500);
            
          end else begin
            #1;
          end 
      end // forever loop
   
   endtask : handle_sn_rsp
   
   task handle_sn_dat;
     dat_trans sn_dat;
      forever begin
        dat_trans sn_dat_cln;
          if(dat_sn2noc_port_i.try_get(sn_dat)) begin
            `uvm_info (get_type_name(), $psprintf("handle_sn_dat: L1 dat %s", sn_dat.convert2string()),500);
          
            $cast(sn_dat_cln, sn_dat.clone());
            dat_noc2hn_port_sema.get();
            dat_noc2hn_port_o.put(sn_dat_cln);
            dat_noc2hn_port_sema.put();
            `uvm_info (get_type_name(),{"handle_sn_dat sent: ", sn_dat_cln.convert2string()},500);
            
          end else begin
            #1;
          end 
      end // forever loop
   
   endtask : handle_sn_dat
   
endclass : noc_ref_model

