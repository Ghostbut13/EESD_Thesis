typedef struct {
    logic valid;
    //logic trace_tag;
    //int tag_op;
    logic exp_comp_ack;
    logic excl;
    //int persistence_gid;
    //logic snp_attr;
    //int mem_attr;
    //int pcrd_type;
    //int order;
    //logic allow_retry;
    //logic likely_shared;
    //logic non_secure_ext;
    //logic non_secure;
    longint addr;
    //int size;
    int opcode;
    //int return_txn_id;
    //logic stash_nid_valid;
    //int return_nid;
    int txn_id;
    int src_id;
    int tgt_id;
    //int qos;
    logic alloc; //-- for readonce and writeunique transactions
} req_struct;

typedef struct {
    logic valid;
    //logic trace_tag;
    //int tag_op;
    //int pcrd_type;
    int dbid;
    //int cbusy;
    //int fwd_state;
    int resp;
    int resp_err;
    int opcode;
    int txn_id;
    int src_id;
    int tgt_id;
    //int qos;
    logic rsp_type; //response type (1: With Data, 0: Dataless)
    longint addr; // For DEBUG
} rsp_struct;

typedef struct {
    logic valid;
    longint tgt_id;
    //logic trace_tag;
    //logic ret_to_src;
    //logic do_not_go_to_sd;
    //logic non_secure_ext;
    //logic non_secure;
    longint addr;
    int opcode;
    //int fwd_txn_id;
    //int fwd_nid;
    int txn_id;
    int src_id;
    //int qos;
} snp_struct;

typedef struct {
    bit valid;
    longint unsigned data[8];
    longint be;
    //logic cah;
    //logic trace_tag;
    //longint tu;
    //longint tag;
    //int tag_op;
    //int data_id;
    //int cc_id;
    int dbid;
    //int cbusy;
    //int data_source;
    int rsp;
    int rsp_err;
    int opcode;
    //int home_nid;
    int txn_id;
    int src_id;
    int tgt_id;
    //int qos;
    longint addr; // For DEBUG
} dat_struct;

function automatic void req_structtotrans(ref req_struct s, ref req_trans t);
    //t.req_flit.trace_tag       = s.trace_tag;
    //t.req_flit.tag_op          = s.tag_op;
    t.req_flit.exp_comp_ack    = s.exp_comp_ack;
    t.req_flit.excl            = s.excl;
    //t.req_flit.persistence_gid = s.persistence_gid;
    //t.req_flit.snp_attr        = s.snp_attr;
    //t.req_flit.mem_attr        = s.mem_attr;
    //t.req_flit.pcrd_type       = s.pcrd_type;
    //t.req_flit.order           = s.order;
    //t.req_flit.allow_retry     = s.allow_retry;
    //t.req_flit.likely_shared   = s.likely_shared;
    //t.req_flit.non_secure_ext  = s.non_secure_ext;
    //t.req_flit.non_secure      = s.non_secure;
    t.req_flit.addr            = s.addr;
    //t.req_flit.size            = s.size;
    t.req_flit.opcode          = reqval2enum(s.opcode);
    //t.req_flit.return_txn_id   = s.return_txn_id;
    //t.req_flit.stash_nid_valid = s.stash_nid_valid;
    //t.req_flit.return_nid      = s.return_nid;
    t.req_flit.txn_id          = s.txn_id;
    t.req_flit.src_id          = s.src_id;
    t.req_flit.tgt_id          = s.tgt_id;
    //t.req_flit.qos             = s.qos;
    t.req_flit.alloc             = s.alloc;
endfunction : req_structtotrans

function automatic void req_transtostruct(ref req_struct s, ref req_trans t);
    //s.trace_tag       = t.req_flit.trace_tag;
    //s.tag_op          = t.req_flit.tag_op;
    s.exp_comp_ack    = t.req_flit.exp_comp_ack;
    s.excl            = t.req_flit.excl;
    //s.persistence_gid = t.req_flit.persistence_gid;
    //s.snp_attr        = t.req_flit.snp_attr;
    //s.mem_attr        = t.req_flit.mem_attr;
    //s.pcrd_type       = t.req_flit.pcrd_type;
    //s.order           = t.req_flit.order;
    //s.allow_retry     = t.req_flit.allow_retry;
    //s.likely_shared   = t.req_flit.likely_shared;
    //s.non_secure_ext  = t.req_flit.non_secure_ext;
    //s.non_secure      = t.req_flit.non_secure;
    s.addr            = t.req_flit.addr;
    //s.size            = t.req_flit.size;
    s.opcode          = t.req_flit.opcode;
    //s.return_txn_id   = t.req_flit.return_txn_id;
    //s.stash_nid_valid = t.req_flit.stash_nid_valid;
    //s.return_nid      = t.req_flit.return_nid;
    s.txn_id          = t.req_flit.txn_id;
    s.src_id          = t.req_flit.src_id;
    s.tgt_id          = t.req_flit.tgt_id;
    //s.qos             = t.req_flit.qos;
    s.alloc             = t.req_flit.alloc;
