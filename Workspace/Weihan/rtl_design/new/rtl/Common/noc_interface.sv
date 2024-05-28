// =============================================================================
//
//            Copyright (c) 2022 CHALMERS University of Technology
//                             All rights reserved
//
// This file contains CHALMERS proprietary and confidential information 
// and has been developed by CHALMERS within the EUMMSS Project. 
//
// ===============================[ INFORMATION ]===============================
//
// Author(s)  : Madhavan Manivannan, Bhavishya Goel
// Contact(s) : madhavan@chalmers.se, goelb@chalmers.se
//
// Summary    : 
// Created    : June 13, 2023
// Modified   : June 21, 2023
//
// ===============================[ DESCRIPTION ]===============================
//
// Package for Noc interface specification based on CHI rev. F (chapter 13)
//
// =============================================================================

package chi_package;

    localparam int unsigned QOS_W = 4;
    localparam int unsigned NID_W = 7; //allowed: 7 to 11
    localparam int unsigned TXNID_W = 12;
    localparam int unsigned SNP_W = 8;
    localparam int unsigned ADDR_W = 48; //allowed: 44 to 52
    localparam int unsigned PCRDTYPE_W = 4;
    localparam int unsigned TAGOP_W = 2;
    localparam int unsigned DATA_W = 512;

    typedef enum logic [6:0] {
        REQ_LCRD_RETURN                          =          7'h0  ,
        READ_SHARED                              =          7'h1  , //noticed
        READ_CLEAN                               =          7'h2  ,
        READ_ONCE                                =          7'h3  ,
        READ_NO_SNP                              =          7'h4  , //noticed
        PC_RD_RETURN                             =          7'h5  ,
        READ_UNIQUE                              =          7'h7  , //noticed
        CLEAN_SHARED                             =          7'h8  ,
        CLEAN_INVALID                            =          7'h9  ,
        MAKE_INVALID                             =          7'ha  ,
        CLEAN_UNIQUE                             =          7'hb  ,
        MAKE_UNIQUE                              =          7'hc  ,
        EVICT                                    =          7'hd  ,
        READ_NO_SNP_SEP                          =          7'h11 ,
        CLEAN_SHARED_PERSIST_SEP                 =          7'h13 ,
        DVM_OP                                   =          7'h14 ,
        WRITE_EVICT_FULL                         =          7'h15 ,
        WRITE_CLEAN_FULL                         =          7'h17 ,
        WRITE_UNIQUE_PTL                         =          7'h18 ,
        WRITE_UNIQUE_FULL                        =          7'h19 ,
        WRITE_BACK_PTL                           =          7'h1a ,
        WRITE_BACK_FULL                          =          7'h1b , //noticed
        WRITE_NO_SNP_PTL                         =          7'h1c ,
        WRITE_NO_SNP_FULL                        =          7'h1d ,
        WRITE_UNIQUE_FULL_STASH                  =          7'h20 ,
        WRITE_UNIQUE_PTL_STASH                   =          7'h21 ,
        STASH_ONCE_SHARED                        =          7'h22 ,
        STASH_ONCE_UNIQUE                        =          7'h23 ,
        READ_ONCE_CLEAN_INVALID                  =          7'h24 ,
        READ_ONCE_MAKE_INVALID                   =          7'h25 ,
        READ_NOT_SHARED_DIRTY                    =          7'h26 ,
        CLEAN_SHARED_PERSIST                     =          7'h27 ,
        ATOMIC_STORE_ADD                         =          7'h28 ,
        ATOMIC_STORE_CLR                         =          7'h29 ,
        ATOMIC_STORE_EOR                         =          7'h2a ,
        ATOMIC_STORE_SET                         =          7'h2b ,
        ATOMIC_STORE_SMAX                        =          7'h2c ,
        ATOMIC_STORE_SMIN                        =          7'h2d ,
        ATOMIC_STORE_UMAX                        =          7'h2e ,
        ATOMIC_STORE_UMIN                        =          7'h2f ,
        ATOMIC_LOAD_ADD                          =          7'h30 ,
        ATOMIC_LOAD_CLR                          =          7'h31 ,
        ATOMIC_LOAD_EOR                          =          7'h32 ,
        ATOMIC_LOAD_SET                          =          7'h33 ,
        ATOMIC_LOAD_SMAX                         =          7'h34 ,
        ATOMIC_LOAD_SMIN                         =          7'h35 ,
        ATOMIC_LOAD_UMAX                         =          7'h36 ,
        ATOMIC_LOAD_UMIN                         =          7'h37 ,
        ATOMIC_SWAP                              =          7'h38 ,
        ATOMIC_COMPARE                           =          7'h39 ,
        PREFETCH_TGT                             =          7'h3a ,
        MAKE_READ_UNIQUE                         =          7'h41 ,
        WRITE_EVICT_OR_EVICT                     =          7'h42 ,
        WRITE_UNIQUE_ZERO                        =          7'h43 ,
        WRITE_NO_SNP_ZERO                        =          7'h44 ,//noticed
        STASH_ONCE_SEP_SHARED                    =          7'h47 ,
        STASH_ONCE_SEP_UNIQUE                    =          7'h48 ,
        READ_PREFER_UNIQUE                       =          7'h4C ,
        CLEAN_INVALID_POPA                       =          7'h4D ,
        WRITE_NO_SNP_DEF                         =          7'h4E ,//noticed
        WRITE_NO_SNP_FULL_CLEAN_SH               =          7'h50 ,
        WRITE_NO_SNP_FULL_CLEAN_INV              =          7'h51 ,
        WRITE_NO_SNP_FULL_CLEAN_SH_PER_SEP       =          7'h52 ,
        WRITE_UNIQUE_FULL_CLEAN_SH               =          7'h54 ,
        WRITE_UNIQUE_FULL_CLEAN_SH_PER_SEP       =          7'h56 ,
        WRITE_BACK_FULL_CLEAN_SH                 =          7'h58 ,
        WRITE_BACK_FULL_CLEAN_INV                =          7'h59 ,
        WRITE_BACK_FULL_CLEAN_SH_PER_SEP         =          7'h5A ,
        WRITE_CLEAN_FULL_CLEAN_SH                =          7'h5C ,
        WRITE_CLEAN_FULL_CLEAN_SH_PER_SEP        =          7'h5E ,
        WRITE_NO_SNP_PTL_CLEAN_SH                =          7'h60 ,
        WRITE_NO_SNP_PTL_CLEAN_INV               =          7'h61 ,
        WRITE_NO_SNP_PTL_CLEAN_SH_PER_SEP        =          7'h62 ,
        WRITE_UNIQUE_PTL_CLEAN_SH                =          7'h64 ,
        WRITE_UNIQUE_PTL_CLEAN_SH_PER_SEP        =          7'h66 ,
        WRITE_NO_SNP_PTL_CLEAN_INV_POPA          =          7'h70 ,
        WRITE_NO_SNP_FULL_CLEAN_INV_POPA         =          7'h71 ,
        WRITE_BACK_FULL_CLEAN_INV_POPA           =          7'h79 
    } request_opcode_e; //noticed

    typedef enum logic [4:0] {
        RESP_LCRD_RETURN    =          5'h0,
        SNP_RESP            =          5'h1, //NOTICED
        COMP_ACK            =          5'h2, //NOTICED
        RETRY_ACK           =          5'h3,
        COMP                =          5'h4, //NOTICED
        COMP_DBID_RESP      =          5'h5, //NOTICED
        DBID_RESP           =          5'h6, //NOTICED
        PC_RD_GRANT         =          5'h7,
        READ_RECEIPT        =          5'h8,
        SNP_RESP_FWDED      =          5'h9,
        TAG_MATCH           =          5'hA,
        RESP_SEP_DATA       =          5'hB, //NOTICED
        PERSIST             =          5'hC,
        COMP_PERSIST        =          5'hD,
        DBID_RESP_ORD       =          5'hE,
        STASH_DONE          =          5'h10,
        COMP_STASH_DONE     =          5'h11,
        COMP_CMO            =          5'h14
    } response_opcode_e;//NOTICED

    typedef enum logic [4:0] {
        SNP_LCRD_RETURN               =          5'h0,
        SNP_SHARED                    =          5'h1, //NOTICED
        SNP_CLEAN                     =          5'h2, 
        SNP_ONCE                      =          5'h3,
        SNP_NOT_SHARED_DIRTY          =          5'h4,
        SNP_UNIQUE_STASH              =          5'h5,
        SNP_MAKE_INVALID_STASH        =          5'h6,
        SNP_UNIQUE                    =          5'h7, //NOTICED
        SNP_CLEAN_SHARED              =          5'h8,
        SNP_CLEAN_INVALID             =          5'h9,
        SNP_MAKE_INVALID              =          5'hA,
        SNP_STASH_UNIQUE              =          5'hB,
        SNP_STASH_SHARED              =          5'hC,
        SNP_DVM_OP                    =          5'hD,
        SNP_QUERY                     =          5'h10,
        SNP_SHARED_FWD                =          5'h11,
        SNP_CLEAN_FWD                 =          5'h12,
        SNP_ONCE_FWD                  =          5'h13,
        SNP_NOT_SHARED_DIRTY_FWD      =          5'h14,
        SNP_PREFER_UNIQUE             =          5'h15,
        SNP_PREFER_UNIQUE_FWD         =          5'h16,
        SNP_UNIQUE_FWD                =          5'h17
    } snoop_opcode_e;

    typedef enum logic [3:0] {
        DATA_LCRD_RETURN           =          4'h0,
        SNP_RSP_DATA               =          4'h1,//NOTICED
        COPY_BACK_WR_DATA          =          4'h2,//NOTICED
        NON_COPY_BACK_WR_DATA      =          4'h3,//NOTICED
        COMP_DATA                  =          4'h4,//NOTICED
        SNP_RESP_DATA_PTL          =          4'h5,
        SNP_RESP_DATA_FWDED        =          4'h6,
        WRITE_DATA_CANCEL          =          4'h7,
        DATA_SEP_RESP              =          4'hb,//NOTICED
        NCB_WR_DATA_COMP_ACK       =          4'hc
    } data_opcode_e;




   // flit
    typedef struct packed {
        //No RSVDC bus
        //No PBHA bus
        //No MPAM bus
        logic trace_tag;
        logic [TAGOP_W-1:0] tag_op;
        logic exp_comp_ack;
        logic excl;
        logic [7:0] persistence_gid;
        logic snp_attr;
        logic [3:0] mem_attr;
        logic [PCRDTYPE_W-1:0] pcrd_type;
        logic [1:0] order;
        logic allow_retry;
        logic likely_shared;
        logic non_secure_ext;
        logic non_secure;
        logic [ADDR_W-1:0] addr;
        logic [2:0] size;
        request_opcode_e opcode;
        logic [TXNID_W-1:0] return_txn_id;
        logic stash_nid_valid;
        logic [NID_W-1:0] return_nid;
        logic [TXNID_W-1:0] txn_id;
        logic [NID_W-1:0] src_id;
        logic [NID_W-1:0] tgt_id;
        logic [QOS_W-1:0] qos;
    } request_flit_t;

    typedef struct packed {
        logic trace_tag;
        logic [TAGOP_W-1:0] tag_op;
        logic [PCRDTYPE_W-1:0] pcrd_type;
        logic [TXNID_W-1:0] dbid;
        logic [2:0] cbusy;
        logic [2:0] fwd_state;
        logic [2:0] resp;
        logic [1:0] resp_err;
        response_opcode_e opcode;
        logic [TXNID_W-1:0] txn_id;
        logic [NID_W-1:0] src_id;
        logic [NID_W-1:0] tgt_id;
        logic [QOS_W-1:0] qos;
    } response_flit_t;

    typedef struct packed {
        //No MPAM bus
        logic [SNP_W-1:0] tgt_mask;
        logic trace_tag;
        logic ret_to_src;
        logic do_not_go_to_sd;
        logic non_secure_ext;
        logic non_secure;
        logic [ADDR_W-4:0] addr;
        snoop_opcode_e opcode;
        logic [TXNID_W-1:0] fwd_txn_id;
        logic [NID_W-1:0] fwd_nid;
        logic [TXNID_W-1:0] txn_id;
        logic [NID_W-1:0] src_id;
        logic [QOS_W-1:0] qos;
    } snoop_flit_t;

    typedef struct packed {
        //No Poison
        //No DataCheck
        //No RSVDC
        logic [DATA_W-1:0] data;
        logic [((DATA_W)/8)-1:0] be;
        logic cah;
        logic trace_tag;
        logic [((DATA_W)/128)-1:0] tu;
        logic [((DATA_W)/32)-1:0] tag;
        logic [TAGOP_W-1:0] tag_op;
        logic [1:0] data_id;
        logic [1:0] cc_id;
        logic [TXNID_W-1:0] dbid;
        logic [2:0] cbusy;
        logic [4:0] data_source;
        logic [2:0] resp;
        logic [1:0] resp_err;
        data_opcode_e opcode;
        logic [NID_W-1:0] home_nid;
        logic [TXNID_W-1:0] txn_id;
        logic [NID_W-1:0] src_id;
        logic [NID_W-1:0] tgt_id;
        logic [QOS_W-1:0] qos;
    } data_flit_t;

