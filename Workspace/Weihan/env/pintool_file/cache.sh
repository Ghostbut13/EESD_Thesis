#!/bin/bash

touch filter.log
touch MultiCachesim.log 
rm filter.log MultiCachesim.log
### unconcise output log
./pin -t /home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified/obj-intel64/mcs.so -protos /home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified/obj-intel64/MOESI_SMPCache.so -csize 32768 -bsize 64 -assoc 16 -numcaches 4  -concise 0  -- /home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified/Tests/simple/simple > filter.log
