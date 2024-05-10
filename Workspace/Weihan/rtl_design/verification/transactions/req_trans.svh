class req_trans extends uvm_transaction; 
    `uvm_object_utils(req_trans)

    smpl_req_flit_t req_flit;

    function new(string name = "");
        super.new(name);
    endfunction : new

    function string convert2string();
        return $psprintf("<< src id: %d, tgt id: %d, txn id: %d, opcode: %s, addr: %h, excl: %h, alloc: %h, exp_comp_ack: %h>>",req_flit.src_id, req_flit.tgt_id, req_flit.txn_id, req_flit.opcode.name(), req_flit.addr, req_flit.excl, req_flit.alloc, req_flit.exp_comp_ack);
    endfunction : convert2string

    function void do_copy(uvm_object rhs);
        req_trans RHS;
        super.do_copy(rhs);
        $cast(RHS,rhs);
        req_flit = RHS.req_flit;
    endfunction : do_copy

    function bit comp (uvm_object rhs);
        req_trans RHS;
        $cast (RHS,rhs);
        return (RHS.req_flit == req_flit);
    endfunction : comp

    function void load_data (smpl_req_flit_t rq_fl);
        req_flit = rq_fl;
    endfunction : load_data

    function void load_flit (request_flit_t rq_fl);
        req_flit.src_id = rq_fl.src_id;
        req_flit.tgt_id = rq_fl.tgt_id;
        req_flit.txn_id = rq_fl.txn_id;
        req_flit.opcode = rq_fl.opcode;
        req_flit.addr   = rq_fl.addr;
        req_flit.excl   = rq_fl.excl;
        req_flit.exp_comp_ack = rq_fl.exp_comp_ack;
        req_flit.alloc  = 0;
    endfunction : load_flit

    function void offload_flit (ref request_flit_t req_fl); 
        req_fl.src_id           = req_flit.src_id;
        req_fl.tgt_id           = req_flit.tgt_id; 
        req_fl.txn_id           = req_flit.txn_id;
        req_fl.opcode           = req_flit.opcode;
        req_fl.addr             = req_flit.addr; 
        req_fl.return_txn_id    = 0; // DMT not supported: default = 0, note: in case of HN-Buff-ID, it is already set by HN, not here.
        req_fl.return_nid       = 0; // DMT not supported: default = 0, note: in case of HN-ID, it is already set by HN, not here. 
        req_fl.trace_tag        = 0; // mem. tagging not supported 
        req_fl.tag_op           = 0; // mem. tagging not supported 
        req_fl.excl             = 0; // exclusives not supported 
        req_fl.persistence_gid  = 0; // not supported
        req_fl.mem_attr         = 4'b1100; // [Allocate, Cachable, Normal Mem., EWA not permitted]
        req_fl.pcrd_type        = 0; // retry not supported
        req_fl.order            = 0; // no ordering required 
        req_fl.allow_retry      = 0; // retry not supported 
        req_fl.likely_shared    = 0; // not supported 
        req_fl.non_secure_ext   = 0; // [NSE, NS] = 01 : Non-secure
        req_fl.non_secure       = 1; // [NSE, NS] = 01 : Non-secure
        req_fl.size             = 3'b110; // 64bytes
        req_fl.stash_nid_valid  = 0; // not supported 
        req_fl.qos              = '{default: 1}; // set max prio (same for all messages)
        case (req_flit.opcode)// Todo: these conditions may need to be updated/extended 
            READ_SHARED: begin 
                req_fl.exp_comp_ack = 1;
                req_fl.snp_attr = 1; 
            end 
            READ_NO_SNP, WRITE_NO_SNP_FULL: begin 
                req_fl.exp_comp_ack = 0;
                req_fl.snp_attr = 0; 
            end 
            default: begin 
                req_fl.exp_comp_ack = 0; 
                req_fl.snp_attr = 1; 
            end 
        endcase 
        assert(req_flit.src_id != HN_ID) else
            `uvm_fatal(get_type_name(), $psprintf("offloading a flit with source = HN. The assumption is that this function is only called when flit is going toward HN. Otherwise, flit content needs to be reviewed."))
    endfunction : offload_flit

endclass : req_trans
