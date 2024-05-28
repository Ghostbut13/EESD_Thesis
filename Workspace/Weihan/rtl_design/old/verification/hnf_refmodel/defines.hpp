#define NUM_CORES 1
#define NUM_WAYS 1
#define NUM_SETS 512
#define SET_INDEX 9
#define BLOCK_SIZE 64
#define BLOCK_OFFSET 6
#define SNP_OFFSET 3
#define NUM_PENDING 256
#define HNF_ID 32
#define SNF_ID 64
#define LLC_REQ_BUFF_ID 0
#define LLC_VICT_BUFF_ID 129

#ifdef DEBUGMSG_REF_MODEL
#define DEBUG 1
#else
#define DEBUG 0
#endif

enum l2_hm_state {
	MISS = 0x0,
	HIT = 0x1
};

enum l2_iv_state {
	INVALID = 0x0,
	VALID  = 0x1
};

enum l2_cd_state {
	CLEAN = 0x0,
	DIRTY = 0x1
};

enum l1_c_state {
	I = 0x0,
	SC = 0x1,
	UC = 0x2,
	UD = 0x3
};
enum l2_c_state {
	NP = 0x0,
	S = 0x1,
	M = 0x2,
	MT = 0x3
};

enum l2_t_state {
	MT_S = 0x0,
	MT_MT = 0x1,
	S_MT = 0x2,
	MT_MI = 0x3,
	S_M  = 0x4,
	CI = 0x5,
	CS = 0x6,
	A_M = 0x7,
	S_CU = 0x8,
	MT_M = 0x9,
	MT_I = 0xa,
	S_I = 0xb,
	NA = 0xc
};

enum l2_resp {
	OK  = 0,
	XOK = 1
};

enum req_opcode {
        REQ_LCRD_RETURN   = 0x0,
        READ_SHARED       = 0x1,
        READ_CLEAN        = 0x2,
        READ_ONCE         = 0x3,
        READ_NO_SNP       = 0x4,
        PC_RD_RETURN      = 0x5,
        READ_UNIQUE       = 0x7,
        CLEAN_SHARED      = 0x8,
        CLEAN_INVALID     = 0x9,
        MAKE_INVALID      = 0xa,
        CLEAN_UNIQUE      = 0xb,
        MAKE_UNIQUE       = 0xc,
        EVICT             = 0xd,
        READ_NO_SNP_SEP   = 0x11,
        DVM_OP            = 0x14,
        WRITE_EVICT_FULL  = 0x15,
        WRITE_CLEAN_FULL  = 0x17,
        WRITE_UNIQUE_PTL  = 0x18,
        WRITE_UNIQUE_FULL = 0x19,
        WRITE_BACK_PTL    = 0x1a,
        WRITE_BACK_FULL   = 0x1b,
        WRITE_NO_SNP_PTL  = 0x1c,
        WRITE_NO_SNP_FULL = 0x1d,
        WRITE_UNIQUE_FULL_STASH = 0x20,
        WRITE_UNIQUE_PTL_STASH  = 0x21,
        STASH_ONCE_SHARED       = 0x22,
        STASH_ONCE_UNIQUE       = 0x23,
        READ_ONCE_CLEAN_INVALID = 0x24,
        READ_ONCE_MAKE_INVALID = 0x25,
        READ_NOT_SHARED_DIRTY  = 0x26,
        CLEAN_SHARED_PERSIST   = 0x27,
        ATOMIC_STORE_ADD       = 0x28,
        ATOMIC_STORE_CLR       = 0x29,
        ATOMIC_STORE_EOR       = 0x2A,
        ATOMIC_STORE_SET       = 0x2B,
        ATOMIC_STORE_SMAX      = 0x2C,
        ATOMIC_STORE_SMIN      = 0x2D,
        ATOMIC_STORE_UMAX      = 0x2E,
        ATOMIC_STORE_UMIN      = 0x2F,
        ATOMIC_LOAD_ADD        = 0x30,
        ATOMIC_LOAD_CLR        = 0x31,
        ATOMIC_LOAD_EOR        = 0x32,
        ATOMIC_LOAD_SET        = 0x33,
        ATOMIC_LOAD_SMAX       = 0x34,
        ATOMIC_LOAD_SMIN       = 0x35,
        ATOMIC_LOAD_UMAX       = 0x36,
        ATOMIC_LOAD_UMIN       = 0x37,
        ATOMIC_SWAP            = 0x38,
        ATOMIC_COMPARE         = 0x39,
        PREFETCH_TGT           = 0x3a,
		INV                     = 0x40
};

enum rsp_opcode {
        RESP_LCRD_RETURN = 0x0,
        SNP_RESP         = 0x1,
        COMP_ACK         = 0x2,
        RETRY_ACK        = 0x3,
        COMP             = 0x4,
        COMP_DBID_RESP   = 0x5,
        DBID_RESP        = 0x6,
        PC_RD_GRANT      = 0x7,
        READ_RECEIPT     = 0x8,
        SNP_RESP_FWDED   = 0x9,
        RESP_SEP_DATA    = 0xb

};

enum snp_opcode {
        SNP_LCRD_RETURN        = 0x0,
        SNP_SHARED             = 0x1,
        SNP_CLEAN              = 0x2,
        SNP_ONCE               = 0x3,
        SNP_NOT_SHARED_DIRTY   = 0x4,
        SNP_UNIQUE_STASH       = 0x5,
        SNP_MAKE_INVALID_STASH = 0x6,
        SNP_UNIQUE             = 0x7,
        SNP_CLEAN_SHARED       = 0x8,
        SNP_CLEAN_INVALID      = 0x9,
        SNP_MAKE_INVALID       = 0xa,
        SNP_STASH_UNIQUE       = 0xb,
        SNP_STASH_SHARED       = 0xc,
        SNP_DVM_OP             = 0xd,
        SNP_SHARED_FWD         = 0x11,
        SNP_CLEAN_FWD          = 0x12,
        SNP_ONCE_FWD           = 0x13,
        SNP_NOT_SHARED_DIRTY_FWD = 0x14,
        SNP_UNIQUE_FWD         = 0x17
};

enum dat_opcode {
        DATA_LCRD_RETURN     = 0x0,
        SNP_RSP_DATA         = 0x1,
        COPY_BACK_WR_DATA    = 0x2,
        NON_COPY_BACK_WR_DATA = 0x3,
        COMP_DATA            = 0x4,
        SNP_RESP_DATA_PTL    = 0x5,
        SNP_RESP_DATA_FWDED  = 0x6,
        WRITE_DATA_CANCEL    = 0x7,
        DATA_SEP_RESP        = 0xb,
        NCB_WR_DATA_COMP_ACK = 0xc

};
