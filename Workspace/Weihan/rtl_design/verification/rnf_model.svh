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
// Summary    : L1 Reference model for HN verification
// Created    : 14/10/2019
// Modified   : 29/08/2022
//
// ===============================[ DESCRIPTION ]===============================
//
// L1 reference model for use in HN UVM verification environment
//
// =============================================================================

class rnf_model extends uvm_agent;

  `uvm_component_utils(rnf_model)

  localparam int LLSC_WAIT_CNT = 200;

  /****************************L1 State Definitions*****************************
  Invalid - Cacheline is not present in the cache
  SharedClean - Cacheline is present and valid in the cache, it has not been
    modified with respect to the last level cache (Dirty bit is not set in L1), 
    it may be present in other L1 caches
  UniqueClean - Cacheline is present and valid in the cache, it has not been
    modified with respect to the last level cache (Dirty bit is not set in L1), 
    it is only present in this L1 cache and can be modified without sending any 
    request to L2HN
  UniqueDirty - Cacheline is present and valid in the cache, it has been
    modified with respect to the last level cache (Dirty bit is set in L1), it
    is only present in this L1 cache and can be modified without sending any 
    request to L2HN
  IS - Cacheline is not present in the cache, data in shared state is expected
    from L2HN
  IM: Cacheline is not present in the cache, data in exclusive state is
    expected from L2HN
  IMM: Cacheline is not present in the cache, expecting COMP_UC from L2HN
  II: Cacheline is not present in the cache, expecting COMP_I from L2HN
  IID: Cacheline is not present in the cache, expecting COMPDATA_I from L2HN
  IIC: Cacheline is not present in the cache, expecting COMPDBID from L2HN
  SM: Cacheline is present and valid in the cache, expecting COMP_UC from 
    L2HN, line may be present in other L1 caches at this stage
  MI: Cacheline is present and valid in the cache, it has been
    modified with respect to the last level cache (Dirty bit is set in L1), 
    eviction request has been sent to L2HN
  M_II: Cacheline is present and valid in the cache, it has been
    modified with respect to the last level cache (Dirty bit is set in L1), 
    cleaninvalid request has been sent to L2HN
  MI_I: Cacheline is not present in the cache, expecting COMP_I from L2HN (TODO:
    Check if it can be merged with II, TODO: no invalidation should be received
    in this state)
  MS_I: Cacheline is present and valid in the cache in the shared state (Dirty 
    bit is not set in L1). Transient state MI changed to MS_I because of 
    SnpShared.
  AI: Cacheline is not present in the cache, atomic request send to L2HN
  M_AI: Cacheline is present and modified in the cache, atomic request sent to 
    L2HN
  M_UC: Cacheline is present and modified in the cache, writecleanfull request
    sent to L2HN
  MS_SC: Cacheline is present in the cache in shared state, writecleanfull request
    sent to L2HN, M_UC transitioned to MS_SC on snpshared
  
  *****************************************************************************/
  typedef enum {Invalid, SharedClean, UniqueClean, UniqueDirty, IS, IM, IMM, II, IID, IIC, SM, MI, M_II, MI_I, MS_I, AI, M_AI, M_UC, MS_SC} l1_state_e;
  
  

  typedef struct {
    logic [L1C_ADDR_WIDTH-1:0] addr;
    l1_op_e op;
  } l1_stall_queue_entry_t;

  l1_stall_queue_entry_t l1_stall_queue [L1C_STALL_LIMIT-1:0];
  int stall_queue_entries = 0;

  typedef struct {
    logic [L1C_ADDR_WIDTH-1:0] addr;
    int way;
    l1_state_e transient_state;
    bit valid = 0;
    bit vict_valid = 0;
    int vict_entry;
    bit compack = 0;
  } l1_pt_entry_t;

  int pt_entries = 0;

  l1_pt_entry_t l1_pt_buffer[L1C_PT_LIMIT-1:0];

  typedef struct {
    logic [L1C_ADDR_WIDTH-1:0] addr;
    logic [L1C_DATA_WIDTH-1:0] data;
    l1_state_e transient_state;
    bit valid = 0;
    int pt_index;
  } l1_vict_entry_t;

  l1_vict_entry_t l1_vict_buffer[L1C_VB_LIMIT+L1C_PT_LIMIT-1:L1C_PT_LIMIT];
  int vict_entries = 0;

  uvm_get_port #(l1_input)      l1_in_port;
  uvm_put_port #(l1_output)     l1_out_port;
  uvm_put_port #(req_trans)     req_rn2noc_port_o;
  uvm_put_port #(rsp_trans)     rsp_rn2noc_port_o;
  uvm_get_port #(rsp_trans)     rsp_noc2rn_port_i;
  uvm_get_port #(dat_trans)     dat_noc2rn_port_i;
  uvm_put_port #(dat_trans)     dat_rn2noc_port_o;
  uvm_get_port #(snp_trans)     snp_noc2rn_port_i;
  
  l1_input req_in;
  snp_trans snp_in;
  rsp_trans rsp_in;
  dat_trans dat_in;
  
  l1_state_e state_store [L1C_SET_NUM-1:0][L1C_WAY_NUM-1:0] = '{default:Invalid};
  bit valid_store [L1C_SET_NUM-1:0][L1C_WAY_NUM-1:0] = '{default:0};
  bit dirty_store [L1C_SET_NUM-1:0][L1C_WAY_NUM-1:0] = '{default:0};
  logic [L1C_TAG_WIDTH-1:0] tag_store [L1C_SET_NUM-1:0][L1C_WAY_NUM-1:0];
  logic [L1C_DATA_WIDTH-1:0] data_store [L1C_SET_NUM-1:0][L1C_WAY_NUM-1:0];
  int way;
  int stall_queue_write_index = 0;
  int stall_queue_read_index = 0;
  response_opcode_e l2_rsp_op;
  data_opcode_e l2_dat_op;
  logic [RSP_RESP_WIDTH-1:0] resp_out;
  logic [RSP_RESP_WIDTH-1:0] dat_resp_out;
  logic       rsp_type = 0;            //response type (1: With Data, 0: Dataless)
  bit alloc_flag = 1; // allocate by default
  bit excl_flag = 0; // non-exclusive by default
  l1_chi_state_e chi_state;
  bit l2_req;
  bit l2_rsp;
  bit l2_dat;
  bit expcompack = 1;
  request_opcode_e l2_req_op;
  logic [L1C_ADDR_WIDTH-1:0] l2_req_addr;
  int req_txn_id_out;
  int rsp_txn_id_out;
  int dat_txn_id_out;
  bit pipeline_stalled=0;
  bit exclusive_loop=0;
  bit lp_monitor=0;
  int llsc_wait_cntr = 0;
  bit ll_comp = 0;
  logic [L1C_ADDR_WIDTH-1:0] excl_addr;
  logic [L1C_ADDR_WIDTH-1:0] rsp_addr=0;
  logic [L1C_ADDR_WIDTH-1:0] dat_addr=0;
  logic [L1C_DATA_WIDTH-1:0] l2_send_data = 0;

  function new (string name, uvm_component parent);
    super.new(name,parent);
  endfunction: new

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    l1_in_port    = new("l1_in_port",this);
    l1_out_port   = new("l1_out_port",this);
    req_rn2noc_port_o  = new("req_rn2noc_port_o",this);
    rsp_rn2noc_port_o  = new("rsp_rn2noc_port_o",this);
    rsp_noc2rn_port_i   = new("rsp_noc2rn_port_i",this);
    dat_noc2rn_port_i  = new("dat_noc2rn_port_i",this);
    dat_rn2noc_port_o  = new("dat_rn2noc_port_o",this);
    snp_noc2rn_port_i   = new("snp_noc2rn_port_i",this);
  endfunction: build_phase

  task run_phase(uvm_phase phase);
    l1_output l1_out = new();
    l1_output cln;
    bit req, snp, rsp, dat;
    logic [L1C_INDEX_WIDTH-1:0] index;
    logic [L1C_TAG_WIDTH-1:0] tag;
    bit tryget = 0;
    smpl_req_flit_t l2_req_flit;
    smpl_rsp_flit_t l2_rsp_out_flit;
    smpl_data_flit_t l2_dat_out_flit;
    req_trans l2_req_cln; 
    rsp_trans l2_rsp_cln;
    dat_trans l2_dat_cln;
    req_trans l2_req_send = new();
    rsp_trans l2_rsp_send = new();
    dat_trans l2_dat_send = new();

    forever begin : run_loop

      forever begin : get_loop
      
        snp = 0;
        rsp = 0;
        req = 0;
        dat = 0;
      
        if (llsc_wait_cntr)
          llsc_wait_cntr--;
        
        // Prioritize snoop port over rsp port over core requests
        snp = snp_noc2rn_port_i.try_get(snp_in);
        if(!snp) begin
          rsp = rsp_noc2rn_port_i.try_get(rsp_in);
          if(!rsp) begin
            dat = dat_noc2rn_port_i.try_get(dat_in);
            if(!dat)
            req = l1_in_port.try_get(req_in);
          end
        end
        
        if(snp || rsp || dat || req || (exclusive_loop && ll_comp && !llsc_wait_cntr))
          break;
        else
          #1;
      end : get_loop

      l2_req = 0;
      l2_rsp = 0;
      l2_dat = 0;

      `uvm_info(get_type_name(), $psprintf("llsc wait cntr: %d", llsc_wait_cntr),500);

      if (!(snp || rsp || dat || req)) begin //time to execute store conditional
        `uvm_info(get_type_name(), "executing storeconditional", 500);
        ll_comp = 0;
        l2_req_addr = excl_addr;
        llsc_loop_end;
      end else begin
        if (snp) begin
          `uvm_info(get_type_name(), snp_in.convert2string(),500);
        end else if (rsp) begin
          `uvm_info(get_type_name(), rsp_in.convert2string(),500);
        end else if (dat) begin
          `uvm_info(get_type_name(), dat_in.convert2string(),500);
        end else begin
          `uvm_info(get_type_name(), req_in.convert2string(),500);
          l2_req_addr = req_in.addr;
        end
        
        //l2_data_rsp = 0;


        if (req && (req_in.op inside {load, store, storeall, evict, evictclean, getclean, vectorload, vectorstore, vectorstoreptl, vectorload_noalloc, vectorstore_noalloc, loadlinked, atomic, cleaninvalid, makeinvalid})) begin //request from core

          if (exclusive_loop) begin
            add_to_stall_queue(req_in.op, req_in.addr);
            if (ll_comp && !llsc_wait_cntr) begin// time to execute store conditional
              `uvm_info(get_type_name(), "executing storeconditional", 500);
              ll_comp = 0;
              llsc_loop_end;
              l2_req_addr = excl_addr;
            end
          end else if (stall_queue_entries == 0 && req_in.op != loadlinked)
            handle_core_req(req_in.addr, req_in.op, 0);
          else begin
            add_to_stall_queue(req_in.op, req_in.addr);
            replay_stall_queue(l2_req_addr);
          end

        end else if (snp) begin //snoop request

          handle_snoop(snp_in.snp_flit);

        end else if (req && (req_in.op == rdstlq)) begin
          if (exclusive_loop) begin
            `uvm_info(get_type_name(), "ignoring op rdstlq, llsc in progress", 500);
            if (ll_comp && !llsc_wait_cntr) begin// time to execute store conditional
              `uvm_info(get_type_name(), "executing storeconditional", 500);
              ll_comp = 0;
              llsc_loop_end;
              l2_req_addr = excl_addr;
            end
          end else if (stall_queue_entries != 0)
            replay_stall_queue(l2_req_addr);

        end else if (rsp) begin  // comp

          if(rsp_in.rsp_flit.txn_id >= L1C_PT_LIMIT + L1C_VB_LIMIT)
            `uvm_fatal(get_type_name(),$psprintf("unexpected txn id %d",rsp_in.rsp_flit.txn_id))

          if(rsp_in.rsp_flit.txn_id < L1C_PT_LIMIT) // comp for request from PT buffer
            fsm_comp_ptb(rsp_in.rsp_flit);
          else
            fsm_comp_vbuffer(rsp_in.rsp_flit);

        end else if (dat) begin  // compdata

          if(dat_in.dat_flit.txn_id >= L1C_PT_LIMIT)
            `uvm_fatal(get_type_name(),$psprintf("unexpected txn id %d",dat_in.dat_flit.txn_id))

            fsm_compdata_ptb(dat_in.dat_flit);
        end
      end
        
        if (req) begin
          index = l2_req_addr [L1C_OFFSET +: L1C_INDEX_WIDTH];
          tag = l2_req_addr [(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH];

          //check if the valid bit is in sync with the state store array
          if(valid_store[index][way])
            if(!(state_store[index][way] inside {SharedClean, UniqueClean, UniqueDirty, SM, MI, MS_I, M_AI, M_II, M_UC, MS_SC}))
              `uvm_fatal("l1_model", $psprintf("Valid bit is high when state is %s", state_store[index][way].name()))


          //check if the dirty bit is in sync with the state store array
          if(dirty_store[index][way])
            if(!(state_store[index][way] inside {UniqueDirty, MI, M_AI, M_II, M_UC}))
              `uvm_fatal("l1_model", $psprintf("Dirty bit is high when state is %s", state_store[index][way].name()))

          //check if the exclusive flag is in sync with the req opcode
          if(l2_req)
            if(excl_flag && !(l2_req_op inside {READ_SHARED, CLEAN_UNIQUE}))
              `uvm_fatal("l1_model", $psprintf("Exclusive bit is high when req opcode is %s", l2_req_op.name()))
        end
        
        //print the state of L1 buffers
        `uvm_info(get_type_name(),$psprintf("PTB: %d Victim buffer: %d Stall queue: %d",pt_entries, vict_entries, stall_queue_entries), 500)

        if(l2_req) begin
          //generate l2 req flit
          l2_req_flit.src_id = 0; //NoC Model will overwrite this
          l2_req_flit.tgt_id = HN_ID;
          l2_req_flit.txn_id = req_txn_id_out;
          l2_req_flit.addr = l2_req_addr;
          l2_req_flit.opcode = l2_req_op;
          l2_req_flit.excl = excl_flag;
          l2_req_flit.alloc = alloc_flag;
          l2_req_flit.exp_comp_ack = expcompack;
          l2_req_send.load_data(l2_req_flit);
          $cast(l2_req_cln, l2_req_send.clone());
          req_rn2noc_port_o.put(l2_req_cln);
          `uvm_info (get_type_name(),{"l2 req sent: ",l2_req_cln.convert2string()},500);
        end 
        
        if (l2_rsp) begin
          //generate l2 rsp flit
          l2_rsp_out_flit.src_id = 0; //NoC Model will overwrite this
          l2_rsp_out_flit.tgt_id = HN_ID;
          l2_rsp_out_flit.txn_id = rsp_txn_id_out;
          l2_rsp_out_flit.opcode = l2_rsp_op;
          l2_rsp_out_flit.addr = rsp_addr; //For DEBUG
          l2_rsp_out_flit.resp_err = 0;
          l2_rsp_out_flit.rsp_type = rsp_type;
          l2_rsp_out_flit.resp = 3'(resp_out);
          if(l2_rsp_out_flit.opcode == COMP_ACK) begin
            l2_rsp_out_flit.resp = 0;
            l2_rsp_out_flit.rsp_type = 0;
            l2_rsp_out_flit.dbid = 0;
          end

          l2_rsp_send.load_data(l2_rsp_out_flit);

          $cast(l2_rsp_cln, l2_rsp_send.clone());
          rsp_rn2noc_port_o.put(l2_rsp_cln);
          `uvm_info (get_type_name(),{"rsp sent: ",l2_rsp_cln.convert2string()},500);
      end

      if (l2_dat) begin
        //generate l2 data flit
        l2_dat_out_flit.src_id = 0; //NoC Model will overwrite this
        l2_dat_out_flit.tgt_id = 32;
        l2_dat_out_flit.txn_id = dat_txn_id_out;
        l2_dat_out_flit.opcode = l2_dat_op;
        l2_dat_out_flit.addr = dat_addr; //For DEBUG
        l2_dat_out_flit.rsp_err = 0;
        l2_dat_out_flit.rsp = 3'(dat_resp_out);
        l2_dat_out_flit.data = l2_send_data;
        l2_dat_out_flit.be = '{default:'1};
        l2_dat_send.load_data(l2_dat_out_flit);
        $cast(l2_dat_cln, l2_dat_send.clone());
        dat_rn2noc_port_o.put(l2_dat_cln);
        `uvm_info (get_type_name(),{"data sent: ",l2_dat_cln.convert2string()},500);
      end

        // populate the output port
        l1_out.load_data(stall_pipeline(), stall_queue_entries+pt_entries+vict_entries);
        $cast (cln,l1_out.clone());
        l1_out_port.put(cln);
        `uvm_info (get_type_name(),{"l1 out sent: ",cln.convert2string()},500);

    end : run_loop;
  endtask: run_phase

  function bit cache_block_busy_check(int index, int way);
    if (state_store[index][way] inside {UniqueClean, UniqueDirty, Invalid, SharedClean})
      return 0;
    else
      return 1;
  endfunction: cache_block_busy_check

  function bit isvalid(int index, int way);
    if (valid_store[index][way])
      return 1;
    else
      return 0;
  endfunction: isvalid

  function bit isdirty(int index, int way);
    if (valid_store[index][way] && dirty_store[index][way])
      return 1;
    else
      return 0;
  endfunction: isdirty

  function bit ishit(int index, logic [L1C_TAG_WIDTH-1:0]tag);
    for (int i = 0; i<L1C_WAY_NUM;i++)
    begin
      if (valid_store[index][i] && tag_store[index][i] == tag)
        return 1;
    end
    return 0;
  endfunction: ishit

  function int wayfind(int index, logic [L1C_TAG_WIDTH-1:0]tag);
    for (int i = 0; i<L1C_WAY_NUM;i++)
    begin
      if (tag_store[index][i] == tag)
      return i;
    end
    `uvm_fatal("l1_model", $psprintf("unexpected miss"))
    return 0;
  endfunction: wayfind

  function int random_replacement (int index);
    for (int i = 0; i<L1C_WAY_NUM;i++)
      if (state_store[index][i] == Invalid)
        return i;

    // all ways valid or busy, return random way
    return $urandom_range(L1C_WAY_NUM-1);

  endfunction: random_replacement

  function l1_chi_state_e l12chi(l1_state_e l1_state);
    if (l1_state inside {Invalid, IS, IM, IMM})
      return l1_Invalid;
    else if (l1_state inside {SharedClean, SM})
      return l1_SharedClean;
    else if (l1_state inside {UniqueDirty, MI, MI_I, MS_I})
      return l1_UniqueDirty;
    else
      return l1_UniqueClean;
  endfunction: l12chi

  function int vict_buffer_index(logic [L1C_ADDR_WIDTH-1:0] addr);
    for (int i=L1C_PT_LIMIT;i<L1C_PT_LIMIT+L1C_VB_LIMIT;i++) begin
      if (l1_vict_buffer[i].addr[L1C_ADDR_WIDTH-1:3] == addr[L1C_ADDR_WIDTH-1:3] && l1_vict_buffer[i].valid)
        return i;
    end

    return -1;

  endfunction: vict_buffer_index


  // task to handle core request
  task handle_core_req (logic [L1C_ADDR_WIDTH-1:0] addr, l1_op_e op, bit was_stalled);

    logic [L1C_INDEX_WIDTH-1:0] index;
    logic [L1C_TAG_WIDTH-1:0] tag;
    bit req_stalled = 0;
    bit block_busy;
    bit hit_not_miss;

    index = addr [L1C_OFFSET +: L1C_INDEX_WIDTH];
    tag = addr [(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH];


    `uvm_info(get_type_name(),$psprintf("index: %h tag:%h",index, tag), 500)

    hit_not_miss = ishit(index, tag);

    if (hit_not_miss) begin // hit

      way = wayfind(index, tag);

      `uvm_info(get_type_name(), $psprintf("way: %d",way), 500)

      block_busy = cache_block_busy_check(index, way);

      if (!block_busy) begin// if not busy, initiate FSM to handle core req
        fsm_core_req(op, addr, index, way, 0, 0);
      end else begin // block busy, stall the request
        if (op == storeconditional)
          `uvm_fatal(get_type_name(),
          $psprintf("storeconditional index: %h tag:%h busy: %s",index, tag, state_store[index][way].name()))
      else
        `uvm_info(get_type_name(),
        $psprintf("index: %h tag:%h busy",index, tag), 500)
        if (!was_stalled) //if the request did not come from stall queue
          add_to_stall_queue(op, addr);
          req_stalled = 1;
        end

    end else begin // miss

    if((is_ptb_hit(index, tag) != -1) || (is_vbuffer_hit(index, tag) != -1)) begin  //addr is hit in ptb or vbuffer
      if (op == storeconditional)
        `uvm_fatal(get_type_name(),$psprintf("storeconditional index: %h tag:%h ptb hit",index, tag))
      if (!was_stalled)//if the request did not come from stall queue
        add_to_stall_queue(op, addr);
      req_stalled = 1;
    end else begin

      `uvm_info(get_type_name(),$psprintf("index: %h tag:%h missed",index, tag), 500)


      if (op != evict && op != getclean && op != evictclean) begin // if not evict, since evict misses don't need to do anything
        // select way to replace
        way = random_replacement(index);

        `uvm_info(get_type_name(), $psprintf("way: %d",way), 500)

        block_busy = cache_block_busy_check(index, way);

        if (!block_busy) // if not busy
        begin

          bit vict_valid = 0;
          int vict_entry;

          if(isvalid(index, way)) begin // initiate replacement and eviction

            if(isdirty(index,way)) begin //if dirty, put the block in victim buffer
              vict_valid = 1;
              `uvm_info(get_type_name(), $psprintf("Adding index: %h tag: %h to victim buffer",index, tag_store[index][way]), 500)
              vict_entry = add_to_vbuffer({tag_store[index][way], index, {L1C_OFFSET{1'b0}}}, data_store[index][way]);
            end
            // invalidate the block
            state_store[index][way] = Invalid;
            valid_store[index][way] = 0;

          end 

          //replace the tag
          tag_store[index][way] = tag;

          //reset the dirty bit
          dirty_store[index][way] = 0;

          // initiate FSM
          fsm_core_req(op, addr, index, way, vict_valid, vict_entry);

        end else begin// block busy, stall the request
          if (op == storeconditional)
            `uvm_fatal(get_type_name(),$psprintf("storeconditional block busy"))
        else
          `uvm_info(get_type_name(), "Cache block busy, stall request", 500)
          if (!was_stalled)
            add_to_stall_queue(op,addr);
            req_stalled = 1;
          end
        end // if not evict
      end // if ptb hit
    end // if hit/miss

    if (was_stalled && !req_stalled) //if the request came from stall queue and was successfully processed
      remove_from_stall_queue;

  endtask: handle_core_req

  // task to handle snoops
  task handle_snoop(smpl_snp_flit_t snp_flit);

    logic [L1C_INDEX_WIDTH-1:0] index;
    logic [L1C_TAG_WIDTH-1:0] tag;
    logic [L1C_ADDR_WIDTH-1:0] snp_addr = {snp_flit.addr,3'b000};
    `uvm_info(get_type_name(),$psprintf("Handle_snoop addr: %h", snp_addr), 500)
    index = snp_addr [L1C_OFFSET +: L1C_INDEX_WIDTH];
    tag = snp_addr [(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH];

    rsp_txn_id_out = snp_flit.txn_id;
    rsp_addr = snp_addr;
    dat_txn_id_out = snp_flit.txn_id;
    dat_addr = snp_addr;

    // search for the addr in cache
    if(ishit(index, tag)) begin // snooped addr is in cache
      `uvm_info(get_type_name(),
      $psprintf("index: %h tag:%h is hit in cache",index, tag), 500)
      way = wayfind(index, tag);
      fsm_snoop(index, way, snp_flit.opcode);
    end else if(vict_buffer_index(snp_addr) >= 0) begin // snooped addr is in victim buffer
      `uvm_info(get_type_name(),$psprintf("index: %h tag:%h is in vbuffer",index, tag), 500)
      fsm_vbuffer(snp_flit.opcode, snp_addr);

    end else begin //snooped addr is not with us, respond with invalid
      l2_rsp_op = SNP_RESP;
      resp_out = RSP_RESP_WIDTH'(I);
      rsp_type = 0; // no data
      l2_rsp = 1;
      l2_dat = 0;
    end
    `uvm_info(get_type_name(),$psprintf("L2_RSP field: %h",l2_rsp), 500)
    // TODO: make sure rnf can send a data snp response if required
  endtask: handle_snoop

  // FSM to handle snoops
  task fsm_snoop (int index, int way, snoop_opcode_e op);


    l1_state_e curr_state, next_state;

    curr_state = state_store[index][way];

    l2_send_data = data_store[index][way];

    l2_rsp_op = SNP_RESP;
    
    l2_dat_op = SNP_RSP_DATA;
    case (op)
      SNP_CLEAN_INVALID,SNP_UNIQUE: begin

        resp_out = RSP_RESP_WIDTH'(I);
        dat_resp_out = DAT_RESP_WIDTH'(I);
        rsp_type = 0; // no data by default
        l2_dat = 0;
        l2_rsp = 0;
        lp_monitor = 0;
        valid_store[index][way] = 0;
        dirty_store[index][way] = 0;
        case (curr_state)

          UniqueClean, SharedClean: begin //invalidate the line
            next_state = Invalid;
            l2_rsp = 1;
          end

          UniqueDirty: begin //invalidate the line
            next_state = Invalid;
            rsp_type = 1; // data response
            l2_dat = 1;
          end

          Invalid, IS, IM, IMM, MI_I, II, AI: begin
            next_state = curr_state;
            l2_rsp = 1;
          end

          M_II: begin
            next_state = II;
            rsp_type = 1; // data response
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          SM: begin
            next_state = IMM;
            l2_rsp = 1;
            change_ptb_state(index,way,next_state);
          end

          MI,M_UC: begin
            next_state = MI_I;
            rsp_type = 1; // data response
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          MS_I, MS_SC: begin
            next_state = MI_I;
            l2_rsp = 1;
            change_ptb_state(index,way,next_state);
          end

          M_AI: begin
            next_state = AI;
            rsp_type = 1; // data response
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end

      SNP_MAKE_INVALID: begin

        resp_out = RSP_RESP_WIDTH'(I);
        dat_resp_out = DAT_RESP_WIDTH'(I);
        rsp_type = 0; // no data by default
        l2_dat = 0;
        l2_rsp = 1;
        lp_monitor = 0;
        valid_store[index][way] = 0;
        dirty_store[index][way] = 0;
        case (curr_state)

          UniqueDirty, UniqueClean, SharedClean: begin //invalidate the line
            next_state = Invalid;
          end

          Invalid, IS, IM, IMM, MI_I, II, AI: begin
            next_state = curr_state;
          end

          M_II: begin
            next_state = II;
            change_ptb_state(index,way,next_state);
          end

          SM: begin
            next_state = IMM;
            change_ptb_state(index,way,next_state);
          end

          MI, MS_I, M_UC, MS_SC: begin
            next_state = MI_I;
            change_ptb_state(index,way,next_state);
          end

          M_AI: begin
            next_state = AI;
            change_ptb_state(index,way,next_state);
          end

          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end

      SNP_SHARED: begin
        resp_out = RSP_RESP_WIDTH'(SC);
        dat_resp_out = DAT_RESP_WIDTH'(SC);
        rsp_type = 0; // no data by default
        l2_dat = 0;
        l2_rsp = 0;
        case (curr_state)

          UniqueClean: begin
            next_state = SharedClean;
            l2_rsp = 1;
          end

          UniqueDirty: begin
            next_state = SharedClean;
            dirty_store[index][way] = 0;
            rsp_type = 1; // data response
            l2_dat = 1;
          end

          IS, IM, IMM, II: begin
            next_state = curr_state;
            resp_out = RSP_RESP_WIDTH'(I);
            l2_rsp = 1;
          end

          SM: begin
            next_state = curr_state;
            resp_out = RSP_RESP_WIDTH'(I);
            l2_rsp = 1;
          end

          MI: begin
            next_state = MS_I;
            dirty_store[index][way] = 0;
            rsp_type = 1;
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          M_II: begin
            next_state = II;
            dirty_store[index][way] = 0;
            valid_store[index][way] = 0; // Immediately evict the data silently
            rsp_type = 1; // data response
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          MS_I: begin
            next_state = curr_state;
            l2_rsp = 1;
          end

          M_UC: begin
            next_state = MS_SC;
            dirty_store[index][way] = 0;
            rsp_type = 1; // data response
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          M_AI: begin
            next_state = AI;
            dirty_store[index][way] = 0;
            valid_store[index][way] = 0; // Immediately evict the data silently
            rsp_type = 1;
            l2_dat = 1;
            change_ptb_state(index,way,next_state);
          end

          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end

      SNP_ONCE: begin
        next_state = curr_state; // snp_once shouldn't change state
        case (curr_state)

          UniqueClean: begin
            resp_out = RSP_RESP_WIDTH'(UC);
            dat_resp_out = DAT_RESP_WIDTH'(UC);
            l2_dat = 0;
            l2_rsp = 1;
            rsp_type = 0;
          end

          UniqueDirty, M_AI, MI, M_II, M_UC: begin
            resp_out = RSP_RESP_WIDTH'(UC);
            dat_resp_out = DAT_RESP_WIDTH'(UC);
            l2_dat = 1;
            l2_rsp = 0;
            rsp_type = 1; // data response
          end

          IS, IM, IMM, II, AI: begin
            resp_out = RSP_RESP_WIDTH'(I);
            dat_resp_out = DAT_RESP_WIDTH'(I);
            l2_dat = 0;
            l2_rsp = 1;
            rsp_type = 0;
          end

          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end

      default: `uvm_fatal(get_type_name(),$psprintf("unexpected snoop %s",op.name()))
    endcase

    state_store[index][way] = next_state;

    `uvm_info(get_type_name(),$psprintf("index %d way %d state from %s to %s",index, way, curr_state.name(), next_state.name()), 500)
  endtask: fsm_snoop

  // FSM to handle core requests
  task fsm_core_req (l1_op_e op, logic [L1C_ADDR_WIDTH-1:0] addr, int index, int way, bit vict_valid, int vict_entry);


    l1_state_e curr_state, next_state;

    l2_req = 0;

    curr_state = state_store[index][way];

    expcompack = 0;

    case (op)
      load,loadlinked:
        case (curr_state)
          UniqueClean, UniqueDirty, SharedClean: begin
            next_state = curr_state;
            if (op == loadlinked) begin
              lp_monitor = 1;
              llsc_wait_cntr = LLSC_WAIT_CNT;
              ll_comp = 1;
            end
          end
          Invalid:  begin 
            next_state = IS;
            l2_req = 1;
            l2_req_op = READ_SHARED;
            expcompack = 1;
            if (op == loadlinked) begin
              ll_comp = 0;
            end
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      store: begin
        // It should be okay to populate the data array at this point even if the state is invalid
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        case (curr_state)
          UniqueClean: begin
            next_state = UniqueDirty;
            dirty_store[index][way] = 1;
          end
          UniqueDirty: begin
            next_state = curr_state;
          end
          Invalid:  begin
            next_state = IM;
            l2_req = 1;
            l2_req_op = READ_UNIQUE;
            expcompack = 1;
          end
          SharedClean: begin
            next_state = IM;
            l2_req = 1;
            l2_req_op = READ_UNIQUE;
            valid_store[index][way] = 0;
            expcompack = 1;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      storeall: begin
        // It should be okay to populate the data array at this point even if the state is invalid
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        case (curr_state)
          UniqueClean: begin
            next_state = UniqueDirty;
            dirty_store[index][way] = 1;
          end
          UniqueDirty: next_state = curr_state;
          Invalid:  begin
            next_state = IMM;
            l2_req = 1;
            l2_req_op = MAKE_UNIQUE;
            expcompack = 1;
          end
          SharedClean: begin
            next_state = SM;
            l2_req = 1;
            l2_req_op = MAKE_UNIQUE;
            expcompack = 1;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      storeconditional: begin
        // It should be okay to populate the data array at this point even if the state is invalid
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        case (curr_state)
          UniqueClean: begin
            next_state = UniqueDirty;
            dirty_store[index][way] = 1;
            exclusive_loop = 0;
          end
          UniqueDirty: begin
            next_state = curr_state;
            exclusive_loop = 0;
          end
          Invalid:  begin
            `uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
          end
          SharedClean: begin
            next_state = SM;
            l2_req = 1;
            l2_req_op = CLEAN_UNIQUE;
            expcompack = 1;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      evict:
        case (curr_state)
          UniqueClean,SharedClean: begin
            next_state = Invalid;
            valid_store[index][way] = 0;
          end
          UniqueDirty: begin
            next_state = MI;
            l2_req = 1;
            l2_req_op = WRITE_BACK_FULL;
          end
          Invalid:  next_state = curr_state;
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      evictclean:
        case (curr_state)
          UniqueClean,SharedClean: begin
            next_state = II;
            valid_store[index][way] = 0;
            l2_req = 1;
            l2_req_op = EVICT;
          end
          UniqueDirty: begin
            next_state = MI;
            l2_req = 1;
            l2_req_op = WRITE_BACK_FULL;
          end
          Invalid:  next_state = curr_state;
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      getclean:
        case (curr_state)
          UniqueClean, Invalid, SharedClean: begin
            next_state = curr_state;
          end
          UniqueDirty: begin
            next_state = M_UC;
            l2_req = 1;
            l2_req_op = WRITE_CLEAN_FULL;
          end
          Invalid:  next_state = curr_state;
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      vectorload, vectorload_noalloc:
        case (curr_state)
        // We are silently evicting dirty data because for the purpose of HN verificaiton, 
        // it doesn't matter and it greatly simplifies handling vectorload and vectorstore
        // Ideally, the software will evict dirty data before issuing vector instruction
          UniqueClean, UniqueDirty, SharedClean, Invalid: begin
            next_state = IID;
            l2_req = 1;
            l2_req_op = READ_ONCE;
            if(op == vectorload)
              expcompack = 1;
              valid_store[index][way] = 0;
              dirty_store[index][way] = 0;
            end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      vectorstore, vectorstore_noalloc: begin
        // This data will be sent when COMPDBID is received from L2HN
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        case (curr_state)
          // We are silently evicting dirty data because for the purpose of HN verificaiton, 
          // it doesn't matter and it greatly simplifies handling vectorload and vectorstore
          // Ideally, the software will evict dirty data before issuing vector instruction
          UniqueClean, UniqueDirty, SharedClean, Invalid: begin
            next_state = IIC;
            l2_req = 1;
            l2_req_op = WRITE_UNIQUE_FULL;
            valid_store[index][way] = 0;
            dirty_store[index][way] = 0;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      vectorstoreptl: begin
        // This data will be sent when COMPDBID is received from L2HN
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        case (curr_state)
          // We are silently evicting dirty data because for the purpose of HN verificaiton, 
          // it doesn't matter and it greatly simplifies handling vectorload and vectorstore
          // Ideally, the software will evict dirty data before issuing vector instruction
          UniqueClean, UniqueDirty, SharedClean, Invalid: begin
            next_state = IIC;
            l2_req = 1;
            l2_req_op = WRITE_UNIQUE_PTL;
            valid_store[index][way] = 0;
            dirty_store[index][way] = 0;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      atomic: begin
        // This data will be sent when DBIDResp is received from L2HN
        data_store[index][way] = {(L1C_DATA_WIDTH/32){$urandom()}};
        l2_req = 1;
        l2_req_op = ATOMIC_SWAP;
        case (curr_state)
          UniqueClean, SharedClean, Invalid: begin
            next_state = AI;
            valid_store[index][way] = 0; // silently evict the line
          end
          UniqueDirty: begin
            next_state = M_AI;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      cleaninvalid: begin
        l2_req = 1;
        l2_req_op = CLEAN_INVALID;
        case (curr_state)
          UniqueClean, SharedClean, Invalid: begin
            next_state = II;
            valid_store[index][way] = 0;
          end
          UniqueDirty: begin
            next_state = M_II;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      makeinvalid: begin
        l2_req = 1;
        l2_req_op = MAKE_INVALID;
        case (curr_state)
          UniqueClean, UniqueDirty, SharedClean, Invalid: begin
            next_state = II;
            valid_store[index][way] = 0;
            dirty_store[index][way] = 0;
          end
          default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 state %s",op.name(), curr_state.name()))
        endcase
      end
      default: `uvm_fatal(get_type_name(),$psprintf("unexpected op %s from driver",op.name()))
    endcase

    if (op == vectorload_noalloc || op == vectorstore_noalloc)
      alloc_flag = 0;
    else
      alloc_flag = 1;

    if (op == loadlinked) begin
      exclusive_loop = 1;
    end

    if (op == loadlinked || op == storeconditional) begin
      excl_flag = 1;
      excl_addr = addr;
    end else
      excl_flag = 0;

    if (l2_req) begin // if sending request to L2, add the pending transaction to PT buffer
      req_txn_id_out = add_to_ptb(addr, way, next_state, vict_valid, vict_entry, expcompack);
    end

    state_store[index][way] = next_state;


    `uvm_info(get_type_name(),$psprintf("index %d way %d state from %s to %s",index, way, curr_state.name(), next_state.name()), 500)
  endtask: fsm_core_req
  
  // FSM to handle snoops that hit victim buffer
  task fsm_vbuffer(snoop_opcode_e op, logic [L1C_ADDR_WIDTH-1:0] addr);

    l1_state_e curr_state, next_state;
    int index;
    int pt_index;

    index = vict_buffer_index(addr);
    pt_index = l1_vict_buffer[index].pt_index;
    l2_send_data = l1_vict_buffer[index].data;

    l2_rsp_op = SNP_RESP;
    l2_dat_op = SNP_RSP_DATA;

    if (index < 0)
      `uvm_fatal(get_type_name(),$psprintf("addr %0h not found in vict buffer", addr))

      curr_state = l1_vict_buffer[index].transient_state;

      case (op)
        SNP_CLEAN_INVALID, SNP_UNIQUE: begin

          resp_out = RSP_RESP_WIDTH'(I);
          dat_resp_out = DAT_RESP_WIDTH'(I);
          rsp_type = 0; // no data by default
          l2_dat = 0;
          l2_rsp = 0;
          case (curr_state)

            UniqueDirty: begin //invalidate the line
              next_state = Invalid;
              rsp_type = 1; // data response
              l2_dat = 1;
              l1_vict_buffer[index].valid = 0;
              vict_entries--;
              if (!l1_pt_buffer[pt_index].valid)
                `uvm_fatal(get_type_name(),$psprintf("Associated pt buffer entry %d invalid for vict entry %d %h", pt_index, index, addr))
              l1_pt_buffer[pt_index].vict_valid = 0;
              `uvm_info(get_type_name(), $psprintf("removing entry %d from vbuffer", index), 500)
            end

            MI, MS_I: begin
              next_state = MI_I;
              rsp_type = 1; // data response
              l2_dat = 1;
            end

            MI_I: begin
              next_state = curr_state;
              l2_rsp = 1;
            end

            default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 vict state %s",op.name(), curr_state.name()))
          endcase
        end
        SNP_MAKE_INVALID: begin

          resp_out = RSP_RESP_WIDTH'(I);
          dat_resp_out = DAT_RESP_WIDTH'(I);
          rsp_type = 0; // no data by default
          l2_dat = 0;
          l2_rsp = 1;
          case (curr_state)

            UniqueDirty: begin //invalidate the line
              next_state = Invalid;
              l1_vict_buffer[index].valid = 0;
              vict_entries--;
              if (!l1_pt_buffer[pt_index].valid)
                `uvm_fatal(get_type_name(),$psprintf("Associated pt buffer entry %d invalid for vict entry %d %h", pt_index, index, addr))
              l1_pt_buffer[pt_index].vict_valid = 0;
              `uvm_info(get_type_name(), $psprintf("removing entry %d from vbuffer", index), 500)
            end

            MI, MS_I: begin
              next_state = MI_I;
            end

            MI_I: begin
              next_state = curr_state;
            end

            default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 vict state %s",op.name(), curr_state.name()))
          endcase
        end
        SNP_SHARED: begin

          resp_out = RSP_RESP_WIDTH'(SC);
          dat_resp_out = DAT_RESP_WIDTH'(SC);
          rsp_type = 0; // dataless response by default
          l2_dat = 0;
          l2_rsp = 0;

          case (curr_state)

            UniqueDirty: begin //invalidate the line, since we were going to evict it anyway
              next_state = Invalid;
              rsp_type = 1; // data response
              l2_dat = 1;
              l1_vict_buffer[index].valid = 0;
              vict_entries--;
              if (!l1_pt_buffer[pt_index].valid)
                `uvm_fatal(get_type_name(),$psprintf("Associated pt buffer entry %d invalid for vict entry %d %h", pt_index, index, addr))
                l1_pt_buffer[pt_index].vict_valid = 0;
                `uvm_info(get_type_name(), $psprintf("removing entry %d from vbuffer", index), 500)
              end

            MI: begin
              next_state = MS_I;
              rsp_type = 1; // data response
              l2_dat = 1;
            end

            MS_I: begin
              next_state = curr_state;
              l2_rsp = 1;
            end

            default:`uvm_fatal(get_type_name(),$psprintf("unexpected op %s for L1 vict state %s",op.name(), curr_state.name()))
          endcase
        end
        SNP_ONCE: begin

          resp_out = RSP_RESP_WIDTH'(UC);
          dat_resp_out = DAT_RESP_WIDTH'(UC);
          rsp_type = 1; // data response by default
          l2_dat = 1;
          l2_rsp = 0;
          next_state = curr_state; // snp_once shouldn't change state

        end
        default: `uvm_fatal(get_type_name(),$psprintf("unexpected snoop %s",op.name()))
      endcase

    l1_vict_buffer[index].transient_state = next_state;

    `uvm_info(get_type_name(),
    $psprintf("Vict entry %d state from %s to %s",
    index, curr_state.name(), next_state.name()), 500)

  endtask: fsm_vbuffer

  // FSM to handle compdata for PTB
  task fsm_compdata_ptb(smpl_data_flit_t data_flit);

    logic [L1C_INDEX_WIDTH-1:0] index;
    logic [L1C_TAG_WIDTH-1:0] tag;
    logic[L1C_ADDR_WIDTH-1:0] addr;
    l1_state_e curr_state;
    int pt_index;

    pt_index = data_flit.txn_id;

    `uvm_info(get_type_name(), $psprintf("received compdata for PTB entry %d", pt_index), 500)

    curr_state = l1_pt_buffer[pt_index].transient_state;
    index = l1_pt_buffer[pt_index].addr[L1C_OFFSET +: L1C_INDEX_WIDTH];
    way = l1_pt_buffer[pt_index].way;
    tag = l1_pt_buffer[pt_index].addr[(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH];

    //print the index and tag information
    `uvm_info(get_type_name(),
    $psprintf("index: %h tag:%h",
    index, tag), 500)




  case (curr_state)
    IS: begin
      valid_store[index][way] = 1;
      //change state in state store
        if(data_flit.rsp == unsigned'(SC))
        state_store[index][way] = SharedClean;
        else if(data_flit.rsp == unsigned'(UC))
        state_store[index][way] = UniqueClean;
      else
        `uvm_fatal(get_type_name(),
          $psprintf("unexpected response %0h for transient state IS",
            data_flit.rsp))

      if(exclusive_loop) begin // the request was exclusive
        lp_monitor = 1;
        llsc_wait_cntr = LLSC_WAIT_CNT;
        ll_comp = 1;
      end
    end

    IM: begin
      if (!exclusive_loop) begin
        valid_store[index][way] = 1;
        dirty_store[index][way] = 1;
        //change state in state store
          if(data_flit.rsp == unsigned'(UC))
          state_store[index][way] = UniqueDirty;
        else
          `uvm_fatal(get_type_name(),
            $psprintf("unexpected response %0h for transient state IM",
              data_flit.rsp))
        end else begin
          `uvm_fatal(get_type_name(), "exclusive request not expected for transient state IM")
        end
      end
      IID: begin
        if(data_flit.rsp != unsigned'(I))
          `uvm_fatal(get_type_name(),
            $psprintf("unexpected response %0h for transient state II",
            data_flit.rsp))
        state_store[index][way] = Invalid;
      end
      AI: begin
        if(data_flit.rsp != unsigned'(I))
          `uvm_fatal(get_type_name(),
          $psprintf("unexpected response %0h for transient state AI",
          data_flit.rsp))
        state_store[index][way] = Invalid;
      end
      default:`uvm_fatal(get_type_name(),
                $psprintf("unexpected state %s for COMPDATA",
                curr_state.name()))
    endcase
    
    data_store[index][way] = data_flit.data;

    `uvm_info(get_type_name(),
      $psprintf("State changed from %s to %s",
        curr_state.name(), state_store[index][way].name()), 500)

    if(l1_pt_buffer[pt_index].compack) begin
      l2_rsp = 1;
      l2_rsp_op = COMP_ACK;
      rsp_type = 0; // no data
      rsp_txn_id_out = data_flit.dbid; // TODO: This should be txn_id not dbid
      rsp_addr = l1_pt_buffer[pt_index].addr;
    end

    //remove the entry from PTB
    remove_from_ptb(pt_index);

    if (exclusive_loop) begin 
      if (data_flit.rsp_err != unsigned'(X_OK)) begin // exclusive request failed

        if(l1_pt_buffer[pt_index].vict_valid)
          `uvm_fatal(get_type_name(), "unexpected victim for failed exclusive request")

        `uvm_info(get_type_name(), "exclusive request failed, sending load linked again", 500)
        l2_req_addr = excl_addr;
        handle_core_req(excl_addr, loadlinked, 0);
      end else begin
        `uvm_info(get_type_name(), "exclusive request successfull", 500)

        //check if there is an associated victim buffer entry waiting to be evicted
        if(l1_pt_buffer[pt_index].vict_valid) begin
          l2_req = 1;
          l2_req_addr = l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].addr;
          l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
          req_txn_id_out = l1_pt_buffer[pt_index].vict_entry;
          `uvm_info(get_type_name(), $psprintf("found associated vict %h at %d for PTB index %d", l2_req_addr, l1_pt_buffer[pt_index].vict_entry, pt_index), 500)
          //l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
          l2_req_op = WRITE_BACK_FULL;
          excl_flag = 0;
          expcompack = 0;
        end
      end
    end else begin
      //check if there is an associated victim buffer entry waiting to be evicted
      if(l1_pt_buffer[pt_index].vict_valid) begin
        l2_req = 1;
        l2_req_addr = l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].addr;
        l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
        req_txn_id_out = l1_pt_buffer[pt_index].vict_entry;
        `uvm_info(get_type_name(), $psprintf("found associated vict %h at %d for PTB index %d", l2_req_addr, l1_pt_buffer[pt_index].vict_entry, pt_index), 500)
        //l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
        l2_req_op = WRITE_BACK_FULL;
        excl_flag = 0;
        expcompack = 0;

      end else begin//check if there is an entry in stall queue
        if (stall_queue_entries != 0)
          replay_stall_queue(l2_req_addr);
    end
  end


  endtask: fsm_compdata_ptb

  // FSM to handle comp for PTB
  task fsm_comp_ptb(smpl_rsp_flit_t rsp_flit);

    logic [L1C_INDEX_WIDTH-1:0] index;
    logic [L1C_TAG_WIDTH-1:0] tag;
    logic[L1C_ADDR_WIDTH-1:0] addr;
    l1_state_e curr_state;
    int pt_index;
    bit data_send = 0;

    pt_index = rsp_flit.txn_id;

    `uvm_info(get_type_name(), $psprintf("received comp for PTB entry %d", pt_index), 500)

    curr_state = l1_pt_buffer[pt_index].transient_state;
    index = l1_pt_buffer[pt_index].addr[L1C_OFFSET +: L1C_INDEX_WIDTH];
    way = l1_pt_buffer[pt_index].way;
    tag = l1_pt_buffer[pt_index].addr[(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH];

    //print the index and tag information
    `uvm_info(get_type_name(),
    $psprintf("index: %h tag:%h",
    index, tag), 500)




  case (curr_state)
    IMM: begin
      if (!exclusive_loop) begin
        valid_store[index][way] = 1;
        dirty_store[index][way] = 1;
        //change state in state store
        if(rsp_flit.resp == unsigned'(UC))
          state_store[index][way] = UniqueDirty;
        else
          `uvm_fatal(get_type_name(),
            $psprintf("unexpected response %0h for transient state IMM",
            rsp_flit.resp))
        end else begin // exclusive request failed
          `uvm_info(get_type_name(), "exclusive request failed", 500)
          valid_store[index][way] = 0;
          state_store[index][way] = Invalid;
        end
      end
    II: begin
      if(rsp_flit.resp != unsigned'(I))
        `uvm_fatal(get_type_name(),
          $psprintf("unexpected response %0h for transient state II",
          rsp_flit.resp))
      state_store[index][way] = Invalid;
    end
    SM: begin
      if (!exclusive_loop || (exclusive_loop && rsp_flit.resp_err == unsigned'(X_OK))) begin
        if(!valid_store[index][way])
          `uvm_fatal(get_type_name(), "valid bit not set for transient state SM")
        dirty_store[index][way] = 1;
        //change state in state store
        if(rsp_flit.resp == unsigned'(UC))
          state_store[index][way] = UniqueDirty;
        else
          `uvm_fatal(get_type_name(),
            $psprintf("unexpected response %0h for transient state SM",
            rsp_flit.resp))
        if (exclusive_loop) begin
          exclusive_loop = 0;
          lp_monitor = 0;
        end
      end else begin // exclusive request failed
        `uvm_info(get_type_name(), "exclusive request failed", 500)
        valid_store[index][way] = 0;
        state_store[index][way] = Invalid;
      end
    end
    MI,MI_I,MS_I: begin
      valid_store[index][way] = 0;
      dirty_store[index][way] = 0;
      //change state in state store
      state_store[index][way] = Invalid;
      data_send = 1;
      dat_resp_out = DAT_RESP_WIDTH'(I);
    end
    M_UC: begin
      dirty_store[index][way] = 0;
      //change state in state store
      state_store[index][way] = UniqueClean;
      data_send = 1;
      dat_resp_out = DAT_RESP_WIDTH'(UC);
    end
    MS_SC: begin
      //change state in state store
      state_store[index][way] = SharedClean;
      data_send = 1;
      dat_resp_out = DAT_RESP_WIDTH'(SC);
    end
    AI, IIC: begin
      //change state in state store
      state_store[index][way] = Invalid;
      data_send = 1;
      dat_resp_out = DAT_RESP_WIDTH'(I);
    end
    default:`uvm_fatal(get_type_name(),
              $psprintf("unexpected state %s for COMP",
              curr_state.name()))
  endcase

  `uvm_info(get_type_name(),
    $psprintf("State changed from %s to %s",
      curr_state.name(), state_store[index][way].name()), 500)

  if(l1_pt_buffer[pt_index].compack) begin
    l2_rsp = 1;
    l2_rsp_op = COMP_ACK;
    rsp_type = 0; // no data
    rsp_txn_id_out = rsp_flit.dbid;
    rsp_addr = l1_pt_buffer[pt_index].addr;
  end

  if(data_send) begin
    l2_dat = 1;
    dat_txn_id_out = rsp_flit.dbid;
    if(curr_state == AI || curr_state == IIC)
      l2_dat_op = NON_COPY_BACK_WR_DATA;
    else
      l2_dat_op = COPY_BACK_WR_DATA;
    dat_addr = l1_pt_buffer[pt_index].addr;
    l2_send_data = data_store[index][way];
  end
  //remove the entry from PTB
  remove_from_ptb(pt_index);

  if (exclusive_loop) begin 
    if (rsp_flit.resp_err != unsigned'(X_OK)) begin // exclusive request failed

      if(l1_pt_buffer[pt_index].vict_valid)
        `uvm_fatal(get_type_name(), "unexpected victim for failed exclusive request")

      `uvm_info(get_type_name(), "exclusive request failed, sending load linked again", 500)
      l2_req_addr = excl_addr;
      handle_core_req(excl_addr, loadlinked, 0);
    end else begin
      `uvm_info(get_type_name(), "exclusive request successfull", 500)

      //check if there is an associated victim buffer entry waiting to be evicted
      if(l1_pt_buffer[pt_index].vict_valid) begin
        l2_req = 1;
        l2_req_addr = l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].addr;
        l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
        req_txn_id_out = l1_pt_buffer[pt_index].vict_entry;
        `uvm_info(get_type_name(), $psprintf("found associated vict %h at %d for PTB index %d", l2_req_addr, l1_pt_buffer[pt_index].vict_entry, pt_index), 500)
        //l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
        l2_req_op = WRITE_BACK_FULL;
        excl_flag = 0;
        expcompack = 0;
      end
    end
  end else begin
    //check if there is an associated victim buffer entry waiting to be evicted
    if(l1_pt_buffer[pt_index].vict_valid) begin
      l2_req = 1;
      l2_req_addr = l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].addr;
      l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
      req_txn_id_out = l1_pt_buffer[pt_index].vict_entry;
      `uvm_info(get_type_name(), $psprintf("found associated vict %h at %d for PTB index %d", l2_req_addr, l1_pt_buffer[pt_index].vict_entry, pt_index), 500)
      //l1_vict_buffer[l1_pt_buffer[pt_index].vict_entry].transient_state = MI;
      l2_req_op = WRITE_BACK_FULL;
      excl_flag = 0;
      expcompack = 0;

    end else begin//check if there is an entry in stall queue
      if (stall_queue_entries != 0)
        replay_stall_queue(l2_req_addr);
    end
  end


  endtask: fsm_comp_ptb

  // FSM to handle comp for Victim Buffer
  task fsm_comp_vbuffer(smpl_rsp_flit_t rsp_flit);

    l1_state_e curr_state;
    int vict_index;
    logic[L1C_ADDR_WIDTH-1:0] addr;

    vict_index = rsp_flit.txn_id;
    if(rsp_flit.opcode != COMP_DBID_RESP)
      `uvm_fatal(get_type_name(),  
        $psprintf("received invalid opcode %s for vbuffer", rsp_flit.opcode.name()))

    if(!l1_vict_buffer[vict_index].valid)
      `uvm_fatal(get_type_name(),  
        $psprintf("received comp for invalid vbuffer entry %d addr %h", vict_index, l1_vict_buffer[vict_index].addr))

    `uvm_info(get_type_name(), $psprintf("received comp for vbuffer entry %d addr %h", vict_index, l1_vict_buffer[vict_index].addr), 500)
    // send data
    l2_dat = 1;
    //dat_txn_id_out = rsp_flit.txn_id;
    dat_txn_id_out = rsp_flit.dbid;
    l2_dat_op = COPY_BACK_WR_DATA;
    dat_addr = l1_vict_buffer[vict_index].addr;
    dat_resp_out = DAT_RESP_WIDTH'(I);
    l2_send_data = l1_vict_buffer[vict_index].data;

    //remove the entry from victim buffer
    `uvm_info(get_type_name(), $psprintf("removing entry %d from vbuffer", vict_index), 500)
    l1_vict_buffer[vict_index].valid = 0;
    vict_entries--;

    if (stall_queue_entries != 0  && !exclusive_loop)
      replay_stall_queue(l2_req_addr);

  endtask: fsm_comp_vbuffer

  // replay stall queue
  task replay_stall_queue(output logic[L1C_ADDR_WIDTH-1:0] l1_stall_queue_entry_addr);

    l1_stall_queue_entry_t stall_queue_entry;
    
    if (pt_entries < L1C_PT_LIMIT && vict_entries < L1C_VB_LIMIT) begin

      read_from_stall_queue(stall_queue_entry);

      if((stall_queue_entry.op != loadlinked) || (stall_queue_entry.op == loadlinked && !pt_entries && !vict_entries)) begin

        `uvm_info(get_type_name(), $psprintf("replaying stall queue entry %h %s", stall_queue_entry.addr, stall_queue_entry.op.name()), 500)


        handle_core_req(stall_queue_entry.addr, stall_queue_entry.op, 1);
      end else
        `uvm_info(get_type_name(), $psprintf("stall queue entry %s waiting for L1 PT buffer: %d and Victim buffer : %d to be empty", stall_queue_entry.op.name(), pt_entries, vict_entries), 500)
    end else
      `uvm_info(get_type_name(), $psprintf("replaying stall queue entry %s unsuccessful, PTB (%d) or VB (%d) full", stall_queue_entry.op.name(), pt_entries, vict_entries), 500)
  l1_stall_queue_entry_addr = stall_queue_entry.addr;

  endtask: replay_stall_queue

  // add request to stall queue
  task add_to_stall_queue(l1_op_e op, logic [L1C_ADDR_WIDTH-1:0] addr);

  assert(stall_queue_entries != L1C_STALL_LIMIT) else
  `uvm_fatal(get_type_name(),
  $psprintf("trying to write to full L1 stall queue"))

  `uvm_info(get_type_name(), $psprintf("adding %s %0h to stall queue", op.name(), addr), 500)

  l1_stall_queue[stall_queue_write_index].addr = addr;
  l1_stall_queue[stall_queue_write_index].op = op;

  stall_queue_write_index++;
  stall_queue_entries++;

  if (stall_queue_write_index == L1C_STALL_LIMIT)
  stall_queue_write_index = 0;

  endtask: add_to_stall_queue

  // read request from stall queue
  task read_from_stall_queue (output l1_stall_queue_entry_t l1_stall_queue_entry);

  assert(stall_queue_entries != 0) else
  `uvm_fatal(get_type_name(),
  $psprintf("trying to read from empty L1 stall queue"))

  l1_stall_queue_entry.addr = l1_stall_queue[stall_queue_read_index].addr;
  l1_stall_queue_entry.op = l1_stall_queue[stall_queue_read_index].op;

  endtask: read_from_stall_queue

  // remove request from stall queue
  task remove_from_stall_queue;

  assert(stall_queue_entries != 0) else
  `uvm_fatal(get_type_name(),
  $psprintf("trying to read from empty L1 stall queue"))

  `uvm_info(get_type_name(), $psprintf("Entry %d removed from stall queue", stall_queue_read_index), 500)

  stall_queue_read_index++;
  stall_queue_entries--;

  if (stall_queue_read_index == L1C_STALL_LIMIT)
  stall_queue_read_index = 0;

  endtask: remove_from_stall_queue

  // check if the addr is in stall queue
  function bit is_stallq_hit (logic [L1C_ADDR_WIDTH-1:0] addr);
  bit stallq_hit = 0;
  int j = stall_queue_read_index;

  for(int i=0;i<stall_queue_entries;i++) begin
  if(l1_stall_queue[j].addr[L1C_ADDR_WIDTH-1:3] == addr[L1C_ADDR_WIDTH-1:3]) begin
  `uvm_info(get_type_name(),
  $psprintf("addr:%h hit in stall queue",
  addr), 500)
  stallq_hit = 1;
  break;
  end
  j++;
  if (j == L1C_STALL_LIMIT)
  j = 0;
  end

  return stallq_hit;
  endfunction: is_stallq_hit

  // change the transient state in pending transaction buffer
  function void change_ptb_state (logic [L1C_INDEX_WIDTH-1:0] index, int way, l1_state_e transient_state);

  int pt_entry = -1;

  for(int i=0;i<L1C_PT_LIMIT;i++) begin
  if(l1_pt_buffer[i].addr[L1C_OFFSET +: L1C_INDEX_WIDTH] == index && l1_pt_buffer[i].way == way && l1_pt_buffer[i].valid) begin
  pt_entry = i;
  break;
  end
  end

  if(pt_entry < 0) begin
  `uvm_fatal(get_type_name(),
  $psprintf("There should have been a valid PT Buffer entry for index %d way %d state %s", index, way, state_store[index][way]))
  end

  l1_pt_buffer[pt_entry].transient_state = transient_state;

  return;

  endfunction: change_ptb_state

  // add request to pending transaction buffer
  function int add_to_ptb (logic [L1C_ADDR_WIDTH-1:0] addr, int way, l1_state_e transient_state, bit vict_valid, int vict_entry, bit compack);

  int pt_insert_entry = -1;

  for(int i=0;i<L1C_PT_LIMIT;i++) begin
  if(l1_pt_buffer[i].valid == 0) begin
  pt_insert_entry = i;
  break;
  end
  end

  if(pt_insert_entry != -1) begin

  l1_pt_buffer[pt_insert_entry].addr = addr;
  l1_pt_buffer[pt_insert_entry].way = way;
  l1_pt_buffer[pt_insert_entry].transient_state = transient_state;
  l1_pt_buffer[pt_insert_entry].valid = 1;
  l1_pt_buffer[pt_insert_entry].vict_valid = vict_valid;
  l1_pt_buffer[pt_insert_entry].vict_entry = vict_entry;
  l1_pt_buffer[pt_insert_entry].compack = compack;
  if(vict_valid)
  l1_vict_buffer[vict_entry].pt_index = pt_insert_entry;
  pt_entries++;
  end

  `uvm_info(get_type_name(), $psprintf("PT index: %d vict_valid: %d vict_entry: %d", pt_insert_entry, vict_valid, vict_entry), 500)

  return pt_insert_entry;

  endfunction: add_to_ptb

  // check if the addr is in ptb
  function int is_ptb_hit (logic [L1C_INDEX_WIDTH-1:0] index, logic [L1C_TAG_WIDTH-1:0] tag);
    int pt_entry = -1;

    for(int i=0;i<L1C_PT_LIMIT;i++) begin
      if(l1_pt_buffer[i].addr[L1C_OFFSET +: L1C_INDEX_WIDTH] == index && l1_pt_buffer[i].addr[(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH] == tag && l1_pt_buffer[i].valid) begin
        `uvm_info(get_type_name(),
        $psprintf("index: %h tag:%h hit in ptb entry %d",
          index, tag, i), 500)
        pt_entry = i;
        break;
      end
    end

    return pt_entry;
    endfunction: is_ptb_hit

  // remove pending transaction buffer entry
  function void remove_from_ptb (int pt_index);

    assert(pt_index < L1C_PT_LIMIT) else
      `uvm_fatal(get_type_name(),
        $psprintf("Incorrect PT Index"))


    l1_pt_buffer[pt_index].valid = 0;
    pt_entries--;

    `uvm_info(get_type_name(), $psprintf("entry %d removed from PTB", pt_index), 500)

  endfunction: remove_from_ptb

  // add replacement to victim buffer
  function int add_to_vbuffer (logic [L1C_ADDR_WIDTH-1:0] addr, logic [L1C_DATA_WIDTH-1:0] data);

    int vb_insert_entry = -1;

    for(int i=L1C_PT_LIMIT;i<L1C_VB_LIMIT+L1C_PT_LIMIT;i++) begin
      if(l1_vict_buffer[i].valid == 0) begin
        vb_insert_entry = i;
        break;
      end
    end

    if(vb_insert_entry != -1) begin

      l1_vict_buffer[vb_insert_entry].addr = addr;
      l1_vict_buffer[vb_insert_entry].data = data;
      l1_vict_buffer[vb_insert_entry].transient_state = UniqueDirty;
      l1_vict_buffer[vb_insert_entry].valid = 1;
      vict_entries++;
      `uvm_info(get_type_name(), $psprintf("Addr %h added to Victim buffer at %d", addr, vb_insert_entry), 500)
    end else 
      `uvm_fatal(get_type_name(), $psprintf("L1 victim buffer full"))

    return vb_insert_entry;

  endfunction: add_to_vbuffer
  // check if the addr is in victim buffer
  function int is_vbuffer_hit (logic [L1C_INDEX_WIDTH-1:0] index, logic [L1C_TAG_WIDTH-1:0] tag);
    int vbuffer_entry = -1;

    for(int i=L1C_PT_LIMIT;i<L1C_VB_LIMIT+L1C_PT_LIMIT;i++) begin
      if(l1_vict_buffer[i].addr[L1C_OFFSET +: L1C_INDEX_WIDTH] == index && l1_vict_buffer[i].addr[(L1C_OFFSET + L1C_INDEX_WIDTH) +: L1C_TAG_WIDTH] == tag && l1_vict_buffer[i].valid) begin
        `uvm_info(get_type_name(),
        $psprintf("index: %h tag:%h hit in vict buffer entry %d",
          index, tag, i), 500)
        vbuffer_entry = i;
        break;
      end
    end

    return vbuffer_entry;
  endfunction: is_vbuffer_hit

  function bit stall_pipeline();

  if(pipeline_stalled) begin
    if (stall_queue_entries < L1C_STALL_LIMIT/4 && pt_entries < L1C_PT_LIMIT/4 && vict_entries < L1C_VB_LIMIT/4)
      pipeline_stalled = 0;
    end else begin
      if ((stall_queue_entries >= L1C_STALL_LIMIT-8) || (pt_entries >= L1C_PT_LIMIT-8) || (vict_entries >= L1C_VB_LIMIT-8))
        pipeline_stalled = 1;
      end
    return pipeline_stalled;
  endfunction: stall_pipeline

  task llsc_loop_end;
  if (lp_monitor) begin
  `uvm_info(get_type_name(), "lp_monitor valid", 500)
  lp_monitor = 0;
  handle_core_req(excl_addr, storeconditional, 0);
  end else begin
  `uvm_info(get_type_name(), "lp_monitor invalid, executing loadlinked", 500)
  handle_core_req(excl_addr, loadlinked, 0);
  end

  endtask: llsc_loop_end

endclass: rnf_model

