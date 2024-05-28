package llc_hn_sim_pkg; 
    import uvm_pkg::*;
    import l1c_mems_config_pkg::*;
    import llc_common_pkg::*;
    import chi_package::*;  
    import llc_config_pkg::*; 

    virtual interface clk_rst_interface global_clk_rst_if; 

    // channels from LLC to NoC: 
    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   global_req_noc2hn_if; 
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  global_rsp_noc2hn_if; 
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      global_dat_noc2hn_if; 

    // channels from NoC to LLC 
    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   global_req_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  global_rsp_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      global_dat_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(snoop_flit_t))     global_snp_hn2noc_if; 


    parameter int HALF_CLK_P = 5;
    parameter int CLK_P = 2 * HALF_CLK_P;  

    localparam int NUM_SIM_CORES = 1;

    typedef logic [NUM_SIM_CORES-1:0] bitmask_numcores_t;
  
    class fence_class extends uvm_object;
        semaphore sema;
        bitmask_numcores_t mask;

        function new(string name = "");
            super.new(name);
            sema = new(1);
            mask = 0;
        endfunction
    
    endclass: fence_class

    typedef enum {load, store, storeall, evict, evictclean, getclean, vectorload, vectorstore, vectorstoreptl, vectorload_noalloc, vectorstore_noalloc, atomic, makeinvalid, cleaninvalid, loadlinked, nop, storeconditional, fence, rdstlq, snpunique, snpcleaninvalid, snpmakeinvalid, snpshared, snponce, compdbidresp, dbidresp, compdata, comp, compack} l1_op_e;
    typedef enum {l1_Invalid, l1_UniqueClean, l1_UniqueDirty, l1_SharedClean} l1_chi_state_e;


    typedef struct packed {
      logic [NID_W-1:0]       src_id;
      logic [NID_W-1:0]       tgt_id;
      logic [TXNID_W-1:0]     txn_id;
      request_opcode_e        opcode;
      logic [ADDR_W-1:0]      addr;
      logic                   excl; //-- for exlusive transactions, snoopme for atomic transactions
      logic                   alloc; //-- for readonce and writeunique transactions
      logic                   exp_comp_ack;
    } smpl_req_flit_t;

    typedef struct packed {
      logic [NID_W-1:0]       tgt_id;
      logic [NID_W-1:0]       src_id;
      logic [TXNID_W-1:0]     txn_id;
      logic [TXNID_W-1:0]     dbid;
      response_opcode_e       opcode;
      logic [ADDR_W-1:0]      addr; // For DEBUG
      logic [1:0]             resp_err;
      logic [2:0]             resp;
      logic                   rsp_type; //response type (1: With Data, 0: Dataless)
    } smpl_rsp_flit_t;

    typedef struct packed {
      logic [NID_W-1:0]       src_id;
      logic [TXNID_W-1:0]     txn_id;
      snoop_opcode_e          opcode;
      logic [ADDR_W-4:0]      addr;
      logic [NID_W-1:0]       tgt_id;
    } smpl_snp_flit_t;
    // TODO: change tgt_id into tgt_mask

    typedef struct packed {
      logic [NID_W-1:0]         tgt_id;
      logic [NID_W-1:0]         src_id;
      logic [TXNID_W-1:0]       txn_id;
      data_opcode_e             opcode;
      logic [ADDR_W-1:0]        addr; // For DEBUG
      logic [1:0]               rsp_err;
      logic [2:0]               rsp;
      logic [DATA_W-1:0]        data;
      logic [((DATA_W)/8)-1:0]  be;
      logic [TXNID_W-1:0]       dbid;
    } smpl_data_flit_t;
    
  `include "uvm_macros.svh"
  `include "uvm_seq_macros.svh"

  // uvm_transactions
  `include "l1_req.svh"
  `include "l1_seq.svh"
  `include "l1_seq1.svh"
  `include "l1_seq2.svh"
  `include "l1_seq3.svh"
  `include "l1_input.svh"
  `include "l1_output.svh"
  `include "req_trans.svh"
  `include "rsp_trans.svh"
  `include "dat_trans.svh"
  `include "snp_trans.svh"

  // uvm_agents 
  `include "driver.svh"
  `include "dut_driver.svh"
  `include "rnf_model.svh"
  `include "noc_delay_model.svh"
  `include "noc_model.svh"
  `include "sn_model.svh"
  `ifdef refmodel
    `include "monitor.svh"
    `include "predictor.svh"
    `include "comparator.svh"
  `endif


  // uvm_envs
  `include "tester_env.svh"

  // uvm_tests  
  `include "llc_test.svh"
  `include "test_i.svh"

  //uvm_tests_end

endpackage
