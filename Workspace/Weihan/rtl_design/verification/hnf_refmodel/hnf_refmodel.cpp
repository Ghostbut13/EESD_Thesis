#include "hnf_refmodel.hpp"

/* generic functions for printing state*/
string printCState(l2_c_state c_state) {
    string s = "NA";
    if(c_state == M)
        s = "M";
    else if(c_state == MT)
        s = "MT";
    else if(c_state == S)
        s = "S";
    else if(c_state == NP)
        s = "NP";
    return s;
}

string printTState(l2_t_state t_state) {
    string s = "NA";
    if(t_state == MT_S)
        s = "MT_S";
    else if(t_state == MT_MT)
        s = "MT_MT";
    else if(t_state == S_MT)
        s = "S_MT";
    else if(t_state == MT_MI)
        s = "MT_MI";
    else if(t_state == S_M)
        s = "S_M";
    else if(t_state == CI)
        s = "CI";
    else if(t_state == CS)
        s = "CS";
    else if(t_state == A_M)
        s = "A_M";
    else if(t_state == S_CU)
        s = "S_CU";
    else if(t_state == MT_M)
        s = "MT_M";
    else if(t_state == MT_I)
        s = "MT_I";
    else if(t_state == S_I)
        s = "S_I";
    else if(t_state == NA)
        s = "NA";
    return s;
}

/*misc function*/
void copyData(unsigned long *dst, unsigned long *src) {
    dst[0] = src[0];
    dst[1] = src[1];
    dst[2] = src[2];
    dst[3] = src[3];
    dst[4] = src[4];
    dst[5] = src[5];
    dst[6] = src[6];
    dst[7] = src[7];
}

bool genValidReq(req_opcode req) {
    if(req == WRITE_BACK_FULL) return false;
    else return true;
}

bool genValidRsp(req_opcode req) {
    if(req == WRITE_BACK_FULL) return true;
    else return false;
}

bool genValidData(req_opcode req) {
    if(req == WRITE_BACK_FULL) return false;
    else return true;
}

long computeSetIndex(long tag) {
    return tag & (NUM_SETS - 1);
}

long computeTag(long addr) {
    return addr >> BLOCK_OFFSET;
}

int getSharerId(bitset<NUM_CORES> bm) {
    return (((int) bm.to_ulong() ) -1 ); // Here we need to convert tgt_mask 0001 to tgt_id 0
}

/*functions related to req,rsp,snp and dat structs*/

void reqs::reset() {
    valid = false;
    exp_comp_ack = false;
    excl = false;
    addr = 0;
    opcode = REQ_LCRD_RETURN;
    txn_id = 0;
    src_id = 0;
    tgt_id = 0;
    alloc = false;
}

void rsps::reset() {
    valid = false;
    dbid = 0;
    resp = I;
    resp_err = OK;
    opcode = RESP_LCRD_RETURN;
    txn_id = 0;
    src_id = 0;
    tgt_id = 0;
    rsp_type = false;
    addr = 0;
}

void snps::reset() {
    valid = false;
    tgt_id = 0;
    addr = 0;
    opcode = SNP_LCRD_RETURN;
    txn_id = 0;
    src_id = 0;
}

void dats::reset() {
    valid = false;
    be = 0;
    dbid = 0;
    rsp = I;
    rsp_err = OK;
    opcode = DATA_LCRD_RETURN;
    txn_id = 0;
    src_id = 0;
    tgt_id = 0;
    addr = 0;
    for(int i = 0; i < 8; i++)
        data[i] = 0;

}


/*functions related to CacheEntry*/
CacheEntry::CacheEntry() {
    resetEntry();
}

void CacheEntry::resetEntry() {
    iv_state = INVALID;
    cd_state = CLEAN;
    c_state = NP;
    p_bits.reset();
    tag = -1;
    for(int i = 0; i < 8; i++)
        data[i] = 0;
}

void CacheEntry::printEntry() {
    cout << "VALID: " << iv_state << " DIRTY: " << cd_state << " C_STATE: " << printCState(c_state) << " PBITS: " << p_bits << " TAG: " << tag << " DATA: " << data[7] << data[6] << data[5] << data[4] << data[3] << data[2] << data[1] << data[0] << endl;
}

long CacheEntry::getTag() {
    return tag;
}

unsigned long* CacheEntry::getDataPtr() {
    return data;
}

bool CacheEntry::isValid() {
    return iv_state == VALID;
}

