#include "../../sc_dpiheader.h"
#include "hnf_refmodel.hpp"

#include <string>
#include <iostream>
#include "systemc.h"
#ifdef DEBUGMSG_REF_MODEL
#define DEBUG 1
#else
#define DEBUG 0
#endif

using std::cout;
using std::hex;
using std::endl;

void printReqStruct(const req_struct* req) {
    cout << hex <<  "REFMODEL REQ SrcId: " << req->src_id << " TgtId: " << req->tgt_id << " TxnId: " << req->txn_id <<" Addr: " << req->addr << " Opcode: "<< req->opcode << "Excl: " << req->excl << " Valid: " << static_cast <bool> (req->valid) << endl;
}

void printRspStruct(const rsp_struct* rsp) {
    cout << hex <<  "REFMODEL RSP SrcId: " << rsp->src_id << " TgtId: " << rsp->tgt_id << " TxnId: " << rsp->txn_id <<" Addr: " << rsp->addr << " Opcode: "<< rsp->opcode << " Resp: " << rsp->resp << " RespErr: " << rsp->resp_err << " DBID: " << rsp->dbid << " Valid: " << static_cast <bool> (rsp->valid) << endl;
}

void printSnpStruct(const snp_struct* snp) {
    cout << hex <<  "REFMODEL SNP SrcId: " << snp->src_id << " TgtId: " << snp->tgt_id << " TxnId: " << snp->txn_id <<" Addr: " << snp->addr << " Opcode: "<< snp->opcode << " Valid: " << static_cast <bool> (snp->valid) << endl;
}

void printDatStruct(const dat_struct* dat) {
    cout << hex <<  "REFMODEL DAT SrcId: " << dat->src_id << " TgtId: " << dat->tgt_id << " TxnId: " << dat->txn_id << " Opcode: "<< dat->opcode << " Resp: " << dat->rsp << " RespErr: " << dat->rsp_err << " DBID: " << dat->dbid << " BE: " << dat->be << " DATA7: " << dat->data[7] << " DATA6: " << dat->data[6] << " DATA5: " << dat->data[5] << " DATA4: " << dat->data[4] << " DATA3: " << dat->data[3] << " DATA2: " << dat->data[2] << " DATA1: " << dat->data[1] << " DATA0: " << dat->data[0] << " Valid: " << static_cast <bool> (dat->valid) << endl;
}

void printReq(const reqs* req) {
    cout << hex <<  "REFMODEL REQS SrcId: " << req->src_id << " TgtId: " << req->tgt_id << " TxnId: " << req->txn_id <<" Addr: " << req->addr << " Opcode: "<< req->opcode << "Excl: " << req->excl << " Valid: " << req->valid << endl;
}

void printRsp(const rsps* rsp) {
    cout << hex <<  "REFMODEL RSPS SrcId: " << rsp->src_id << " TgtId: " << rsp->tgt_id << " TxnId: " << rsp->txn_id <<" Addr: " << rsp->addr << " Opcode: "<< rsp->opcode << " Resp: " << rsp->resp << " RespErr: " << rsp->resp_err << " DBID: " << rsp->dbid << " Valid: " << rsp->valid << endl;
}

void printSnp(const snps* snp) {
    cout << hex <<  "REFMODEL SNPS SrcId: " << snp->src_id << " TgtId: " << snp->tgt_id << " TxnId: " << snp->txn_id <<" Addr: " << snp->addr << " Opcode: "<< snp->opcode << " Valid: " <<  snp->valid << endl;
}

void printDat(const dats* dat) {
    cout << hex <<  "REFMODEL DATS SrcId: " << dat->src_id << " TgtId: " << dat->tgt_id << " TxnId: " << dat->txn_id << " Opcode: "<< dat->opcode << " Resp: " << dat->rsp << " RespErr: " << dat->rsp_err << " DBID: " << dat->dbid << " BE: " << dat->be << " DATA7: " << dat->data[7] << " DATA6: " << dat->data[6] << " DATA5: " << dat->data[5] << " DATA4: " << dat->data[4] << " DATA3: " << dat->data[3] << " DATA2: " << dat->data[2] << " DATA1: " << dat->data[1] << " DATA0: " << dat->data[0] << " Valid: " << dat->valid << endl;
}