endfunction : req_transtostruct

function automatic void rsp_structtotrans(ref rsp_struct s, ref rsp_trans t);
    //t.rsp_flit.trace_tag = s.trace_tag;
    //t.rsp_flit.tag_op    = s.tag_op;
    //t.rsp_flit.pcrd_type = s.pcrd_type;
    t.rsp_flit.dbid      = s.dbid;
    //t.rsp_flit.cbusy     = s.cbusy;
    //t.rsp_flit.fwd_state = s.fwd_state;
    t.rsp_flit.resp      = s.resp;
    t.rsp_flit.resp_err  = s.resp_err;
    t.rsp_flit.opcode    = rspval2enum(s.opcode);
    t.rsp_flit.txn_id    = s.txn_id;
    t.rsp_flit.src_id    = s.src_id;
    t.rsp_flit.tgt_id    = s.tgt_id;
    //t.rsp_flit.qos       = s.qos;
    t.rsp_flit.rsp_type  = s.rsp_type;
    t.rsp_flit.addr       = s.addr;
endfunction : rsp_structtotrans

function automatic void rsp_transtostruct(ref rsp_struct s, ref rsp_trans t);
    //s.trace_tag = t.rsp_flit.trace_tag;
    //s.tag_op    = t.rsp_flit.tag_op;
    //s.pcrd_type = t.rsp_flit.pcrd_type;
    s.dbid      = t.rsp_flit.dbid;
    //s.cbusy     = t.rsp_flit.cbusy;
    //s.fwd_state = t.rsp_flit.fwd_state;
    s.resp      = t.rsp_flit.resp;
    s.resp_err  = t.rsp_flit.resp_err;
    s.opcode    = t.rsp_flit.opcode;
    s.txn_id    = t.rsp_flit.txn_id;
    s.src_id    = t.rsp_flit.src_id;
    s.tgt_id    = t.rsp_flit.tgt_id;
    //s.qos       = t.rsp_flit.qos;
    //s.qos       = t.rsp_flit.qos;
    //s.qos       = t.rsp_flit.qos;
endfunction : rsp_transtostruct

function automatic void snp_structtotrans(ref snp_struct s, ref snp_trans t);
    t.snp_flit.tgt_id        = s.tgt_id;
    //t.snp_flit.trace_tag       = s.trace_tag;
    //t.snp_flit.ret_to_src      = s.ret_to_src;
    //t.snp_flit.do_not_go_to_sd = s.do_not_go_to_sd;
    //t.snp_flit.non_secure_ext  = s.non_secure_ext;
    //t.snp_flit.non_secure      = s.non_secure;
    t.snp_flit.addr            = s.addr;
    t.snp_flit.opcode          = snpval2enum(s.opcode);
    //t.snp_flit.fwd_txn_id      = s.fwd_txn_id;
    //t.snp_flit.fwd_nid         = s.fwd_nid;
    t.snp_flit.txn_id          = s.txn_id;
    t.snp_flit.src_id          = s.src_id;
    //t.snp_flit.qos             = s.qos;
endfunction : snp_structtotrans