bool CacheEntry::isDirty() {
    return cd_state == DIRTY;
}

void CacheEntry::setDirty() {
    cd_state = DIRTY;
}

l2_c_state CacheEntry::getCState() {
    return c_state;
}


void CacheEntry::setCState(l2_c_state state) {
    c_state = state;
}

void CacheEntry::setOwner(int id) {
    p_bits.reset();
    p_bits.set(id);
}

void CacheEntry::addSharer(int id) {
    p_bits.set(id);
}

bool CacheEntry::isSharer(int id) {
    return p_bits.test(id);
}

int CacheEntry::numSharers() {
    return p_bits.count();
}

void CacheEntry::resetSharers() {
    p_bits.reset();
}

bitset<NUM_CORES> CacheEntry::getSharers() {
    return p_bits;
}

void CacheEntry::updateEntry(l2_iv_state iv, l2_cd_state cd, l2_c_state cs, int core_id, long addr) {
    iv_state = iv;
    cd_state = cd;
    c_state = cs;
    p_bits.reset();
    p_bits.set(core_id);
    tag = addr;
}

/*functions related to ReplacementPolicy*/
ReplacementPolicy::ReplacementPolicy() {
    lru_state.resize(NUM_WAYS);
    for(int i = 0; i < NUM_WAYS; i++)
        lru_state[i] = -1;
    access_count = 0;
}

void ReplacementPolicy::print(int way) {
    cout << "Replacment Age: " << lru_state[way] << endl;
}

void ReplacementPolicy::updateAccessCount() {
    access_count++;
}

int ReplacementPolicy::getAccessCount() {
    return access_count;
}

void ReplacementPolicy::updateReplacementState(int way) {
    assert(way >=0 && way < NUM_WAYS);

    lru_state[way] = access_count;
}

int ReplacementPolicy::getReplacementCandidate() {
    //get the first invalid way
    for(int i = 0; i < NUM_WAYS; i++)
        if(lru_state[i] == -1)
            return i;

    int lru_index = 0;
    //pick the earliest accessed line
    for(int i = 0; i < NUM_WAYS; i++)
        if(lru_state[i] < lru_state[lru_index])
            lru_index = i;

    return lru_index;
}

/*functions related to CacheSet*/
CacheSet::CacheSet() {
    data_arr.resize(NUM_WAYS);
}

CacheEntry& CacheSet::getCacheEntry(int way) {
    assert(way >= 0 && way < NUM_WAYS);
    return data_arr[way];
}

int CacheSet::accessTag(long tag) {
    assert(tags.size() <= NUM_WAYS);

    if(tags.find(tag) == tags.end())
        return -1;

    return tags[tag];
}

void CacheSet::replaceTag(long repl_addr, long addr, int way) {
    tags[addr] = way;
    if(repl_addr >= 0)
        tags.erase(repl_addr);
}

l2_hm_state CacheSet::accessHitMiss(long tag) {

    int way = accessTag(tag);
    if(way >= 0) {
        CacheEntry &e = getCacheEntry(way);
        if(e.isValid())
            return HIT;
    }
    return MISS;
}

int CacheSet::selectReplacementWay() {
    return repl.getReplacementCandidate();
}

void CacheSet::printSet() {
    for(int i = 0; i < NUM_WAYS; i++) {
        cout << "ADDR: " << data_arr[i].getTag() << " VALID: " << data_arr[i].isValid() << " DIRTY: " << data_arr[i].isDirty() << " PBITS: " << data_arr[i].getSharers() << endl;
        data_arr[i].printEntry();
        //repl.print(i);
    }

    cout << "TAG ARRAY CONTENTS: " << endl;
    for(auto i: tags)
        cout << "TAG: " << i.first << " WAY: " << i.second << endl;

}

/*functions that handle PendingBuffer management*/
PendingBuffer::PendingBuffer() {
    //initialize free list with all the entries
    for(int i = 0; i < NUM_PENDING; i++)
        free_list.push(i);

    //initialize the buffer size to the number of entries
    buffer.resize(NUM_PENDING);
}

PendingBuffer::PendingBufferEntry::PendingBufferEntry() {
    resetPBEntry();
}

void PendingBuffer::PendingBufferEntry::setValid() {
    valid = true;
}

void PendingBuffer::PendingBufferEntry::resetValid() {
    valid = false;
}

