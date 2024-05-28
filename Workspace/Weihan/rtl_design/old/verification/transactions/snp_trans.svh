class snp_trans extends uvm_transaction; 
    `uvm_object_utils(snp_trans)

    smpl_snp_flit_t snp_flit;

    function new(string name = "");
        super.new(name);
    endfunction : new

    function string convert2string();
        return $psprintf("<< src id: %d, tgt id: %d, txn id: %d, opcode: %s, addr: %h, addr+000: %h>>",snp_flit.src_id, snp_flit.tgt_id, snp_flit.txn_id, snp_flit.opcode.name(), snp_flit.addr, {snp_flit.addr, 3'b000});
    endfunction : convert2string

    function void do_copy(uvm_object rhs);
        snp_trans RHS;
        super.do_copy(rhs);
        $cast(RHS,rhs);
        snp_flit = RHS.snp_flit;
    endfunction : do_copy

    function bit comp (uvm_object rhs);
        snp_trans RHS;
        $cast (RHS,rhs);
        return (RHS.snp_flit == snp_flit);
    endfunction : comp

    function void load_data (smpl_snp_flit_t snp_fl);
        snp_flit = snp_fl;
    endfunction : load_data

    function void load_flit (snoop_flit_t sn_fl);
        //snp_flit.tgt_id = sn_fl.tgt_mask;
        snp_flit.tgt_id = RN_ID; //currently we only have one core
        snp_flit.src_id = sn_fl.src_id;
        snp_flit.txn_id = sn_fl.txn_id;
        snp_flit.opcode = sn_fl.opcode;
        snp_flit.addr = sn_fl.addr;
    endfunction : load_flit

endclass : snp_trans