void copytoreqs(reqs *r, const req_struct* s) {
    r->valid        = static_cast<bool> (s->valid);
    r->exp_comp_ack = static_cast<bool> (s->exp_comp_ack);
    r->excl         = static_cast<bool> (s->excl);
    r->addr         = s->addr;
    r->opcode       = static_cast<req_opcode> (s->opcode);
    r->txn_id       = s->txn_id;
    r->src_id       = s->src_id;
    r->tgt_id       = s->tgt_id;
    r->alloc        = static_cast<bool> (s->alloc);
}

void copyfromreqs(reqs *r, req_struct* s) {
    s->valid        = static_cast<svLogic> (r->valid);
    s->exp_comp_ack = static_cast<svLogic> (r->exp_comp_ack);
    s->excl         = static_cast<svLogic> (r->excl);
    s->addr         = r->addr;
    s->opcode       = static_cast<int> (r->opcode);
    s->txn_id       = r->txn_id;
    s->src_id       = r->src_id;
    s->tgt_id       = r->tgt_id;
    s->alloc        = static_cast<svLogic> (r->alloc);
}

void copytorsps(rsps *r, const rsp_struct* s) {
    r->valid        = static_cast<bool> (s->valid);
    r->dbid         = s->dbid;
    r->resp         = static_cast<l1_c_state> (s->resp);
    r->resp_err     = static_cast<l2_resp> (s->resp_err);
    r->opcode       = static_cast<rsp_opcode> (s->opcode);
    r->txn_id       = s->txn_id;
    r->src_id       = s->src_id;
    r->tgt_id       = s->tgt_id;
    r->rsp_type     = static_cast<bool> (s->rsp_type);
    r->addr         = s->addr;
}

void copyfromrsps(rsps *r, rsp_struct* s) {
    s->valid        = static_cast<svLogic> (r->valid);
    s->dbid         = r->dbid;
    s->resp         = static_cast<int> (r->resp);
    s->resp_err     = static_cast<int> (r->resp_err);
    s->opcode       = static_cast<int> (r->opcode);
    s->txn_id       = r->txn_id;
    s->src_id       = r->src_id;
    s->tgt_id       = r->tgt_id;
    s->rsp_type     = static_cast<svLogic> (r->rsp_type);
    s->addr         = r->addr;
}

void copyfromsnps(snps *r, snp_struct* s) {
    s->valid        = static_cast<svLogic> (r->valid);
    s->tgt_id       = r->tgt_id;
    s->addr         = r->addr;
    s->opcode       = static_cast<int> (r->opcode);
    s->txn_id       = r->txn_id;
    s->src_id       = r->src_id;
}

void copytodats(dats *r, const dat_struct* s) {
    r->valid        = static_cast<bool> (s->valid);
    r->data[0]      = s->data[0];
    r->data[1]      = s->data[1];
    r->data[2]      = s->data[2];
    r->data[3]      = s->data[3];
    r->data[4]      = s->data[4];
    r->data[5]      = s->data[5];
    r->data[6]      = s->data[6];
    r->data[7]      = s->data[7];
    r->be           = s->be;
    r->dbid         = s->dbid;
    r->rsp          = static_cast<l1_c_state> (s->rsp);
    r->rsp_err      = static_cast<l2_resp> (s->rsp_err);
    r->opcode       = static_cast<dat_opcode> (s->opcode);
    r->txn_id       = s->txn_id;
    r->src_id       = s->src_id;
    r->tgt_id       = s->tgt_id;
    r->addr         = s->addr;
}

void copyfromdats(dats *r, dat_struct* s) {
    s->valid        = static_cast<svLogic> (r->valid);
    s->data[0]      = r->data[0];
    s->data[1]      = r->data[1];
    s->data[2]      = r->data[2];
    s->data[3]      = r->data[3];
    s->data[4]      = r->data[4];
    s->data[5]      = r->data[5];
    s->data[6]      = r->data[6];
    s->data[7]      = r->data[7];
    s->be           = r->be;
    s->dbid         = r->dbid;
    s->rsp          = static_cast<int> (r->rsp);
    s->rsp_err      = static_cast<int> (r->rsp_err);
    s->opcode       = static_cast<int> (r->opcode);
    s->txn_id       = r->txn_id;
    s->src_id       = r->src_id;
    s->tgt_id       = r->tgt_id;
    s->addr         = r->addr;
}