void PendingBuffer::PendingBufferEntry::resetPBEntry() {
    hm_state = MISS;
    addr = -1;
    t_state = NA;
    index = -1;
    way = -1;
    ack_count = -1;
    id = -1;
    vict_id = -1;

    wb_hazard = false;
    genSnoop = false;
    genVictim = false;
    expCompAck = false;

    curr_entry.resetEntry();
    new_entry.resetEntry();
    rq.reset();
    resetValid();

}

void PendingBuffer::PendingBufferEntry::initializeBuffer(long tag, CacheEntry& cache_entry, reqs& req, l2_hm_state hm, int way_id, int buff_id) {

    curr_entry = cache_entry;
    new_entry = cache_entry;
    rq = req;

    hm_state = hm;
    addr = tag;
    index = computeSetIndex(tag);
    way = way_id;
    ack_count = 0;
    id = buff_id;

    setValid();
}

void PendingBuffer::PendingBufferEntry::printEntry() {
    cout << "CURR_ENTRY: " << endl;
    curr_entry.printEntry();
    cout << "NEW_ENTRY: " << endl;
    new_entry.printEntry();

    cout << "HM: " << hm_state << " Addr: "  << addr << " TSTATE: " << printTState(t_state) << " WBH: " << wb_hazard << " WAY: " << way << " INDEX: " << index << " ACKC: " << ack_count << " ID: " << id << " VICT_ID: " << vict_id << " VALID: " << valid << " GENSNOOP: " << genSnoop << " GenVictim: " << genVictim << "expxCompAck: " << expCompAck << endl;
}

PendingBuffer::PendingBufferEntry& PendingBuffer::getEntry(int id) {
    assert(id < NUM_PENDING);
    return buffer[id];
}

int PendingBuffer::addtoBuffer(long addr, CacheEntry& cache_entry, reqs& req, l2_hm_state hm_state, int way, int id) {

    if(id < 0) {
        id = free_list.front();
        free_list.pop();
    }

    //check to ensure bufid is valid and is not being used
    assert(id < NUM_PENDING);
    assert(used_list.find(id) == used_list.end());

    buffer[id].initializeBuffer(addr, cache_entry, req, hm_state, way, id);
    used_list.insert(id);
    return id;
}

long PendingBuffer::removefromBuffer(int buff_id) {
    //cout << "removefromBuffer Id: " << buff_id << " TOT_NUM_PENDING: " << NUM_PENDING << endl;

    //cout << "Usedlist contains Ids: " << endl;
    //for(auto i: used_list)
    //    cout << i << " ";
    //cout << endl;

    //check if bufid is valid and is not being used
    assert(buff_id < NUM_PENDING);
    assert(used_list.find(buff_id) != used_list.end());

    PendingBuffer::PendingBufferEntry &entry = buffer[buff_id];
    long addr = entry.addr;

    //reset the PBEntry, remove from used list and add to free list
    entry.resetPBEntry();
    used_list.erase(buff_id);
    //free_list.push(buff_id);

    return addr;
}

void PendingBuffer::printStatus() {
    cout << "Free list size: " << free_list.size() << endl;
    cout << "Occupied entries are: " << endl;
    for(auto i: used_list)
        cout << i << " ";
    cout << endl;

    if(used_list.size()) {
        for(auto i: used_list) {
            cout << "Entry: " << i << endl;
            buffer[i].printEntry();
        }
    }
}

/*functions that manage HN operation*/
CoherenceController::CoherenceController() {

}

CoherenceController& CoherenceController::getInstance() {
    static CoherenceController* cc_cntlr = nullptr;
    if(!cc_cntlr)
        cc_cntlr = new CoherenceController();
    return *cc_cntlr;
}

