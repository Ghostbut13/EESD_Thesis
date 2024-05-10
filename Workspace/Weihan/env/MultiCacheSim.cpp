#include "MultiCacheSim.h"

//  "MultiCacheSim.h" includes the declaration of function
//std::ofstream OutFile;


MultiCacheSim::MultiCacheSim(FILE *cachestats, int size, int assoc, int bsize, CacheFactory c){

  cacheFactory = c;
  CacheStats = cachestats;
  num_caches = 0;
  cache_size = size;
  cache_assoc = assoc;
  cache_bsize = bsize; 

  #ifndef PIN
  pthread_mutex_init(&allCachesLock, NULL);
  #else
  PIN_InitLock(&allCachesLock);
  #endif

}

SMPCache *MultiCacheSim::findCacheByCPUId(unsigned int CPUid){
    std::vector<SMPCache *>::iterator cacheIter = allCaches.begin();
    std::vector<SMPCache *>::iterator cacheEndIter = allCaches.end();
    for(; cacheIter != cacheEndIter; cacheIter++){
      if((*cacheIter)->CPUId == CPUid){
        return (*cacheIter);
	
      }
    }
    return NULL;
} 

void MultiCacheSim::dumpStatsForAllCaches(bool concise, std::ostream& outFile){
   
    std::vector<SMPCache *>::iterator cacheIter = allCaches.begin();
    std::vector<SMPCache *>::iterator cacheEndIter = allCaches.end();
    for(; cacheIter != cacheEndIter; cacheIter++){
      if(!concise){
        (*cacheIter)->dumpStatsToFile(outFile);
      }else{
	
	//fprintf(CacheStats,"CPUId, numReadHits, numReadMisses, numReadOnInvalidMisses, numReadRequestsSent, numReadMissesServicedByOthers, numReadMissesServicedByShared, numReadMissesServicedByModified, numWriteHits, numWriteMisses, numWriteOnSharedMisses, numWriteOnInvalidMisses, numInvalidatesSent,weihan'shere\n");
	outFile << "CPUId, numReadHits, numReadMisses, numReadOnInvalidMisses, numReadRequestsSent, numReadMissesServicedByOthers, numReadMissesServicedByShared, numReadMissesServicedByModified, numWriteHits, numWriteMisses, numWriteOnSharedMisses, numWriteOnInvalidMisses, numInvalidatesSent, EmptyLookUp" << std::endl;

	//// conciseDumpStatsToFile : most impotant. in SMPCache
	//// So, before enter dumpStatsForAllCaches, the iterator "i" is cores' index. Here, iterator "cacheIter" is global history index
	/// the class for global is SMPCache; and class of core is MultiCacheSim 
	
        (*cacheIter)->conciseDumpStatsToFile(outFile);

      }
    }
}

void MultiCacheSim::createNewCache(){

    #ifndef PIN
    pthread_mutex_lock(&allCachesLock);
    #else
    PIN_GetLock(&allCachesLock,1);
    // ------------------debug flag1-----------------
    #endif

    SMPCache * newcache ;
    // ------------------debug flag2------------------

    
    newcache = this->cacheFactory(num_caches, &allCaches, cache_size, cache_assoc, cache_bsize, 1, "LRU", false);

    num_caches++;

    // ------------------debug flag3------------------

    allCaches.push_back(newcache);


    #ifndef PIN
    pthread_mutex_unlock(&allCachesLock);
    #else
    PIN_ReleaseLock(&allCachesLock);
    // ------------------debug flag4

    #endif
}












void MultiCacheSim::readLine(unsigned long tid, unsigned long rdPC, unsigned long addr){
    #ifndef PIN
    pthread_mutex_lock(&allCachesLock);
    #else
    PIN_GetLock(&allCachesLock,1); 
    #endif


    SMPCache * cacheToRead = findCacheByCPUId(tidToCPUId(tid));
    if(!cacheToRead){
      return;
    }
    cacheToRead->readLine(rdPC,addr); //polymorphisms


    #ifndef PIN
    pthread_mutex_unlock(&allCachesLock);
    #else
    PIN_ReleaseLock(&allCachesLock); 
    #endif
    return;
}








void MultiCacheSim::writeLine(unsigned long tid, unsigned long wrPC, unsigned long addr){
    #ifndef PIN
    pthread_mutex_lock(&allCachesLock);
    #else
    PIN_GetLock(&allCachesLock,1); 
    #endif


    SMPCache * cacheToWrite = findCacheByCPUId(tidToCPUId(tid));
    if(!cacheToWrite){
      return;
    }
    cacheToWrite->writeLine(wrPC,addr);


    #ifndef PIN
    pthread_mutex_unlock(&allCachesLock);
    #else
    PIN_ReleaseLock(&allCachesLock); 
    #endif
    return;
}

int MultiCacheSim::getStateAsInt(unsigned long tid, unsigned long addr){

  SMPCache * cacheToWrite = findCacheByCPUId(tidToCPUId(tid));
  if(!cacheToWrite){
    return -1;
  }
  return cacheToWrite->getStateAsInt(addr);

}

int MultiCacheSim::tidToCPUId(int tid){
    //simple for now, perhaps we want to be fancier
    return tid % num_caches; 
}


// already declaration in .h
char *MultiCacheSim::Identify(){
  SMPCache *c = findCacheByCPUId(0);
  if(c != NULL){
    return c->Identify();  // calling the Iden in SMPCache
  }
  return 0;
}
  
MultiCacheSim::~MultiCacheSim(){
    std::vector<SMPCache *>::iterator cacheIter = allCaches.begin();
    std::vector<SMPCache *>::iterator cacheEndIter = allCaches.end();
    for(; cacheIter != cacheEndIter; cacheIter++){
      //delete (*cacheIter);
    }
}