SC_MODULE(refmodel_sc)
{
    int hnf_request(const req_struct* reqi, req_struct* req1, req_struct* req2, rsp_struct* rsp, snp_struct* snp, dat_struct* dat);
    int hnf_response(const rsp_struct* rspi, req_struct* req, dat_struct* dat, req_struct* req1, req_struct* req2, rsp_struct* rsp1, snp_struct* snp1, dat_struct* dat1);
    int hnf_data(const dat_struct* rspi, req_struct* req, dat_struct* dat);

    //constructor
    SC_CTOR(refmodel_sc)
    {
        SC_DPI_REGISTER_CPP_MEMBER_FUNCTION("hnf_request", &refmodel_sc::hnf_request);
        SC_DPI_REGISTER_CPP_MEMBER_FUNCTION("hnf_response", &refmodel_sc::hnf_response);
        SC_DPI_REGISTER_CPP_MEMBER_FUNCTION("hnf_data", &refmodel_sc::hnf_data);
    }

    ~refmodel_sc() {};
};

int refmodel_sc::hnf_request(const req_struct* ri, req_struct* r1, req_struct* r2, rsp_struct* r, snp_struct* s, dat_struct* d)
{
    reqs reqi, req1, req2, req3;
    rsps rsp;
    snps snp;
    dats dat;

    copytoreqs(&reqi, ri);

    #if DEBUG
    printReqStruct(ri);
    printReq(&reqi);
    #endif

    HNFModel &hnf = HNFModel::getInstance();
    hnf.processRequest(reqi, req1, req2, rsp, snp, dat);

    if(req1.valid) {
        #if DEBUG
        printReq(&req1);
        #endif
        copyfromreqs(&req1, r1);
    }

    if(req2.valid) {
        #if DEBUG
        printReq(&req2);
        #endif
        copyfromreqs(&req2, r2);
    }

    if(rsp.valid) {
        #if DEBUG
        printRsp(&rsp);
        #endif
        copyfromrsps(&rsp, r);
    }

    if(snp.valid) {
        #if DEBUG
        printSnp(&snp);
        #endif
        copyfromsnps(&snp, s);
    }

    if(dat.valid) {
        #if DEBUG
        printDat(&dat);
        #endif
        copyfromdats(&dat, d);
    }
}

int refmodel_sc::hnf_response(const rsp_struct* ri, req_struct* r, dat_struct* d, req_struct* r1, req_struct* r2, rsp_struct* rs1, snp_struct* s1, dat_struct* d1)
{
    rsps rspi, rsp1;
    reqs req, req1, req2;
    dats dat, dat1;
    snps snp1;

    copytorsps(&rspi, ri);

    #if DEBUG
    printRspStruct(ri);
    printRsp(&rspi);
    #endif

    HNFModel &hnf = HNFModel::getInstance();
    hnf.processResponse(rspi, req, dat, req1, req2, rsp1, snp1, dat1);

    if(req.valid) {
        #if DEBUG
        printReq(&req);
        #endif
        copyfromreqs(&req, r);
    }

    if(dat.valid) {
        #if DEBUG
        printDat(&dat);
        #endif
        copyfromdats(&dat, d);
    }

    if(req1.valid) {
        #if DEBUG
        printReq(&req1);
        #endif
        copyfromreqs(&req1, r1);
    }

    if(req2.valid) {
        #if DEBUG
        printReq(&req2);
        #endif
        copyfromreqs(&req2, r2);
    }

    if(rsp1.valid) {
        #if DEBUG
        printRsp(&rsp1);
        #endif
        copyfromrsps(&rsp1, rs1);
    }

    if(snp1.valid) {
        #if DEBUG
        printSnp(&snp1);
        #endif
        copyfromsnps(&snp1, s1);
    }

    if(dat1.valid) {
        #if DEBUG
        printDat(&dat1);
        #endif
        copyfromdats(&dat1, d1);
    }
}

int refmodel_sc::hnf_data(const dat_struct* di, req_struct* r, dat_struct* d)
{
    dats dati;
    reqs req;
    dats dat;

    copytodats(&dati, di);

    #if DEBUG
    printDatStruct(di);
    printDat(&dati);
    #endif

    HNFModel &hnf = HNFModel::getInstance();
    hnf.processData(dati, req, dat);

    if(req.valid) {
        #if DEBUG
        printReq(&req);
        #endif
        copyfromreqs(&req, r);
    }

    if(dat.valid) {
        #if DEBUG
        printDat(&dat);
        #endif
        copyfromdats(&dat, d);
    }
}

SC_MODULE_EXPORT(refmodel_sc);