function automatic void dat_structtotrans(ref dat_struct s, ref dat_trans t);
    t.dat_flit.be          = s.be;
    //t.dat_flit.cah         = s.cah;
    //t.dat_flit.trace_tag   = s.trace_tag;
    //t.dat_flit.tu          = s.tu;
    //t.dat_flit.tag         = s.tag;
    //t.dat_flit.tag_op      = s.tag_op;
    //t.dat_flit.data_id     = s.data_id;
    //t.dat_flit.cc_id       = s.cc_id;
    t.dat_flit.dbid        = s.dbid;
    //t.dat_flit.cbusy       = s.cbusy;
    //t.dat_flit.data_source = s.data_source;
    t.dat_flit.rsp        = s.rsp;
    t.dat_flit.rsp_err    = s.rsp_err;
    t.dat_flit.opcode      = datval2enum(s.opcode);
    //t.dat_flit.home_nid    = s.home_nid;
    t.dat_flit.txn_id      = s.txn_id;
    t.dat_flit.src_id      = s.src_id;
    t.dat_flit.tgt_id      = s.tgt_id;
    //t.dat_flit.qos         = s.qos;
    t.dat_flit.addr         = s.addr;

    //copy data
    t.dat_flit.data[63:0]    = s.data[0];
    t.dat_flit.data[127:64]  = s.data[1];
    t.dat_flit.data[191:128] = s.data[2];
    t.dat_flit.data[255:192] = s.data[3];
    t.dat_flit.data[319:256] = s.data[4];
    t.dat_flit.data[383:320] = s.data[5];
    t.dat_flit.data[447:384] = s.data[6];
    t.dat_flit.data[511:448] = s.data[7];
endfunction : dat_structtotrans

function automatic void dat_transtostruct(ref dat_struct s, ref dat_trans t);
    s.be          = t.dat_flit.be;
    //s.cah         = t.dat_flit.cah;
    //s.trace_tag   = t.dat_flit.trace_tag;
    //s.tu          = t.dat_flit.tu;
    //s.tag         = t.dat_flit.tag;
    //s.tag_op      = t.dat_flit.tag_op;
    //s.data_id     = t.dat_flit.data_id;
    //s.cc_id       = t.dat_flit.cc_id;
    s.dbid        = t.dat_flit.dbid;
    //s.cbusy       = t.dat_flit.cbusy;
    //s.data_source = t.dat_flit.data_source;
    s.rsp        = t.dat_flit.rsp;
    s.rsp_err    = t.dat_flit.rsp_err;
    s.opcode      = t.dat_flit.opcode;
    //s.home_nid    = t.dat_flit.home_nid;
    s.txn_id      = t.dat_flit.txn_id;
    s.src_id      = t.dat_flit.src_id;
    s.tgt_id      = t.dat_flit.tgt_id;
    //s.qos         = t.dat_flit.qos;
    s.addr         = t.dat_flit.addr;

    //copy data
    s.data[0]  = t.dat_flit.data[63:0];
    s.data[1]  = t.dat_flit.data[127:64];
    s.data[2]  = t.dat_flit.data[191:128];
    s.data[3]  = t.dat_flit.data[255:192];
    s.data[4]  = t.dat_flit.data[319:256];
    s.data[5]  = t.dat_flit.data[383:320];
    s.data[6]  = t.dat_flit.data[447:384];
    s.data[7]  = t.dat_flit.data[511:448];
endfunction : dat_transtostruct

function automatic string convertreqs2string(ref req_struct req_fl);
    return $psprintf("REQSTRUCT valid: %d src id: %d, tgt id: %d, txn id: %d, opcode: %s, addr: %h >> ", req_fl.valid, req_fl.src_id, req_fl.tgt_id, req_fl.txn_id, req_fl.opcode, req_fl.addr);
endfunction : convertreqs2string

function automatic string convertrsps2string(ref rsp_struct rsp_fl);
    return $psprintf("RSPSTRUCT valid: %d src id: %d, tgt id: %d, txn id: %d, rsp_addr: %h, opcode: %s, resp: %h, resp_err: %h dbid: %h >>", rsp_fl.valid, rsp_fl.src_id, rsp_fl.tgt_id, rsp_fl.txn_id, rsp_fl.addr, rsp_fl.opcode, rsp_fl.resp, rsp_fl.resp_err, rsp_fl.dbid);
endfunction : convertrsps2string

