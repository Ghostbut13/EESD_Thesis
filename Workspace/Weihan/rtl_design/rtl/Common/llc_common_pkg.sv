package llc_common_pkg; 
    import llc_config_pkg::*; 
    import chi_package::*;

    typedef struct packed {
        logic                       hit; 
        logic                       clean; 
        logic [LLC_ADDR_WIDTH-1:0]  addr;
        logic [LLC_TAG_WIDTH-1:0]   tag;
        logic [LLC_INDEX_WIDTH-1:0] index;
        request_opcode_e            opcode; 
        logic                       replay; 
        logic                       valid;
        logic [TXNID_W-1:0]         txn_id; 
    } req_info_t; 

    // ------------------- data-buff:
    typedef struct packed {
        logic   valid;
        logic   do_replay; 
        logic   snp_data; 
    } data_buff_info_t;

    // -------------------- victim:
    typedef struct packed {
        logic                       valid; 
        logic                       clean;
        logic [LLC_ADDR_WIDTH-1:0]  addr;        
    } vict_info_t; 

    typedef enum logic[2:0]{
        RESET, 
        EMPTY, 
        WAIT_SNP_RSP, 
        WAIT_DBID, 
        WRITEBACK
    } vict_buff_state_t; 
    
    typedef struct packed{
        logic                       valid; 
        vict_buff_state_t           state;
        logic [TXNID_W-1:0]         dbid; 
        logic [LLC_ADDR_WIDTH-1:0]  addr; 
        logic                       clean; 
    } vict_buff_info_t;

    typedef struct packed {
        logic   [TXNID_W-1:0]   dbid; 
        logic                   dbid_v; 
        logic                   snprsp_v; 
    } rsp2vb_info_t;

    // =================== reduction functions ===================
    
    function logic [LLC_TAG_WIDTH-1:0] filter_tag (input logic [LLC_ADDR_WIDTH-1:0] addr); 
        return addr[LLC_ADDR_WIDTH-1 -: LLC_TAG_WIDTH]; 
    endfunction : filter_tag

    function logic [LLC_INDEX_WIDTH-1:0] filter_index (input logic [LLC_ADDR_WIDTH-1:0] addr); 
        return addr[(LLC_ADDR_WIDTH-LLC_TAG_WIDTH)-1 -: LLC_INDEX_WIDTH]; 
    endfunction : filter_index

    function logic [LLC_ADDR_WIDTH-1:0] zero_offset_addr(input logic [LLC_ADDR_WIDTH-1:0] addr); 
        return {addr[LLC_ADDR_WIDTH-1:LLC_OFFSET], 6'b000000}; 
    endfunction : zero_offset_addr

    /*******************************************************************************
    *
    * L1 Stable State definitions
    * Values match with Resp field encodings in Table 4-4, 4-5 and 12-36 in ARM CHI Spec
    *
    ******************************************************************************/
  typedef enum logic [2:0] {
      I         = 3'h0,
      SC        = 3'h1,
      UC        = 3'h2
  } l1_state_e;

  /*******************************************************************************
   *
   * Response Error Value
   *
   ******************************************************************************/
  typedef enum logic [1:0] {
      OK           = 2'h0,
      X_OK         = 2'h1,
      DATA_ERR     = 2'h2,
      NON_DATA_ERR = 2'h3
  } l2_resperr_e;

  /*******************************************************************************
   *
   * CHI interface parameters: TODO Remove after added to Noc-Interface.sv
   *
   ******************************************************************************/
    localparam int unsigned REQ_QOS_WIDTH = 1;
    localparam int unsigned REQ_TGTID_WIDTH = chi_package::NID_W;
    localparam int unsigned REQ_SRCID_WIDTH = chi_package::NID_W;
    localparam int unsigned REQ_TXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned REQ_RETURNNID_WIDTH = chi_package::NID_W;
    localparam int unsigned REQ_RETURNTXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned REQ_OPCODE_WIDTH = 7;
    localparam int unsigned REQ_SIZE_WIDTH = 3;
    localparam int unsigned REQ_ADDR_WIDTH = chi_package::ADDR_W;
    localparam int unsigned REQ_MEMATTR_WIDTH = 4;
    localparam int unsigned REQ_SNPATTR_WIDTH = 1;
    localparam int unsigned REQ_EXCL_WIDTH = 1;
    localparam int unsigned REQ_EXPCOMPACK_WIDTH = 1;

    localparam int unsigned RSP_QOS_WIDTH = 1;
    localparam int unsigned RSP_TGTID_WIDTH = chi_package::NID_W;
    localparam int unsigned RSP_SRCID_WIDTH = chi_package::NID_W;
    localparam int unsigned RSP_TXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned RSP_OPCODE_WIDTH = 5;
    localparam int unsigned RSP_RESPERR_WIDTH = 2;
    localparam int unsigned RSP_RESP_WIDTH = 3;
    localparam int unsigned RSP_FWDSTATE_WIDTH = 3;
    localparam int unsigned RSP_DBID_WIDTH = chi_package::TXNID_W;

    localparam int unsigned DAT_QOS_WIDTH = 1;
    localparam int unsigned DAT_TGTID_WIDTH = chi_package::NID_W;
    localparam int unsigned DAT_SRCID_WIDTH = chi_package::NID_W;
    localparam int unsigned DAT_TXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned DAT_HOMENID_WIDTH = chi_package::NID_W;
    localparam int unsigned DAT_OPCODE_WIDTH = 4;
    localparam int unsigned DAT_RESPERR_WIDTH = 2;
    localparam int unsigned DAT_RESP_WIDTH = 3;
    localparam int unsigned DAT_FWDSTATE_WIDTH = 3;
    localparam int unsigned DAT_DBID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned DAT_BE_WIDTH = 64;
    localparam int unsigned DAT_DATA_WIDTH = 512;

    localparam int unsigned SNP_QOS_WIDTH = 1;
    localparam int unsigned SNP_TGTID_WIDTH = chi_package::SNP_W;
    localparam int unsigned SNP_SRCID_WIDTH = chi_package::NID_W;
    localparam int unsigned SNP_TXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned SNP_FWDNID_WIDTH = chi_package::NID_W;
    localparam int unsigned SNP_FWDTXNID_WIDTH = chi_package::TXNID_W;
    localparam int unsigned SNP_OPCODE_WIDTH = 5;
    localparam int unsigned SNP_ADDR_WIDTH = chi_package::ADDR_W-3;
    localparam int unsigned SNP_DONOTDATAPULL_WIDTH = 1;
    localparam int unsigned SNP_RETTOSRC_WIDTH = 1;


    localparam int unsigned REQ_FLIT_WIDTH = REQ_QOS_WIDTH + REQ_TGTID_WIDTH + REQ_SRCID_WIDTH + REQ_TXNID_WIDTH + REQ_RETURNNID_WIDTH + REQ_RETURNTXNID_WIDTH + REQ_OPCODE_WIDTH + REQ_SIZE_WIDTH + REQ_ADDR_WIDTH + REQ_MEMATTR_WIDTH + REQ_SNPATTR_WIDTH + REQ_EXCL_WIDTH + REQ_EXPCOMPACK_WIDTH;
    localparam int unsigned RSP_FLIT_WIDTH = RSP_QOS_WIDTH + RSP_TGTID_WIDTH + RSP_SRCID_WIDTH + RSP_TXNID_WIDTH + RSP_OPCODE_WIDTH + RSP_RESPERR_WIDTH + RSP_RESP_WIDTH + RSP_FWDSTATE_WIDTH + RSP_DBID_WIDTH;
    localparam int unsigned DAT_FLIT_WIDTH = DAT_QOS_WIDTH + DAT_TGTID_WIDTH + DAT_SRCID_WIDTH + DAT_TXNID_WIDTH + DAT_HOMENID_WIDTH + DAT_OPCODE_WIDTH + DAT_RESPERR_WIDTH + DAT_RESP_WIDTH + DAT_FWDSTATE_WIDTH + DAT_DBID_WIDTH + DAT_BE_WIDTH + DAT_DATA_WIDTH;
    localparam int unsigned SNP_FLIT_WIDTH = SNP_QOS_WIDTH + SNP_TGTID_WIDTH + SNP_SRCID_WIDTH + SNP_TXNID_WIDTH + SNP_FWDNID_WIDTH + SNP_FWDTXNID_WIDTH + SNP_OPCODE_WIDTH + SNP_ADDR_WIDTH + SNP_DONOTDATAPULL_WIDTH + SNP_RETTOSRC_WIDTH;


    //************************************* Node IDs: 

    parameter logic [NID_W-1:0]   RN_ID = 0; //noticed
    parameter logic [NID_W-1:0]   HN_ID = 32;//noticed 
    parameter logic [NID_W-1:0]   SN_ID = 64;//noticed
    parameter logic [SNP_W-1:0]   RN_MSK_SNP = 1; 

    parameter logic [TXNID_W-1:0] LLC_VictBuff_ID = 129; 
    parameter logic [TXNID_W-1:0] LLC_ReqBUff_ID = 0; 

endpackage: llc_common_pkg
