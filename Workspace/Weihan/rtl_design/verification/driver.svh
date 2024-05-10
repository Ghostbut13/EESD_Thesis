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
// Summary    : UVM Driver for HN verification
// Created    : 14/10/2019
// Modified   : 08/01/2023
//
// ===============================[ DESCRIPTION ]===============================
//
// UVM Driver for use in HN UVM verification environment. It takes sequences from
// the sequencer and passes it to the L1 reference model
//
// =============================================================================

class driver extends uvm_driver #(l1_req);
  `uvm_component_utils(driver)
  
   uvm_put_port #(l1_input)      l1_in_port;
   uvm_get_port #(l1_output)     l1_out_port;


   l1_input l1_send;
   l1_output l1_received;
   fence_class fence_obj;
   
   int fence_num = 0;
   logic stall_pipeline = 0;
   int core_id;
   
   bit global_fence = 0;
   
   function new (string name, uvm_component parent, int id = 0);
      super.new(name,parent);
      core_id = id;
   endfunction : new
   
   function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      
      l1_in_port = new("l1_in_port",this);
      l1_out_port = new("l1_out_port",this);
      l1_send = new();
      l1_received = new();
      
      if(!uvm_config_db #(fence_class)::get(this, "*", "fence_obj", fence_obj))
        `uvm_error(get_type_name(), "Failed to retrieve fence_obj from the Configuration Database.")

   endfunction: build_phase

   task run_phase(uvm_phase phase);
    fork
        handle_core_req;
        handle_l1_rsp;
    join
   endtask : run_phase
   
   task handle_core_req;
     l1_req req;

      forever begin
        l1_input cln;
        
        if (stall_pipeline != 0 || global_fence) begin
            if(global_fence) begin
              if (fence_obj.mask == 0) begin
                global_fence = 0;
                `uvm_info (get_type_name(),$psprintf("fence %d disabled", fence_num),500);
                fence_num++;
                #10;
              end else
                `uvm_info (get_type_name(),$psprintf("mask: %h", fence_obj.mask),500);
            end
          req.op = rdstlq;
          req.core_id = core_id;
        end else begin
          seq_item_port.get_next_item(req);
          if (req != null) begin
            seq_item_port.item_done();
            `uvm_info (get_type_name(),{"got ",req.convert2string()},500);
            if(req.op == nop)
              req.op = rdstlq;
            else if (req.op == fence) begin
              global_fence = 1;
              `uvm_info (get_type_name(),$psprintf("fence %d enabled", fence_num),500);
              req.op = rdstlq;
              //set fence bitmask in config db
              if(fence_obj.mask == 0) begin
                fence_obj.sema.get();
                fence_obj.mask = {NUM_SIM_CORES{1'b1}};
                `uvm_info (get_type_name(),$psprintf("mask set to : %h",fence_obj.mask),500);
                fence_obj.sema.put();
              end
            end
          end
        end
              
        if(req.core_id == core_id) begin
          l1_send.load_data(req.op, req.addr, req.data, req.core_id);
          $cast(cln, l1_send.clone());
          l1_in_port.put(cln);
          `uvm_info (get_type_name(),{"sent ",req.convert2string()},500);
          #1;
        end else
          `uvm_info (get_type_name(),$psprintf("req core_id %d not matched with driver id %d, seq ignored", req.core_id, core_id),500);
      end

   endtask : handle_core_req
   
   task handle_l1_rsp;
      forever begin
        if(l1_out_port.try_get(l1_received)) begin
          `uvm_info (get_type_name(), $psprintf("handle_l1_rsp: L1 state %s", l1_received.convert2string()),500);
          stall_pipeline = l1_received.stall_pipeline;
          if(global_fence) begin
            fence_obj.sema.get();
            fence_obj.mask[core_id] = (l1_received.pending_entries != 0);
            fence_obj.sema.put();
          end
          

        end else begin
          #1;
        end // if l1_received
      end // forever loop
   
   endtask : handle_l1_rsp
   
endclass : driver