//function emulating protocol FSM
void CoherenceController::sendSnoop(int itb_id, int vtb_id, snps& snp) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(itb_id);
    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(vtb_id);

    itbe.vict_id = vtbe.id;


    #if DEBUG
    cout << "sendSnoop" << endl;
    itbe.printEntry();
    vtbe.printEntry();
    #endif

    snp.reset();

    l2_hm_state hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;
    req_opcode req = itbe.rq.opcode;
    long addr = itbe.rq.addr;

    int core_id = itbe.rq.src_id;
    bool req_is_sharer = entry.isSharer(core_id);

    //cout << "COREID: " << core_id << endl;

    #if DEBUG
    entry.printEntry();
    #endif

    //cout << "REQ_IS_SHARER: " << req_is_sharer << endl;

    //Common field for snoop
    snp.src_id = HNF_ID;

    if(hm == HIT) {

        snp.addr = addr >> SNP_OFFSET; //45 bit snp addr field
        snp.txn_id = itbe.id;

        if(state == MT) {
            assert(entry.numSharers() == 1);
            if(req == READ_SHARED) {
                //read a copy
                if(!req_is_sharer) {
                    //set snp attributes
                    snp.valid = true;
                    snp.tgt_id = getSharerId(entry.getSharers());
                    snp.opcode = SNP_SHARED;

                    itbe.ack_count = 1;
                    itbe.t_state = MT_S;

                    new_entry.setCState(S);
                }
                new_entry.addSharer(core_id);

            } else if(req == READ_UNIQUE) {
                //read a copy with ownership
                if(!req_is_sharer) {
                    //set snp attributes
                    snp.valid = true;
                    snp.tgt_id = getSharerId(entry.getSharers());
                    snp.opcode = SNP_UNIQUE;

                    itbe.ack_count = 1;
                    itbe.t_state = MT_MT;

                }
                new_entry.setOwner(core_id);

            } else if(req == WRITE_BACK_FULL) {
                //writeback and relinquish ownership
                if(req_is_sharer) {
                    new_entry.setDirty();
                    //new_entry.resetSharers();
                    //new_entry.setCState(M);
                } else {
                    itbe.wb_hazard = true;
                }

            } else {
                //cout << "Unsupported Request/State" << endl;
                assert(false);
            }

        } else if (state == S) {

            if(req == READ_SHARED) {
                //read a copy
                new_entry.addSharer(core_id);

            } else if(req == READ_UNIQUE) {
                //read a copy with ownership
                if(!req_is_sharer) {
                    //set snp attributes
                    snp.valid = true;
                    snp.tgt_id = getSharerId(entry.getSharers());
                    snp.opcode = SNP_UNIQUE;

                    itbe.ack_count = entry.numSharers()-1;
                    itbe.t_state = S_MT;
                }
                new_entry.setOwner(core_id);
                new_entry.setCState(MT);

            } else if(req == WRITE_BACK_FULL) {
                itbe.wb_hazard = true;

            } else {
                assert(false);
            }

        } else if (state == M) {

            if(req == READ_SHARED) {
                new_entry.setOwner(core_id);
                new_entry.setCState(MT);
            } else if(req == READ_UNIQUE) {
                //read a copy with ownership
                new_entry.setOwner(core_id);
                new_entry.setCState(MT);
            } else if(req == WRITE_BACK_FULL) {
                itbe.wb_hazard = true;
            } else {
                assert(false);
            }

        } else {
            //cout << "Unsupported Request/State" << endl;
            assert(false);
        }

    } else {

        addr = entry.getTag() << SNP_OFFSET; //shift to get 45-bit addr

        snp.addr = addr;
        snp.txn_id = vtbe.id;

        if(req == WRITE_BACK_FULL) {
            //writebacks should always be in the tag hit case. Else hazard!
            itbe.wb_hazard = true;
        } else if(state == MT) {
            //set snp attributes
            snp.valid = true;
            snp.tgt_id = getSharerId(entry.getSharers());
            snp.opcode = SNP_CLEAN_INVALID;

            assert(entry.numSharers() == 1);
            vtbe.ack_count = entry.numSharers();
            vtbe.t_state = MT_I;
        } else if(state == S) {
            //set snp attributes
            snp.valid = true;
            snp.tgt_id = getSharerId(entry.getSharers());
            snp.opcode = SNP_CLEAN_INVALID;

            vtbe.ack_count = entry.numSharers();
            vtbe.t_state = S_I;
        } else if (state == M) {
            assert(entry.numSharers() == 0);
        } else if (state == NP){
            //cout << "Evicting NP line" << endl;
            //cout << "Evicting invalid data? Should not reach here" << endl;
            //assert(false);
        }
    }

    //set the generate snoop field in bufferentry
    if(snp.valid) {
        //cout << "VALID GENSNOOP!" << endl;
        if(hm == HIT) itbe.genSnoop = true;
        if(hm == MISS) vtbe.genSnoop = true;
    }

    //Fill line in cache in case of a miss
    if(genValidReq(req)) {
        //Update state for the block that is to be installed
        if(hm == MISS) new_entry.updateEntry(VALID, CLEAN, MT, core_id, itbe.addr);
        itbe.expCompAck = true;
    }


}

CacheController::CacheController() {

}

