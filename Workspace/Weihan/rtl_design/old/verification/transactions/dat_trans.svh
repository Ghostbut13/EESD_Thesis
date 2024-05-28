class dat_trans extends uvm_transaction; 
    `uvm_object_utils(dat_trans)

    smpl_data_flit_t dat_flit;

    function new(string name = "");
        super.new(name);
    endfunction : new

    function string convert2string();
        return $psprintf("<< src id: %d, tgt id: %d, txn id: %d, opcode: %s, rsp: %h, data: %h, be: %h, dbid: %h, rsp_err: %h, addr: %h>>",dat_flit.src_id, dat_flit.tgt_id, dat_flit.txn_id, dat_flit.opcode.name(), dat_flit.rsp, dat_flit.data, dat_flit.be, dat_flit.dbid, dat_flit.rsp_err, dat_flit.addr);
    endfunction : convert2string

    function void do_copy(uvm_object rhs);
        dat_trans RHS;
        super.do_copy(rhs);
        $cast(RHS,rhs);
        dat_flit = RHS.dat_flit;
    endfunction : do_copy

    function bit comp (uvm_object rhs);
        dat_trans RHS;
        $cast (RHS,rhs);
        return (RHS.dat_flit == dat_flit);
    endfunction : comp

    function void load_data (smpl_data_flit_t d_fl);
        dat_flit = d_fl;
    endfunction : load_data

    function void load_flit (data_flit_t dt_fl);
        dat_flit.tgt_id = dt_fl.tgt_id;
        dat_flit.src_id = dt_fl.src_id;
        dat_flit.txn_id = dt_fl.txn_id;
        dat_flit.opcode = dt_fl.opcode;
        dat_flit.data  = dt_fl.data;
        dat_flit.be = dt_fl.be;
        dat_flit.rsp = dt_fl.resp;
        dat_flit.dbid = dt_fl.dbid;
        dat_flit.rsp_err = dt_fl.resp_err;
        dat_flit.addr = 0;
    endfunction : load_flit

    function void offload_flit(ref data_flit_t dt_fl);
        dt_fl.src_id        = dat_flit.src_id;
        dt_fl.tgt_id        = dat_flit.tgt_id;
        dt_fl.txn_id        = dat_flit.txn_id;
        dt_fl.opcode        = dat_flit.opcode;
        dt_fl.data          = dat_flit.data;
        dt_fl.be            = dat_flit.be;
        dt_fl.resp          = dat_flit.rsp;
        dt_fl.resp_err      = dat_flit.rsp_err;
        dt_fl.dbid          = dat_flit.dbid;
        dt_fl.cah           = 1; // inclusive assumption 
        dt_fl.trace_tag     = 0; // mem. tagging not supported 
        dt_fl.tu            = 0; // mem. tagging not supported 
        dt_fl.tag           = 0; // mem. tagging not supported 
        dt_fl.tag_op        = 0; // mem. tagging not supported 
        dt_fl.data_id       = 2'b00; // 512 bit data bus width
        dt_fl.cc_id         = 0; // doesn't matter / not supported
        dt_fl.cbusy         = 0; // not supported 
        dt_fl.data_source   = 0; // not required 
        dt_fl.home_nid      = 0; // default = 0, note: in case of HN-ID, it is already set by HN, not here. 
        dt_fl.qos           = '{default: 1}; // set max prio (same for all messages);
        assert(dat_flit.src_id != HN_ID) else
            `uvm_fatal(get_type_name(), $psprintf("offloading a flit with source = HN. The assumption is that this function is only called when flit is going toward HN. Otherwise, flit content needs to be reviewed."))
    endfunction : offload_flit

endclass : dat_trans
