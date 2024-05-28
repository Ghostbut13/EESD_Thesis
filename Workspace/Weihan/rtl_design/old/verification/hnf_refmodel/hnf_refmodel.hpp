#include "defines.hpp"
#include <iostream>
#include <vector>
#include <unordered_map>
#include <bitset>
#include <cassert>
#include <string>
#include <queue>
#include <unordered_set>

using std::cin;
using std::cout;
using std::endl;
using std::vector;
using std::unordered_map;
using std::bitset;
using std::string;
using std::queue;
using std::unordered_set;

/*REQ,RSP,SNP,DAT structs*/
struct reqs {
    bool valid;
    bool exp_comp_ack;
    bool excl;
    long addr;
    req_opcode opcode;
    int txn_id;
    int src_id;
    int tgt_id;
    bool alloc; //-- for readonce and writeunique transactions

    //reqs();
    void reset();
};

struct rsps {
    bool valid;
    int dbid;
    l1_c_state resp;
    l2_resp resp_err;
    rsp_opcode opcode;
    int txn_id;
    int src_id;
    int tgt_id;
    bool rsp_type; //response type (1: With Data, 0: Dataless)
    long addr;

    //rsps();
    void reset();
};

struct snps {
    bool valid;
    long tgt_id;
    long addr;
    snp_opcode opcode;
    int txn_id;
    int src_id;

    //snps();
    void reset();
};

struct dats {
    bool valid;
    unsigned long data[8];
    long be;
    int dbid;
    l1_c_state rsp;
    l2_resp rsp_err;
    dat_opcode opcode;
    int txn_id;
    int src_id;
    int tgt_id;
    long addr;

    //dats();
    void reset();
};


/*The state tracked for each cache block
*/
class CacheEntry {
    //State associated with cache
    l2_iv_state iv_state;
    l2_cd_state cd_state;

    //State associated with coherence
    l2_c_state c_state;
    bitset<NUM_CORES> p_bits;

    long tag;
    unsigned long data[8];

public:
    CacheEntry();
    void resetEntry();
    void printEntry();
    long getTag();
    unsigned long* getDataPtr();
    bool isValid();
    bool isDirty();
    void setDirty();
    l2_c_state getCState();
    void setCState(l2_c_state);
    void setOwner(int id);
    bitset<NUM_CORES> getSharers();
    bool isSharer(int id);
    void addSharer(int id);
    int numSharers();
    void resetSharers();
    void updateEntry(l2_iv_state iv, l2_cd_state cd, l2_c_state cs, int core_id, long addr);

};

/* represents the state for tracking replacmeent policy info*/
class ReplacementPolicy {
    vector<long> lru_state;
    int access_count;

public:
    ReplacementPolicy();
    void updateAccessCount();
    int getAccessCount();
    void updateReplacementState(int way);
    int getReplacementCandidate();
    void print(int way);

};

/* represents a single set which comprises multiple ways in the L2 cache
Replacement policy info is tracked on a per set basis*/

class CacheSet {
    vector<CacheEntry> data_arr;
    unordered_map<long, int> tags;
    ReplacementPolicy repl;

public:
    CacheSet();
    CacheEntry& getCacheEntry(int way);
    int accessTag(long tag);
    void replaceTag(long repl_addr, long addr, int way);
    l2_hm_state accessHitMiss(long tag);
    int selectReplacementWay();
    void printSet();
};

/* represents the Pending Request Buffer and Pending Victim Buffer state management*/

class PendingBuffer {
public:
    class PendingBufferEntry {
    public:

        CacheEntry curr_entry;
        CacheEntry new_entry;
        reqs rq;

        //Fields to track inflight req status
        l2_hm_state hm_state;
        long addr;
        l2_t_state t_state;
        bool wb_hazard;
        int way;
        int index;
        int ack_count;
        int id;
        int vict_id;
        bool valid;

        bool genSnoop;
        bool genVictim;
        bool expCompAck;

        void setValid();
        void resetValid();
        void resetPBEntry();
        void initializeBuffer(long addr, CacheEntry& cache_entry, reqs& req, l2_hm_state hm, int id, int way);
        void printEntry();
        PendingBufferEntry();
    };

    unordered_set<int> used_list;
    queue<int> free_list;
    vector<PendingBufferEntry> buffer;

    PendingBufferEntry& getEntry(int id);
    int addtoBuffer(long addr, CacheEntry& cache_entry, reqs& req, l2_hm_state hm, int id, int way);
    long removefromBuffer(int id);
    void printStatus();
    PendingBuffer();
};

/* represents the HN coherence controller. It also performs the task of free
list management. The task is to update coherence states and track the states for pending request and evict transactions.*/

class CoherenceController {
private:
    CoherenceController();
    CoherenceController(CoherenceController& s) = delete;
    CoherenceController& operator= (CoherenceController& s) = delete;

public:
    static CoherenceController& getInstance();
    void sendSnoop(int itb_id, int vtb_id, snps& snp);
};

class CacheController {
private:
    CacheController();
    CacheController(CacheController &c) = delete;
    CacheController& operator= (CacheController& c) = delete;

public:
    static CacheController& getInstance();
    void sendRequest(int itb_id, reqs& req);
    void sendVictimRequest(int vtb_id, reqs& req);
    void sendReqResponse(int itb_id, rsps& rsp);
    void sendRNFData(int itb_id, dats& dat);
    void sendSNFData(rsps& rspi, dats& dat);

    void processRequestResponse(rsps& rspi, dats& dat);
    void processVictimResponse(rsps& rspi, reqs& req, dats& dat);
    void processRequestData(dats& dati, dats& dat);
    void processVictimData(dats& dati, reqs& req);

};

/* represents the l2cache with multiple sets/ways
*/
class HNFModel {
private:
    //data, tag and state store
    vector<CacheSet> cache_set;

    //inflight request and victim buffers and CAM
    PendingBuffer request_buffer;
    PendingBuffer victim_buffer;
    unordered_set<long> pending_accesses;
    unordered_set<long> pending_victims;
    reqs blocked_request;

    HNFModel();
    HNFModel(HNFModel &m) = delete;
    HNFModel& operator= (HNFModel& m) = delete;

public:
    static HNFModel& getInstance();

    //misc. functions
    CacheSet& getCacheSet(int id);

    //functions related to transaction buffer management
    int addtoRequestBuffer(CacheEntry& cache_entry, reqs& req, l2_hm_state hm, int way, int id);
    int addtoVictimBuffer(CacheEntry& cache_entry, reqs& req, l2_hm_state hm, int way, int id);
    long removefromRequestBuffer(int id);
    long removefromVictimBuffer(int id);
    PendingBuffer::PendingBufferEntry& getRequestBufferEntry(int id);
    PendingBuffer::PendingBufferEntry& getVictimBufferEntry(int id);
    bool canProcessRequest(long addr);
    void printBufferStatus();

    //simulates request handling
    void processRequest(reqs& reqi, reqs& req1, reqs& req2, rsps& rsp, snps& snp, dats& dat);
    //simulates response handling
    void processResponse(rsps& rspi, reqs& req, dats& dat, reqs& req1, reqs& req2, rsps& rsp1, snps& snp1, dats& dat1);
    //simulates data handling
    void processData(dats& dati, reqs& req, dats& dat);
};