function automatic string convertsnps2string(ref snp_struct snp_fl);
    return $psprintf("SNPSTRUCT valid: %d src id: %d, tgt id: %d, txn id: %d, opcode: %s, addr: %h, addr+000: %h>>", snp_fl.valid, snp_fl.src_id, snp_fl.tgt_id, snp_fl.txn_id, snp_fl.opcode, snp_fl.addr, {snp_fl.addr, 3'b000});
endfunction : convertsnps2string

function automatic string convertdats2string(ref dat_struct dat_fl);
        return $psprintf("DATSTRUCT valid: %d src id: %d, tgt id: %d, txn id: %d, opcode: %s, rsp: %h, data: %p >>", dat_fl.valid, dat_fl.src_id, dat_fl.tgt_id, dat_fl.txn_id, dat_fl.opcode, dat_fl.rsp, dat_fl.data);
endfunction : convertdats2string

function request_opcode_e reqval2enum(logic[6:0] op);
    //$display("Converting int: %d", op);
    case(op)
        7'h1 : return READ_SHARED;
        7'h4 : return READ_NO_SNP;
        7'h7 : return READ_UNIQUE;
        7'h1b : return WRITE_BACK_FULL;
        7'h1d : return WRITE_NO_SNP_FULL;
        default : $fatal($sformatf("Illegal REQOPCODE : %7b",op));
    endcase // case (op)
endfunction : reqval2enum

function response_opcode_e rspval2enum(logic[4:0] op);
    //$display("Converting int: %d", op);
    case(op)
        5'h1 : return SNP_RESP;
        5'h2 : return COMP_ACK;
        5'h4 : return COMP;
        5'h5 : return COMP_DBID_RESP;
        default : $fatal($sformatf("Illegal RSPOPCODE : %5b",op));
    endcase // case (op)
endfunction : rspval2enum

function data_opcode_e datval2enum(logic[3:0] op);
    //$display("Converting int: %d", op);
    case(op)
        4'h1 : return SNP_RSP_DATA;
        4'h2 : return COPY_BACK_WR_DATA;
        4'h3 : return NON_COPY_BACK_WR_DATA;
        4'h4 : return COMP_DATA;
        default : $fatal($sformatf("Illegal REQOPCODE : %7b",op));
    endcase // case (op)
endfunction : datval2enum

function snoop_opcode_e snpval2enum(logic[4:0] op);
    //$display("Converting int: %d", op);
    case(op)
        5'h0 : return SNP_LCRD_RETURN;
        5'h1 : return SNP_SHARED;
        5'h3 : return SNP_ONCE;
        5'h7 : return SNP_UNIQUE;
        5'h9 : return SNP_CLEAN_INVALID;
        5'ha : return SNP_MAKE_INVALID;
        default : $fatal($sformatf("Illegal SNPOPCODE : %5b",op));
    endcase // case (op)
endfunction : snpval2enum


import mti_scdpi::*;
import "DPI-SC" context task hnf_request(input req_struct ip, inout req_struct req_op1, inout req_struct req_op2, inout rsp_struct rsp_op, inout snp_struct snp_op, inout dat_struct dat_op);
import "DPI-SC" context task hnf_response(input rsp_struct ip, inout req_struct req_op, inout dat_struct dat_op, inout req_struct req_op1, inout req_struct req_op2, inout rsp_struct rsp_op1, inout snp_struct snp_op1, inout dat_struct dat_op1);
import "DPI-SC" context task hnf_data(input dat_struct ip, inout req_struct req_op, inout dat_struct dat_op);

class predictor extends uvm_agent;

    `uvm_component_utils(predictor)

    uvm_tlm_analysis_fifo #(req_trans) reqin_fifo;
    uvm_tlm_analysis_fifo #(rsp_trans) rspin_fifo;
    uvm_tlm_analysis_fifo #(dat_trans) datin_fifo;

    uvm_analysis_port #(req_trans) reqout_port;
    uvm_analysis_port #(rsp_trans) rspout_port;
    uvm_analysis_port #(dat_trans) datout_port;
    uvm_analysis_port #(snp_trans) snpout_port;

function new (string name,
             uvm_component parent);
    super.new(name,parent);
endfunction: new

virtual        function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    reqin_fifo      = new("reqin_fifo", this);
    rspin_fifo      = new("rspin_fifo", this);
    datin_fifo      = new("datin_fifo", this);

    reqout_port     = new("reqout_port", this);
    rspout_port     = new("rspout_port", this);
    snpout_port     = new("snpout_port", this);
    datout_port     = new("datout_port", this);
endfunction: build_phase

task run_phase(uvm_phase phase);

    req_trans req_in;
    rsp_trans rsp_in;
    dat_trans dat_in;

    req_struct reqi;
    rsp_struct rspi;
    dat_struct dati;

    req_struct req;
    req_struct req1;
    req_struct req2;
    rsp_struct rsp, rsp1;
    snp_struct snp, snp1;
    dat_struct dat, dat1;

    req_trans reqt = new(), c_reqt;
    rsp_trans rspt = new(), c_rspt;
    snp_trans snpt = new(), c_snpt;
    dat_trans datt = new(), c_datt;

    `uvm_info (get_type_name(),{"run_phase predictor"},400);
    forever begin : run_loop
        if(reqin_fifo.try_get(req_in)) begin

            req1.valid = 0;
            req2.valid = 0;
            rsp.valid = 0;
            snp.valid = 0;
            dat.valid = 0;

            `uvm_info (get_type_name(),{"got req ", req_in.convert2string()},400);
            //convert ip trans to struct
            req_transtostruct(reqi, req_in);
            `uvm_info (get_type_name(),{"STRUCT ", convertreqs2string(reqi)},400);
            //convertreqs2string(reqi);
            req_structtotrans(reqi, reqt);
            `uvm_info (get_type_name(),{"POST CONVERSION ", reqt.convert2string()},400);

            //call dpi function
			reqi.valid = 1;
            hnf_request(reqi, req1, req2, rsp, snp, dat);

            if(req1.valid) begin
                //convert op struct to trans
                //send op trans to comparator
                req_structtotrans(req1, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(req2.valid) begin
                req_structtotrans(req2, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(rsp.valid) begin
                rsp_structtotrans(rsp, rspt);
                $cast(c_rspt, rspt.clone());
                rspout_port.write(c_rspt);
            end

            `uvm_info (get_type_name(),$psprintf("SNPOUT: %d ", snp.valid),400);
            if(snp.valid) begin
                snp_structtotrans(snp, snpt);
                $cast(c_snpt, snpt.clone());
                `uvm_info (get_type_name(),{"SNPOUT ", c_snpt.convert2string()},400);
                snpout_port.write(c_snpt);
            end

            if(dat.valid) begin
                dat_structtotrans(dat, datt);
                $cast(c_datt, datt.clone());
                datout_port.write(c_datt);
            end
        end

        if(rspin_fifo.try_get(rsp_in)) begin

            req.valid = 0;
            dat.valid = 0;

            req1.valid = 0;
            req2.valid = 0;
            rsp1.valid = 0;
            snp1.valid = 0;
            dat1.valid = 0;

            `uvm_info (get_type_name(),{"got rsp", rsp_in.convert2string()},400);
            //convert ip trans to struct
            rsp_transtostruct(rspi, rsp_in);
            //convert ip trans to struct
            `uvm_info (get_type_name(),{"STRUCT ", convertrsps2string(rspi)},400);
            rsp_structtotrans(rspi, rspt);
            `uvm_info (get_type_name(),{"POST CONVERSION ", rspt.convert2string()},400);

            //call dpi function
			rspi.valid = 1;
            hnf_response(rspi, req, dat, req1, req2, rsp1, snp1, dat1);

            if(req.valid) begin
                //convert op struct to trans
                //send op trans to comparator
                req_structtotrans(req, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(dat.valid) begin
                dat_structtotrans(dat, datt);
                $cast(c_datt, datt.clone());
                datout_port.write(c_datt);
            end

            if(req1.valid) begin
                //convert op struct to trans
                //send op trans to comparator
                req_structtotrans(req1, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(req2.valid) begin
                req_structtotrans(req2, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(rsp1.valid) begin
                rsp_structtotrans(rsp1, rspt);
                $cast(c_rspt, rspt.clone());
                rspout_port.write(c_rspt);
            end

            if(snp1.valid) begin
                snp_structtotrans(snp1, snpt);
                $cast(c_snpt, snpt.clone());
                snpout_port.write(c_snpt);
            end

            if(dat1.valid) begin
                dat_structtotrans(dat1, datt);
                $cast(c_datt, datt.clone());
                datout_port.write(c_datt);
            end
        end

        if(datin_fifo.try_get(dat_in)) begin

            req.valid = 0;
            dat.valid = 0;

            `uvm_info (get_type_name(),{"got dat", dat_in.convert2string()},400);
            //convert ip trans to struct
            dat_transtostruct(dati, dat_in);
            //convert ip trans to struct
            `uvm_info (get_type_name(),{"STRUCT ", convertdats2string(dati)},400);
            dat_structtotrans(dati, datt);
            `uvm_info (get_type_name(),{"POST CONVERSION ", datt.convert2string()},400);

            //call dpi function
			dati.valid = 1;
            hnf_data(dati, req, dat);

            if(req.valid) begin
                //convert op struct to trans
                //send op trans to comparator
                req_structtotrans(req, reqt);
                $cast(c_reqt, reqt.clone());
                reqout_port.write(c_reqt);
            end

            if(dat.valid) begin
                dat_structtotrans(dat, datt);
                $cast(c_datt, datt.clone());
                datout_port.write(c_datt);
            end
        end

        #1;
    end : run_loop;

endtask: run_phase

endclass: predictor