CacheController& CacheController::getInstance() {
    static CacheController* cac_cntlr = nullptr;
    if(!cac_cntlr)
        cac_cntlr = new CacheController();
    return *cac_cntlr;
}

void CacheController::sendRequest(int itb_id, reqs& req) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(itb_id);

    #if DEBUG
    cout << "sendRquest" << endl;
    itbe.printEntry();
    #endif

    l2_hm_state hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;
    long addr = computeTag(itbe.rq.addr) << BLOCK_OFFSET;

    int core_id = itbe.rq.src_id;
    bool req_is_sharer = entry.isSharer(core_id);

    if(hm == MISS && genValidReq(itbe.rq.opcode)) {
        req.valid  = true;
        req.addr   = addr;
        req.opcode = READ_NO_SNP;
        req.txn_id = itb_id;
        req.src_id = HNF_ID;
        req.tgt_id = SNF_ID;
    }
}

void CacheController::sendVictimRequest(int vtb_id, reqs& req) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(vtb_id);

    #if DEBUG
    cout << "sendVictimRequest" << endl;
    vtbe.printEntry();
    #endif

    l2_hm_state hm = vtbe.hm_state;
    CacheEntry& new_entry = vtbe.new_entry;
    req_opcode reqop = vtbe.rq.opcode;
    long addr = new_entry.getTag() << BLOCK_OFFSET;

    if(hm == MISS && genValidReq(reqop))
        //For cases that miss check for valid dirty victim
        if(new_entry.isValid() && new_entry.isDirty()) vtbe.genVictim = true;

    if(vtbe.genVictim && !vtbe.genSnoop) {
        //generate victim writeback request for valid victims that dont req snoop
        req.valid = true;
        req.addr = addr;
        req.opcode = WRITE_NO_SNP_FULL;
        req.txn_id = vtb_id;
        req.src_id = HNF_ID;
        req.tgt_id = SNF_ID;
    }
}

void CacheController::sendReqResponse(int itb_id, rsps& rsp) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(itb_id);

    #if DEBUG
    cout << "sendReqResponse" << endl;
    itbe.printEntry();
    #endif

    l2_hm_state hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;
    req_opcode req = itbe.rq.opcode;
    long addr = itbe.rq.addr;

    int core_id = itbe.rq.src_id;
    bool req_is_sharer = entry.isSharer(core_id);

    //Response id generated only in case for WB req
    if(genValidRsp(req)) {
        //cout << "Sending COMP_DBID_RESP" << endl;
        rsp.valid = true;
        rsp.dbid = itb_id;
        rsp.resp = I;
        rsp.resp_err = OK;

        rsp.opcode = COMP_DBID_RESP;
        //rsp.txn_id = itb_id;
        rsp.txn_id = itbe.rq.txn_id; 
        rsp.src_id = HNF_ID;
        rsp.tgt_id = itbe.rq.src_id;

        rsp.rsp_type = 0;
        //rsp.addr = itbe.addr;
    }
}

void CacheController::sendRNFData(int itb_id, dats& dat) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(itb_id);

    #if DEBUG
    cout << "sendRNFData" << endl;
    itbe.printEntry();
    #endif

    l2_hm_state hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;
    req_opcode req = itbe.rq.opcode;
    long addr = itbe.rq.addr;

    //Generate data in case of a hit and when snoop is not reqd
    if(hm == HIT && genValidData(req) && !itbe.genSnoop) {
        dat.valid = true;
        dat.be = 0xFFFFFFFFFFFFFFFF;
        dat.dbid = itb_id;
        //dat.txn_id = itb_id;
        dat.txn_id = itbe.rq.txn_id;
        dat.src_id = HNF_ID;
        dat.tgt_id = itbe.rq.src_id;

        //dat.addr = itbe.addr;
        dat.opcode = COMP_DATA;
        dat.rsp_err = OK;

        //TODO: Implement a better way to assign state
        if(new_entry.getCState() == MT)
            dat.rsp = UC;

        copyData(dat.data, new_entry.getDataPtr());
    }
}

