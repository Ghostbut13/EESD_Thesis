class rsp_trans extends uvm_transaction; 
    `uvm_object_utils(rsp_trans)

    smpl_rsp_flit_t rsp_flit;

    function new(string name = "");
        super.new(name);
    endfunction : new

    function string convert2string();
        //return $psprintf("src id: %d tgt id: %d txn id: %d rsp_addr: %h opcode: %s resp: %s",rsp_flit.src_id, rsp_flit.tgt_id, rsp_flit.txn_id, rsp_flit.addr, rsp_flit.opcode.name(), l1_state_e'(rsp_flit.resp));
        return $psprintf("<< src id: %d, tgt id: %d, txn id: %d, addr: %h, opcode: %s, resp: %h,  dbid: %h, rsp_err: %h, rsp_type: %h >>",rsp_flit.src_id, rsp_flit.tgt_id, rsp_flit.txn_id, rsp_flit.addr, rsp_flit.opcode.name(), rsp_flit.resp, rsp_flit.dbid, rsp_flit.resp_err, rsp_flit.rsp_type);
    endfunction : convert2string

    function void do_copy(uvm_object rhs);
        rsp_trans RHS;
        super.do_copy(rhs);
        $cast(RHS,rhs);
        rsp_flit = RHS.rsp_flit;
    endfunction : do_copy

    function bit comp (uvm_object rhs);
        rsp_trans RHS;
        $cast (RHS,rhs);
        return (RHS.rsp_flit == rsp_flit);
    endfunction : comp

    function void load_data (smpl_rsp_flit_t rs_fl);
        rsp_flit = rs_fl;
    endfunction : load_data

    function void load_flit (response_flit_t rs_fl);
        rsp_flit.tgt_id = rs_fl.tgt_id;
        rsp_flit.src_id = rs_fl.src_id;
        rsp_flit.txn_id = rs_fl.txn_id;
        rsp_flit.dbid = rs_fl.dbid;
        rsp_flit.opcode = rs_fl.opcode;
        rsp_flit.resp_err   = rs_fl.resp_err;
        rsp_flit.resp = rs_fl.resp;
        rsp_flit.rsp_type = 0;
        rsp_flit.addr = 0;
    endfunction : load_flit

    function void offload_flit(ref response_flit_t rs_fl); 
        rs_fl.src_id    =rsp_flit.src_id;
        rs_fl.tgt_id    =rsp_flit.tgt_id;
        rs_fl.txn_id    =rsp_flit.txn_id;
        rs_fl.dbid      =rsp_flit.dbid;
        rs_fl.opcode    =rsp_flit.opcode;
        rs_fl.resp      =rsp_flit.resp;
        rs_fl.trace_tag = 0; // mem tagging not supported
        rs_fl.tag_op    = 0; // mem tagging not supported 
        rs_fl.pcrd_type = 0; // retry not supported 
        rs_fl.cbusy     = 0; // not supported 
        rs_fl.fwd_state = 0; // not supported 
        rs_fl.resp_err  = 0; // Normal: no error 
        rs_fl.qos       = '{default: 1}; // set max prio (same for all messages);
    endfunction : offload_flit

endclass : rsp_trans
