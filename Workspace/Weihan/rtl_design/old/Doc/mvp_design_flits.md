#Minimum Viable Product Design

## Node ID Ranges

| RNF   | HN    | SN        | 
| ---   | ---   | ---       |
| 0-31  | 32-63 | $\ge$ 64  | 

## Request Flit Content 

| Feild             | Value             |  Comment  | 
| ----------------- | ----------------- | --------  | 
| src_id            | This node ID      | |
| tgt_id            | Target node ID    | |   
| txn_id            | @RN: set value e.g. RN buff-ID<br /> @HN: set value e.g. HN buff-ID   | | 
| return_txn_id     | = hn.Buff-ID : if (HN->SN & ReadNoSnp/WriteNoSnp) <br /> = 0 : otherwise (NA)  | DMT not supported | 
| return_nid        | = HN-ID: if (HN->SN & ReadNoSnp/WriteNoSnp) <br /> = 0: otherwise (NA)  | DMT not supported | 
| addr              | req. address      | |
| opcode            | req. opcode       | |     
| trace_tag         | = 0 | Packet is not tagged | 
| tag_op            | = 0 (tags invalid) | mem. tagging not supported  | 
| exp_comp_ack      | = 0: if no CompAck <br /> = 1: if CompAck
| excl              | = 0 | Exclusives not supported
| persistence_gid   | = 0 | not supported |   
| snp_attr          | = 0: if NoSnp (HN->SN) <br /> = 1: if snoopable (RNF->HN)
| mem_attr          | = 'b1100 | [Allocate, Cacheable, Normal Mem., EWA not permitted]
| pcrd_type         | = 0 | retry not supported | 
| order             | = 0 | no ordering required |  
| allow_retry       | = 0 | not supported | 
| likely_shared     | = 0 | not supported |   
| non_secure_ext    | = 0 | [NSE, NS] = 01 : Non-secure   | 
| non_secure        | = 1 | [NSE, NS] = 01 : Non-secure   | 
| size              | = 'b110  | 64 bytes |   
| stash_nid_valid   | = 0 | Not supported |        
| qos               | = 'hF              | equal priority for all (max prio.)|    


## Response Flit Content 

| Feild       | Value             |  Comment  | 
| ----------- | ----------------- | --------  | 
| src_id      | This node ID | | 
| tgt_id      | Target node ID | CompData.hnid : if CompAck| 
| txn_id      | = CompData.dbid: if CompAck <br /> = Req.txn_id: if DBIDResp <br /> = snp.txn_id: if SnpRsp | | 
| dbid        | = 0 (NA): if CompAck or SnpRsp<br /> = Buff-ID: if DBIDResp | | 
| trace_tag   | = 0 | Packet is not tagged | 
| tag_op      | = 0 (tags invalid) | mem. tagging not supported  | 
| pcrd_type   | = 0 | retry not supported |   
| cbusy       | = 0 | not supported | 
| fwd_state   | = 0 | not supported | 
| resp        | = RN final state : if SnpRsp or CompAck <br /> = 0 : otherwise |  | 
| resp_err    | = 0 | Normal: No erorr | 
| opcode      | Response opcode | | 
| qos         | = 'hF  | equal priority for all (max prio.)|    

## Data Flit Content 

| Feild       | Value             |  Comment  | 
| ----------- | ----------------- | --------  | 
| src_id      | This node ID | |   
| tgt_id      | Target node ID | |  
| txn_id      | = req.txn_id: if CompData  <br /> = DBIDResp.dbid: if WrData <br /> = snp.txn_id: if SnpRspData | |
| dbid        | Buff-ID | | 
| home_nid    | = HN-ID: if CompData from HN <br /> = 0 (NA): otherwise | | 
| data_id     | = 'b00 | for 512 bit data bus width | 
| cc_id       | = 0 | does't matter / not supported | 
| data        | data value |  | 
| be          | all bits = 1 | all bytes valid |  
| cah         | = 1   | Inclusive assumption | 
| trace_tag   | = 0 | Packet is not tagged |         
| tu          | = 0 | Not Supported | 
| tag         | = 0 | Not Supported | 
| tag_op      | = 0 | Not Supported |       
| cbusy       | = 0 | Not supported |   
| data_source | = 0  | Not required |        
| resp        | = {1,RN final state} : RN-WrData or HN-CompData <br /> = 0 : otherwise |  | 
| resp_err    | = 0 | Normal: No erorr |        
| opcode      | data response opcode | |       
| qos         | = 'hF  | equal priority for all (max prio.)|    

## Snoop Flit Content 

| Feild             | Value             |  Comment  | 
| ----------------  | ----------------- | --------  | 
| src_id            | This node ID  | |         
| tgt_mask          | Bit mask of target nodes |           
| txn_id            | Buff-ID | |         
| fwd_txn_id        | = 0 | not supported |             
| fwd_nid           | = 0 | not supported |          
| trace_tag         | = 0 | Packet is not tagged |           
| ret_to_src        | = 0 | not return a copy if line is clean |            
| do_not_go_to_sd   | = 1 | must be 1 for SNP_CLEAN_I |                  
| non_secure_ext    | = 0 | [NSE, NS] = 01 : Non-secure   |                
| non_secure        | = 1 | [NSE, NS] = 01 : Non-secure   |            
| addr              | snoop address | |       
| opcode            | snoop opcode  | | 
| qos               | = 'hF  | equal priority for all (max prio.)|     