void CacheController::sendSNFData(rsps& rspi, dats& dat) {

    HNFModel &hnf = HNFModel::getInstance();
    int vtb_id = rspi.txn_id;

    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(vtb_id);

    #if DEBUG
    cout << "sendSNFData" << endl;
    vtbe.printEntry();
    #endif

    l2_hm_state hm = vtbe.hm_state;
    l2_c_state state = vtbe.curr_entry.getCState();
    CacheEntry& entry = vtbe.curr_entry;
    CacheEntry& new_entry = vtbe.new_entry;
    req_opcode req = vtbe.rq.opcode;
    long addr = vtbe.rq.addr;

    //Generate data  when snoop is not reqd and when there is a victim
    if(!vtbe.genSnoop && vtbe.genVictim) {
        dat.valid = true;
        dat.be = 0xFFFFFFFFFFFFFFFF;
        dat.dbid = vtb_id;
        dat.txn_id = rspi.dbid;
        dat.src_id = HNF_ID;
        dat.tgt_id = SNF_ID;

        //dat.addr = vtbe.addr;
        dat.opcode = NON_COPY_BACK_WR_DATA;
        dat.rsp_err = OK;

        dat.rsp = I;

        copyData(dat.data, new_entry.getDataPtr());
    } else {
        assert(false);
    }
}

void CacheController::processRequestResponse(rsps& rsp, dats& dat) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(rsp.txn_id);
    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(itbe.vict_id);

    #if DEBUG
    cout << "procecssRequestResponse" << endl;
    itbe.printEntry();
    #endif

    assert(itbe.valid);

    l2_hm_state hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;
    long addr = computeTag(itbe.rq.addr);

    if(rsp.opcode == SNP_RESP) {
        itbe.ack_count--;

        if(itbe.ack_count == 0) {
            itbe.genSnoop = false;
            sendRNFData(rsp.txn_id, dat);
        }

    } else if(rsp.opcode == COMP_ACK) {
        assert(itbe.expCompAck);
        //update cache block with new data
        CacheSet& s = hnf.getCacheSet(itbe.index);
        CacheEntry& e = s.getCacheEntry(itbe.way);
        e = new_entry;

        //replace old addr in tag store with new addr. for miss
        //for hits this should not lead to state change
        long repl_addr = -1;
        if(entry.isValid() && entry.getTag() != new_entry.getTag()) {
            repl_addr = entry.getTag();
        }
        s.replaceTag(repl_addr, addr, itbe.way);

        //print status of buffers
        #if DEBUG
        hnf.printBufferStatus();
        #endif

        //clear itbe
        hnf.removefromRequestBuffer(itbe.id);
        //for accesses without victims also clear vtbe
        if(vtbe.valid && !vtbe.genSnoop && !vtbe.genVictim)
            hnf.removefromVictimBuffer(vtbe.id);

        //cout << "Printing entry after receiving CompAck:" << endl;

        #if DEBUG
        e.printEntry();
        #endif
    } else {
        assert(false);
    }
}

void CacheController::processVictimResponse(rsps& rspi, reqs& req, dats& dat) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(rspi.txn_id);

    #if DEBUG
    cout << "procecssVictimResponse" << endl;
    vtbe.printEntry();
    #endif

    assert(vtbe.valid);

    l2_hm_state hm = vtbe.hm_state;
    l2_c_state state = vtbe.curr_entry.getCState();
    CacheEntry& entry = vtbe.curr_entry;
    CacheEntry& new_entry = vtbe.new_entry;

    if(rspi.opcode == SNP_RESP) {
        vtbe.ack_count--;

        if(vtbe.ack_count == 0) {
            vtbe.genSnoop = false;
            sendVictimRequest(rspi.txn_id, req);
            //for accesses without victims also clear vtbe
            if(!vtbe.genVictim)
                hnf.removefromVictimBuffer(vtbe.id);
        }

    } else if(rspi.opcode == COMP_DBID_RESP) {
        sendSNFData(rspi, dat);
        //for accesses with victim clear vtbe after COMP_DBIS_RESP from mem
        hnf.removefromVictimBuffer(vtbe.id);
    } else {
        assert(false);
    }
}