endpackage: chi_package


/*******************************************************************************
 *
 * Parameterized CHI interface
 *
 ******************************************************************************/

interface chi_channel_inf import chi_package::*; #(
    parameter type DATA_T = request_flit_t // define the "DATA_T" FROM pool <- request/ response/ data /snoop 
    ) ();

    logic  flit_pend;
    logic  flit_v;
    DATA_T flit;

    logic lcrd_v;

    modport tx( // member variable
        output flit_pend,
        output flit_v,
        output flit,
        input  lcrd_v
    );

    modport rx( // member variable
        input  flit_pend,
        input  flit_v,
        input  flit,
        output lcrd_v
    );


    /*
    function void print(string tag="");
        $display("--- T=%0t \t [%s]---- Flit_V=%b, lcrd_v=%b, OpCode=%s, SrcID=%h, TgtID=%h, TxnID=%h, Addr=%h", 
                 $time, tag, flit_v, lcrd_v, flit.opcode.name(), flit.src_id, flit.tgt_id, flit.txn_id, flit.addr );
    endfunction 
    */

    function void print(string tag="");
        $display("--- @%0t \t [%s]---- Flit_V=%b, lcrd_v=%b, OpCode=%s, SrcID=%h, TxnID=%h", 
                 $time, tag, flit_v, lcrd_v, flit.opcode.name(), flit.src_id, flit.txn_id);
    endfunction 

endinterface : chi_channel_inf

