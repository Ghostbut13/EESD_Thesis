#Minimum Viable Product Design

## Front Gate (llc_req_buffer_gate)

```plantuml 
@startuml 
title "Front Gate - Mealy State Machine"

state EMPTY : waiting for next req
state STALLED : waiting for resources
state BUSY : transaction in progress
state REPLAY : replay req

[*] --> EMPTY : rst_n \n <color:blue> lcrd_valid = 1
EMPTY --> EMPTY : !(flit_valid) 
EMPTY --> STALLED : flit_valid & hazard
EMPTY --> BUSY : flit_valid & !(hazard) \n <color:blue> o_req_valid = 1
STALLED --> BUSY : !(hazard)\n <color:blue> o_req_valid = 1
BUSY --> BUSY : else
BUSY --> REPLAY : replay \n <color:blue> o_req_valid = 1
BUSY --> EMPTY : clear_buffer \n <color:blue> lcrd_valid = 1
REPLAY --> BUSY: else
REPLAY --> EMPTY : clear_buffer \n <color:blue> lcrd_valid = 1


note "<color:blue> else: o_req_valid = 0 \n\n <color:blue> else: lcrd_valid = 0" as N1
@enduml 
```

####Assertions:
-  No new request (flit_valid) when not in EMPTY state
-  "clear_buffer" and "replay" signals should not be set in the same cycle. 


## Victim Buffer (llc_vict_buffer)


```plantuml 
@startuml 
title "Vict. Buffer - Mealy State Machine"

state EMPTY : waiting for next vict
state WAIT_SNP_RSP : waiting for snp_rsp from RN
state WAIT_DBID : waiting for DBID rsp from SN
state WRITEBACK: sending data to SN 

[*] --> EMPTY : if (rst_n) \n <color:blue> valid = 0
EMPTY --> WAIT_SNP_RSP : if (vict_valid) \n <color:blue> send SNP_I to RN
EMPTY --> EMPTY : else

WAIT_SNP_RSP --> EMPTY: if (SNP_RSP & Clean) \n <color:blue> valid = 0
WAIT_SNP_RSP --> WAIT_DBID: if (SNP_RSP_DAT or (SNP_RSP & Dirty)) \n <color:blue> send WR_No_SNP to SN (Update VB Data) 
WAIT_SNP_RSP --> WAIT_SNP_RSP: else 

WAIT_DBID --> WRITEBACK : if (DBID_rsp) \n <color:blue> send WrteData to SN
WAIT_DBID --> WAIT_DBID : else

WRITEBACK --> EMPTY : if (i_clear: from DataRspGen) \n <color:blue> valid = 0
WRITEBACK --> WRITEBACK : else

@enduml 
```