void CacheController::processRequestData(dats& dati, dats& dat) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& itbe = hnf.getRequestBufferEntry(dati.txn_id);
    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(itbe.vict_id);


    #if DEBUG
    cout << "processRequestData" << endl;
    itbe.printEntry();
    #endif

    assert(itbe.valid);

    l2_hm_state& hm = itbe.hm_state;
    l2_c_state state = itbe.curr_entry.getCState();
    CacheEntry& entry = itbe.curr_entry;
    CacheEntry& new_entry = itbe.new_entry;


    if(dati.opcode == SNP_RSP_DATA) {
        itbe.ack_count--;

        if(itbe.ack_count == 0) {

            assert(hm == HIT);
            itbe.genSnoop = false;
            copyData(new_entry.getDataPtr(), dati.data);
            new_entry.setDirty();
            sendRNFData(dati.txn_id, dat);

        }
    } else if (dati.opcode == COMP_DATA) {

        assert(hm == MISS);
        copyData(new_entry.getDataPtr(), dati.data);
        hm = HIT;
        sendRNFData(dati.txn_id, dat);
    } else if (dati.opcode == COPY_BACK_WR_DATA){

        CacheSet& s = hnf.getCacheSet(itbe.index);
        CacheEntry& e = s.getCacheEntry(itbe.way);

        if(hm == HIT && !itbe.wb_hazard) {
            copyData(new_entry.getDataPtr(), dati.data);
            e = new_entry;
        } else {
            //cout << "COPY_BACK_WR_DATA HAZARD!" << endl;
        }

        //print status of buffers
        #if DEBUG
        cout << "Printing entry after receiving COPY_BACK_WR_DATA:" << endl;
        e.printEntry();
        hnf.printBufferStatus();
        #endif

        //clear itbe
        hnf.removefromRequestBuffer(itbe.id);
        //for accesses without victims also clear vtbe
        assert(vtbe.valid);
        assert(!vtbe.genSnoop);
        assert(!vtbe.genVictim);
        hnf.removefromVictimBuffer(vtbe.id);
    } else {
        assert(false);
    }
}

void CacheController::processVictimData(dats& dati, reqs& req) {

    HNFModel &hnf = HNFModel::getInstance();

    PendingBuffer::PendingBufferEntry& vtbe = hnf.getVictimBufferEntry(dati.txn_id);

    #if DEBUG
    cout << "procecssVictimData" << endl;
    vtbe.printEntry();
    #endif

    assert(vtbe.valid);

    l2_hm_state hm = vtbe.hm_state;
    l2_c_state state = vtbe.curr_entry.getCState();
    CacheEntry& entry = vtbe.curr_entry;
    CacheEntry& new_entry = vtbe.new_entry;

    if(dati.opcode == SNP_RSP_DATA) {
        vtbe.ack_count--;

        if(vtbe.ack_count == 0) {

            vtbe.genSnoop = false;
            copyData(new_entry.getDataPtr(), dati.data);
            new_entry.setDirty();
            sendVictimRequest(vtbe.id, req);

        }
    } else {
        assert(false);
    }
}
/*functions in l2model that interact with other components*/

CacheSet& HNFModel::getCacheSet(int id) {
    assert(id < NUM_SETS);
    //Get cache set
    return cache_set[id];
}

int HNFModel::addtoRequestBuffer(CacheEntry& cache_entry, reqs& req, l2_hm_state hm_state, int way, int id = -1) {
    long addr = computeTag(req.addr);
    assert(pending_accesses.find(addr) == pending_accesses.end());
    pending_accesses.insert(addr);
    return request_buffer.addtoBuffer(addr, cache_entry, req, hm_state, way, id);
}

long HNFModel::removefromRequestBuffer(int id) {
    long addr = request_buffer.removefromBuffer(id);
    assert(pending_accesses.find(addr) != pending_accesses.end());
    pending_accesses.erase(addr);
    return addr;
}

int HNFModel::addtoVictimBuffer(CacheEntry& cache_entry, reqs& req, l2_hm_state hm_state, int way, int id = -1) {
    long addr = computeTag(cache_entry.getTag());
    assert(pending_victims.find(addr) == pending_victims.end());
    pending_victims.insert(addr);
    return victim_buffer.addtoBuffer(addr, cache_entry, req, hm_state, way, id);
}

long HNFModel::removefromVictimBuffer(int id) {
    long addr = victim_buffer.removefromBuffer(id);
    assert(pending_victims.find(addr) != pending_victims.end());
    pending_victims.erase(addr);
    return addr;
}

PendingBuffer::PendingBufferEntry& HNFModel::getRequestBufferEntry(int id) {
    assert(id < NUM_PENDING);
    return request_buffer.getEntry(id);
}

PendingBuffer::PendingBufferEntry& HNFModel::getVictimBufferEntry(int id) {
    assert(id < NUM_PENDING);
    return victim_buffer.getEntry(id);
}

bool HNFModel::canProcessRequest(long addr) {
    if(pending_accesses.find(addr) != pending_accesses.end() || pending_victims.find(addr) != pending_victims.end())
        return false;

    if(pending_accesses.size() == NUM_PENDING)
        return false;

    return true;
}

