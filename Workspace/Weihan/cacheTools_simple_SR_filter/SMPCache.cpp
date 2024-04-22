// Here, only contain the dump(output), not key func
// key func in MSI_SMPCache.cpp & MESI_SMPCache.cpp

#include "SMPCache.h"
#include <iostream>

SMPCache::SMPCache(int cpuid, std::vector<SMPCache * > * cacheVector){

  CPUId = cpuid;
  allCaches = cacheVector;

  numReadHits = 0;
  numReadMisses = 0;
  numReadOnInvalidMisses = 0;
  numReadRequestsSent = 0;
  numReadMissesServicedByOthers = 0;
  numReadMissesServicedByShared = 0;
  numReadMissesServicedByModified = 0;

  numWriteHits = 0;
  numWriteMisses = 0;
  numWriteOnSharedMisses = 0;
  numWriteOnInvalidMisses = 0;
  numInvalidatesSent = 0;

  //Cache unnessasary request
  EmptyLookUp = 0;
}

void SMPCache::conciseDumpStatsToFile(std::ostream& outFile){

  // fprintf(outFile,"%lu,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
  // 	  CPUId,
  // 	  numReadHits,
  // 	  numReadMisses,
  // 	  numReadOnInvalidMisses,
  // 	  numReadRequestsSent,
  // 	  numReadMissesServicedByOthers,
  // 	  numReadMissesServicedByShared,
  // 	  numReadMissesServicedByModified,
  // 	  EmptyLookUp,
  // 	  numWriteHits,
  // 	  numWriteMisses,
  // 	  numWriteOnSharedMisses,
  // 	  numWriteOnInvalidMisses,
  // 	  numInvalidatesSent);
outFile << CPUId << "," 
        << numReadHits << "," 
        << numReadMisses << ","
        << numReadOnInvalidMisses << ","
        << numReadRequestsSent << ","
        << numReadMissesServicedByOthers << ","
        << numReadMissesServicedByShared << ","
        << numReadMissesServicedByModified << ","
        << numWriteHits << ","
        << numWriteMisses << ","
        << numWriteOnSharedMisses << ","
        << numWriteOnInvalidMisses << ","
        << numInvalidatesSent << ","
        << EmptyLookUp << ","
        << std::endl;

}

void SMPCache::dumpStatsToFile(std::ostream& outFile){
  // fprintf(outFile, "-----Cache %lu-----\n",CPUId);

  // fprintf(outFile, "Read Hits:                   %d\n",numReadHits);
  // fprintf(outFile, "Read Misses:                 %d\n",numReadMisses);
  // fprintf(outFile, "Read-On-Invalid Misses:      %d\n",numReadOnInvalidMisses);
  // fprintf(outFile, "Read Requests Sent:          %d\n",numReadRequestsSent);
  // fprintf(outFile, "Rd Misses Serviced Remotely: %d\n",numReadMissesServicedByOthers);
  // fprintf(outFile, "Rd Misses Serviced by Shared: %d\n",numReadMissesServicedByShared);
  // fprintf(outFile, "Rd Misses Serviced by Modified: %d\n",numReadMissesServicedByModified);
  
  // fprintf(outFile, "Lookup Misses caused by snoop: %d\n",EmptyLookUp);

 
  // fprintf(outFile, "Write Hits:                  %d\n",numWriteHits);
  // fprintf(outFile, "Write Misses:                %d\n",numWriteMisses);
  // fprintf(outFile, "Write-On-Shared Misses:      %d\n",numWriteOnSharedMisses);
  // fprintf(outFile, "Write-On-Invalid Misses:     %d\n",numWriteOnInvalidMisses);
  // fprintf(outFile, "Invalidates Sent:            %d\n",numInvalidatesSent);
outFile << "-----Cache " << CPUId << "-----" << std::endl;
outFile << "Read Hits:                   " << numReadHits << std::endl;
outFile << "Read Misses:                 " << numReadMisses << std::endl;
outFile << "Read-On-Invalid Misses:      " << numReadOnInvalidMisses << std::endl;
outFile << "Read Requests Sent:          " << numReadRequestsSent << std::endl;
outFile << "Rd Misses Serviced Remotely: " << numReadMissesServicedByOthers << std::endl;
outFile << "Rd Misses Serviced by Shared: " << numReadMissesServicedByShared << std::endl;
outFile << "Rd Misses Serviced by Modified: " << numReadMissesServicedByModified << std::endl;
outFile << "Lookup Misses caused by snoop: " << EmptyLookUp << std::endl;
outFile << "Write Hits:                  " << numWriteHits << std::endl;
outFile << "Write Misses:                " << numWriteMisses << std::endl;
outFile << "Write-On-Shared Misses:      " << numWriteOnSharedMisses << std::endl;
outFile << "Write-On-Invalid Misses:     " << numWriteOnInvalidMisses << std::endl;
outFile << "Invalidates Sent:            " << numInvalidatesSent << std::endl;

}

int SMPCache::getCPUId(){
  return CPUId;
}


int SMPCache::getStateAsInt(unsigned long addr){
  return (int)this->cache->findLine(addr)->getState();
}

std::vector<SMPCache * > *SMPCache::getCacheVector(){
  return allCaches;
}

