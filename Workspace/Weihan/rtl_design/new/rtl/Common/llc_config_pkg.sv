package llc_config_pkg; 
    parameter int unsigned LLC_DATA_WIDTH = 512; 
    parameter int unsigned LLC_ADDR_WIDTH = 48; 
    parameter int unsigned LLC_OFFSET = 6;
    //parameter int unsigned LLC_OFFSET_WIDTH = $clog2(LLC_OFFSET);
    parameter int unsigned LLC_SET_NUM = 512; 
    parameter int unsigned LLC_INDEX_WIDTH = $clog2(LLC_SET_NUM);   
    parameter int unsigned LLC_TAG_WIDTH = (LLC_ADDR_WIDTH - LLC_INDEX_WIDTH - LLC_OFFSET);
    // NoC parameters
    parameter int unsigned NOC_CRD_WIDTH = 4; 
    //parameter logic [2:0] DATA_FLIT_SIZE = 3'b110; // 512 bit data-width -> 64 Bytes
endpackage: llc_config_pkg