void HNFModel::printBufferStatus() {
    cout << "Request Buffer Size: " << pending_accesses.size() << endl;
    cout << "----------------------" << endl;
    request_buffer.printStatus();

    cout << "Victim Buffer Size: " << pending_victims.size() << endl;
    cout << "----------------------" << endl;
    victim_buffer.printStatus();
}

void HNFModel::processRequest(reqs& reqi, reqs& req1, reqs& req2, rsps& rsp, snps& snp, dats& dat) {

    bool victim = false;
    int way;
    long tag;
    long index;
    l2_hm_state hm_state;
    int itbe_id;
    int vtbe_id;

    //Reset op fields
    req1.reset();
    req2.reset();
    rsp.reset();
    snp.reset();
    dat.reset();

    //Get tag and index
    tag = computeTag(reqi.addr);
    index = computeSetIndex(tag);

    if(pending_victims.size()) {
        //incase of pending victim store the req for later processing and return
        assert(!blocked_request.valid);
        assert(pending_accesses.size() == 0);
        blocked_request = reqi;
        #if DEBUG
        cout << "BLOCKINGREQ because of pending victim" << endl;
        #endif
        return;
    }

    //Checks specific to MVP
    assert(pending_accesses.size() == 0);
    assert(pending_victims.size() == 0);

    //Check if request can be processed
    assert(canProcessRequest(tag));

    //Get cache set
    CacheSet &set = cache_set[index];


    #if DEBUG
    cout << "processRequest: " << endl;
    cout << "TAG : " << tag << " INDEX: " << index <<  " HM: " << hm_state << " WAY: " << way << endl;
    set.printSet();
    #endif

    //Check if req addr is a hit/miss
    hm_state = set.accessHitMiss(tag);

    //Get cache entry for handling
    if(hm_state == MISS) {
        way = set.selectReplacementWay();
    } else {
        way = set.accessTag(tag);
    }

    CacheEntry &cache_entry = set.getCacheEntry(way);

    //Allocate ITB and VTB
    //itbe_id = addtoRequestBuffer(cache_entry, reqi, hm_state, way, reqi.txn_id);
    itbe_id = addtoRequestBuffer(cache_entry, reqi, hm_state, way, LLC_REQ_BUFF_ID);
    vtbe_id = addtoVictimBuffer(cache_entry, reqi, hm_state, way, LLC_VICT_BUFF_ID);

    //check if snoop needs to be sent out
    CoherenceController& coc = CoherenceController::getInstance();
    CacheController& cac = CacheController::getInstance();

    //check if snoop needs to be sent out
    coc.sendSnoop(itbe_id, vtbe_id, snp);
    //check if request needs to be sent out
    cac.sendRequest(itbe_id, req1);
    cac.sendVictimRequest(vtbe_id, req2);
    //check if response needs to be sent out
    cac.sendReqResponse(itbe_id, rsp);
    //check if data needs to be sent out
    cac.sendRNFData(itbe_id, dat);

}

void HNFModel::processResponse(rsps& rspi, reqs& req, dats& dat, reqs& req1, reqs& req2, rsps& rsp1, snps& snp1, dats& dat1) {

    CacheController& cac = CacheController::getInstance();

    //Reset op fields
    req.reset();
    dat.reset();

    if(rspi.txn_id < (NUM_PENDING/2)) {
        cac.processRequestResponse(rspi, dat);

    } else {
       cac.processVictimResponse(rspi, req, dat);

        if(blocked_request.valid && pending_victims.size() == 0) {
            #if DEBUG
            cout << "REPLAYING BLOCKEDREQ " << endl;
            #endif
            processRequest(blocked_request, req1, req2, rsp1, snp1, dat1);
            blocked_request.reset();
        }

    }
}

void HNFModel::processData(dats& dati, reqs& req, dats& dat) {

    CacheController& cac = CacheController::getInstance();

    //Reset op fields
    req.reset();
    dat.reset();

    if(dati.txn_id < (NUM_PENDING/2))
        cac.processRequestData(dati, dat);
    else
        cac.processVictimData(dati, req);

}

HNFModel& HNFModel::getInstance() {
    static HNFModel* hnf_model = nullptr;
    if(!hnf_model)
        hnf_model = new HNFModel();
    return *hnf_model;
}

HNFModel::HNFModel() {
    cache_set.resize(NUM_SETS);
}
