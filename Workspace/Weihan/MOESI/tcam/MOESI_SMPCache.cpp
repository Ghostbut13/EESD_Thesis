#include "MOESI_SMPCache.h"
#include <iostream>                                                 
#include <bitset>  


//tcam
#ifndef NUM_TCAM_Line
#define NUM_TCAM_Line 64
#endif

//bad coding style. but now, it is easy for me.
bool filter_initial_flag[4][4] =
  {1,1,1,1,
   1,1,1,1,
   1,1,1,1,
   1,1,1,1};
uint16_t filter_base[4][4]  =
  {0x3ff,0x3ff,0x3ff,0x3ff,
   0x3ff,0x3ff,0x3ff,0x3ff,
   0x3ff,0x3ff,0x3ff,0x3ff,
   0x3ff,0x3ff,0x3ff,0x3ff}; //10bit
uint16_t filter_mask[4][4]  =
  {0x000,0x000,0x000,0x000,
   0x000,0x000,0x000,0x000,
   0x000,0x000,0x000,0x000,
   0x000,0x000,0x000,0x000}; //10bit
uint16_t filter_ctr[4][4]   =
  {0,0,0,0,
   0,0,0,0,
   0,0,0,0,
   0,0,0,0};

//-----tcam------
bool     tcam_PB[NUM_TCAM_Line][4] = {0};
uint32_t tcam_TAG[NUM_TCAM_Line]   = {0};
uint16_t tcam_Pointer              = 0;
uint32_t tcam_LRU_ctr[NUM_TCAM_Line] = {0};



MOESI_SMPCache::MOESI_SMPCache(int cpuid, std::vector<SMPCache * > * cacheVector,
			       int csize, int cassoc, int cbsize, int caddressable, const char * repPol, bool cskew) : 
  SMPCache(cpuid,cacheVector){
  fprintf(stderr,"Making a MOESI cache with cpuid %d\n",cpuid);
  CacheGeneric<MOESI_SMPCacheState> *c = CacheGeneric<MOESI_SMPCacheState>::create(csize, cassoc, cbsize, caddressable, repPol, cskew);
  cache = (CacheGeneric<StateGeneric<> >*)c; 
}


void MOESI_SMPCache::fillLine(uint32_t addr, uint32_t moesi_state){
  MOESI_SMPCacheState *st = (MOESI_SMPCacheState *)cache->findLine2Replace(addr); //this gets the contents of whateverline this would go into
  if(st==0){
    return;
  }
  st->setTag(cache->calcTag(addr)); 	  //calcTag: the last 6 bits are diff
  st->changeStateTo((MOESIState_t)moesi_state);
  return;    
}

// check MOESI
void MOESI_SMPCache::checkMOESI(uint32_t addr){
  std::vector<SMPCache * >::iterator cacheIter;
  std::vector<SMPCache * >::iterator lastCacheIter;
  for(cacheIter = this->getCacheVector()->begin(), lastCacheIter = this->getCacheVector()->end(); cacheIter != lastCacheIter; cacheIter++){
    MOESI_SMPCache *otherCache = (MOESI_SMPCache*)*cacheIter; 
    MOESI_SMPCacheState* otherState= (MOESI_SMPCacheState *)otherCache->cache->findLine(addr);
    if(otherState){
      switch(( otherState -> getState()) ){
      case (0x00000001):
	std::cout << "Modified(UD) " << otherCache->getCPUId();
	break;
      case (0x00000010):
	std::cout << "Shared(SC) " << otherCache->getCPUId();
	break;
      case (0x00000100):
	std::cout << "Invalid(I) " << otherCache->getCPUId();
	break;
      case (0x00001000):
	std::cout << "Exclusive(UC) " << otherCache->getCPUId();
	break;
      case (0x00010000):
	std::cout << "OWNED(SD) " << otherCache->getCPUId();
	break;
      }
    }
    else{
      std::cout << "Invalid(I) " << otherCache->getCPUId();
    }
    std::cout << std::endl;
  }
}


void checkTCAM(){
  //check tcam
  std::cout << "=============" << std::endl;
  for(int i=0; i<NUM_TCAM_Line; i++){
    std::cout << tcam_TAG[i] ;
    std::cout << " | " ;
    for(int j=0; j<4; j++){
      std::cout << tcam_PB[i][j] ;
      std::cout << " | " ;
    }
    std::cout << tcam_LRU_ctr[i] << " | ";
    std::cout << std::endl;
  }
  //std::cout << "Pointer: " << tcam_Pointer << std::endl;
  std::cout << "=============" << std::endl;
  //********************************
}



//******************************
// filter
void MOESI_SMPCache::filterFilter(uint32_t addr, MOESI_SMPCache *otherCache){
  
}


void MOESI_SMPCache::filterUpdate_Store(uint32_t addr, bool WB){
  if(WB){// need invalid PB in old addr
    for(int i=0; i<NUM_TCAM_Line; i++){
      if((addr != tcam_TAG[i]) && ((cache->calcTag(tcam_TAG[i])) == (cache->calcTag(addr))) && (tcam_PB[i][this->getCPUId()] == true) ){ // old_addr is in tcam
	//std::cout << this->getCPUId()  << " , "<< (addr) << " , " << tcam_TAG[i]<<" , "<< tcam_PB[i][this->getCPUId()] << " , "<< i << std::endl;	

#ifdef debug	
	//checkTCAM();
	tcam_PB[i][this->getCPUId()] = false; // WriteBack (in cache) invoked by ReadShared
	//std::cout << " WriteBack (in cache) invoked by ReadShared" << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(cache->calcTag(addr)) << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(addr) << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(tcam_TAG[i]) << std::endl;
	//std::cout << (addr) << " , " << tcam_TAG[i]<<" , "<< tcam_PB[i][this->getCPUId()] << " , "<< i << std::endl;	
	//checkTCAM();
#else
	tcam_PB[i][this->getCPUId()] = false; // WriteBack (in cache) invoked by ReadShared, so need envict the '1' from PB
#endif
      }
    }
  }


  // LRU prepare
  for(int i=0; i<NUM_TCAM_Line; i++){
    if((tcam_PB[i][0] | tcam_PB[i][1] | tcam_PB[i][2] | tcam_PB[i][3]) != false){ // no-empty, so LRU-Ctr++
      tcam_LRU_ctr[i]=tcam_LRU_ctr[i]+1;
    }
  }
  
  int flag=0;
  for(int i=0; i<NUM_TCAM_Line; i++){
    if(tcam_TAG[i] == addr){ // addr is in tcam
      for(int j=0; j<4; j++){
	if(this->getCPUId()==j)
	  tcam_PB[i][j] = true; // Store (ReadUnique) 
	else
	  tcam_PB[i][j] = false; // Store (ReadUnique) invalidate others
      }
      flag=1;
      // LRU update
      tcam_LRU_ctr[i]=0;
    }
  }
  for(int i=0; i<NUM_TCAM_Line; i++){ // addr is NOT in tcam but tcam has empty entry
    if( (flag==0) && ((tcam_PB[i][0] | tcam_PB[i][1] | tcam_PB[i][2] | tcam_PB[i][3]) == false) ){ // tcam has empty entry
      tcam_PB[i][this->getCPUId()] = true;
      tcam_TAG[i]                  = addr;
      flag=1;
      // LRU update
      tcam_LRU_ctr[i]=0;
    }
  }

  if(flag==0){ // tcam has NO empty entry; 
    // LRU replacement
    uint32_t max     = 0;
    int      idx_max = 0;
    for(int i=0; i<NUM_TCAM_Line; i++){
      if(max <= tcam_LRU_ctr[i]){
	max = tcam_LRU_ctr[i];
	idx_max = i;
      }
    }
  
    for(int j=0; j<4; j++){
      if(this->getCPUId()==j)
	tcam_PB[idx_max][j] = true; // Store (ReadUnique)
      else
	tcam_PB[idx_max][j] = false; // Store (ReadUnique)
    }
    tcam_TAG[idx_max]       = addr;
    // LRU update
    tcam_LRU_ctr[idx_max]=0;
    flag=1;
  }
  
}


void MOESI_SMPCache::filterUpdate_Load(uint32_t addr, bool WB){
  if(WB==1){
    for(int i=0; i<NUM_TCAM_Line; i++)
      if((addr != tcam_TAG[i]) && ((cache->calcTag(tcam_TAG[i])) == (cache->calcTag(addr))) && (tcam_PB[i][this->getCPUId()] == true) ){ // old_addr is in tcam
	// std::cout << this->getCPUId()  << " , "<< (addr) << " , " << tcam_TAG[i]<<" , "<< tcam_PB[i][this->getCPUId()] << " , "<< i << std::endl;	
#ifdef debug	
	//checkTCAM();
	tcam_PB[i][this->getCPUId()] = false; // WriteBack (in cache) invoked by ReadShared
	//std::cout << " WriteBack (in cache) invoked by ReadShared" << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(cache->calcTag(addr)) << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(addr) << std::endl;
	// std::cout << std::bitset<sizeof(addr)*8>(tcam_TAG[i]) << std::endl;
	//std::cout << (addr) << " , " << tcam_TAG[i]<<" , "<< tcam_PB[i][this->getCPUId()] << " , "<< i << std::endl;	
	//checkTCAM();
#else
	tcam_PB[i][this->getCPUId()] = false; // WriteBack (in cache) invoked by ReadShared	
#endif
      }
  }

  
  // LRU prepare
  for(int i=0; i<NUM_TCAM_Line; i++){
    if((tcam_PB[i][0] | tcam_PB[i][1] | tcam_PB[i][2] | tcam_PB[i][3]) != false){ // no-empty, so LRU-Ctr++
      tcam_LRU_ctr[i]=tcam_LRU_ctr[i]+1;
    }
  }

  int flag=0;
  for(int i=0; i<NUM_TCAM_Line; i++){
    if(tcam_TAG[i] == addr){ // addr is in tcam
      tcam_PB[i][this->getCPUId()] = true;// Load (ReadShared)
      flag = 1;

      tcam_LRU_ctr[i]=0;
    }
  }
  for(int i=0; i<NUM_TCAM_Line; i++){ // addr is NOT in tcam
    if( (flag==0) && ((tcam_PB[i][0] | tcam_PB[i][1] | tcam_PB[i][2] | tcam_PB[i][3]) == false )){ // tcam has empty entry
      tcam_PB[i][this->getCPUId()] = true;
      tcam_TAG[i]                  = addr;
      flag=1;

      tcam_LRU_ctr[i]=0;

    }
  }

  if(flag==0){ // tcam has NO empty entry
    // LRU replacement
    uint32_t max     = 0;
    int      idx_max = 0;
    for(int i=0; i<NUM_TCAM_Line; i++){
      if(max <= tcam_LRU_ctr[i]){
	max = tcam_LRU_ctr[i];
	idx_max = i;
      }
    }
    tcam_PB[idx_max][this->getCPUId()] = true;
    tcam_TAG[idx_max]                  = addr;
    // LRU update
    tcam_LRU_ctr[idx_max]   =0;
    flag=1;  
  }
}

////******************


MOESI_SMPCache::RemoteReadService MOESI_SMPCache::readRemoteAction(uint32_t addr){//change cache state in this function


#ifdef filter
  //1. check the tag in tcam
  int flag=0;  // no tag in tcam
  int tcam_index=0;
  for(int i=0; i<NUM_TCAM_Line; i++){
    if(tcam_TAG[i]==addr){
      flag = 1;
      tcam_index = i;
      break;
    }
  } 
#endif

  std::vector<SMPCache * >::iterator cacheIter;
  std::vector<SMPCache * >::iterator lastCacheIter;
  
  for(cacheIter = this->getCacheVector()->begin(), lastCacheIter = this->getCacheVector()->end(); cacheIter != lastCacheIter; cacheIter++){
    MOESI_SMPCache *otherCache = (MOESI_SMPCache*)*cacheIter; 

    if(otherCache->getCPUId() == this->getCPUId()){
      continue;
    }
    
    //******************************
    //filter : filtering
    //******************************
#ifdef filter
    if(tcam_PB[tcam_index][otherCache->getCPUId()]==0 && flag==1){
      continue;
    }
#endif
    //******************************

       
    MOESI_SMPCacheState* otherState;
    otherState= (MOESI_SMPCacheState *)otherCache->cache->findLine(addr);
    if(otherState){
      if(otherState->getState() == MOESI_MODIFIED){//change state to shared and provide data.

        otherState->changeStateTo(MOESI_OWNED);
        return MOESI_SMPCache::RemoteReadService(false,true);

      }else if(otherState->getState() == MOESI_EXCLUSIVE){//change state to shared and provide data.


        otherState->changeStateTo(MOESI_OWNED); 
        return MOESI_SMPCache::RemoteReadService(false,true);//

      }else if(otherState->getState() == MOESI_SHARED){  //doesn't matter except that someone's got it//change state to shared and provide data.

        return MOESI_SMPCache::RemoteReadService(true,true);
      }else if(otherState->getState() == MOESI_OWNED){  //doesn't matter except that someone's got it//change state to shared and provide data.

        return MOESI_SMPCache::RemoteReadService(true,true);

      }else if(otherState->getState() == MOESI_INVALID){ //doesn't matter at all. doesn't change anything

      }
    }/*Else: Tag didn't match in remote caches. Nothing to do for this cache*/
    /****************************/
    EmptyLookUp++; // invalid in cache + didnot match

    /****************************/


  }// end forloop for 4 cores//done with other caches

  //This happens if everyone was MESI_INVALID
  // because inside forloop, we have "return"
  // if all returns fails, it means: all cache are MOESI_I
  /*If all other caches were MOESI_INVALID*/
  return MOESI_SMPCache::RemoteReadService(false,false);

}




void MOESI_SMPCache::readLine(uint32_t rdPC, uint32_t addr){
  MOESI_SMPCacheState *st = (MOESI_SMPCacheState *)cache->findLine(addr);    //st = state


  if(!st || (st && !(st->isValid())) ){//Read Miss -- i need to look in other's caches for this data
    numReadMisses++;
   

    //Query the other caches and get a remote read service object.
    MOESI_SMPCache::RemoteReadService rrs = readRemoteAction(addr);// find cache line in other cache, and change state.
    numReadRequestsSent++;
    
    MOESIState_t newMoesiState = MOESI_INVALID;

    if(rrs.providedData){
   
      numReadMissesServicedByOthers++;

      if(rrs.isShared){
 
	numReadMissesServicedByShared++;
         
      }else{ 
      
	numReadMissesServicedByModified++;
      } 

      newMoesiState = MOESI_SHARED;

    }else{

      newMoesiState = MOESI_EXCLUSIVE;

    }

 
    if(st){  // tag !=0(No tag) --> full cache --> evict(WriteBack) when load
      numReadOnInvalidMisses++;

      MOESI_SMPCache::filterUpdate_Load(addr,1);
      
    } else{ // tag ==0

      MOESI_SMPCache::filterUpdate_Load(addr,0);
    }

    
    //Fill the line
    fillLine(addr,newMoesiState); 

    //****************************** TODO
#ifdef debug
    MOESI_SMPCache::checkMOESI(addr);
    checkTCAM();
#endif
    //********************************

    
      
  }else{ //Read Hit
    
    //****************************** TODO
#ifdef debug
    MOESI_SMPCache::checkMOESI(addr);
    checkTCAM();
#endif
    //********************************
    
    numReadHits++;

    
    //****************************** TODO
    //filter : updating when hit
    for(int i=0; i<NUM_TCAM_Line; i++){
      if(tcam_TAG[i]==addr){ // addr is in tcam
	tcam_PB[i][this->getCPUId()]   = true;
      }
    }
    //*******************************
    
    return; 

  }
}


MOESI_SMPCache::InvalidateReply MOESI_SMPCache::writeRemoteAction(uint32_t addr){


#ifdef filter
  //1. check the tag in tcam
  int flag=0;  // no tag in tcam
  int tcam_index=0;
  for(int i=0; i<NUM_TCAM_Line; i++){
    if(tcam_TAG[i]==addr){
      flag = 1;
      tcam_index = i;
      break;
    }
  } 
#endif

  
  bool empty = true;
  std::vector<SMPCache * >::iterator cacheIter;
  std::vector<SMPCache * >::iterator lastCacheIter;
  for(cacheIter = this->getCacheVector()->begin(), lastCacheIter = this->getCacheVector()->end(); cacheIter != lastCacheIter; cacheIter++){
    
    MOESI_SMPCache *otherCache = (MOESI_SMPCache*)*cacheIter; 
    if(otherCache->getCPUId() == this->getCPUId()){
      continue;
    }

    
    //******************************
    //filter : filtering
    //******************************
#ifdef filter
    if(tcam_PB[tcam_index][otherCache->getCPUId()]==0 && flag==1){
      continue;
    }
#endif
    //******************************
      
    
    //Get the line from the current other cache 
    MOESI_SMPCacheState* otherState;
    otherState= (MOESI_SMPCacheState *)otherCache->cache->findLine(addr);
    

    //if it was actually in the other cache:
    if(otherState && otherState->isValid()){
      /*Invalidate the line, cause we're writing*/
      //otherState->invalidate();
      otherState->changeStateTo(MOESI_INVALID);
      empty = false;
    }

    //******************************
    else{
      EmptyLookUp++;
    }
    //******************************
  
  }//done with other caches

  //Empty=true indicates that no other cache 
  //had the line or there were no other caches
  //
  //This data in this object is not used as is, 
  //but it might be useful if you plan to extend 
  //this simulator, so i left it in.
  return MOESI_SMPCache::InvalidateReply(empty);
}



void MOESI_SMPCache::writeLine(uint32_t wrPC, uint32_t addr){

  MOESI_SMPCacheState * st = (MOESI_SMPCacheState *)cache->findLine(addr);    
  
  if(!st || (st && !(st->isValid())) ){ //Write Miss
    
    numWriteMisses++;


    writeRemoteAction(addr);
    
    if(st){ // tag !=0 --> full cache --> evict(WriteBack)
      numWriteOnInvalidMisses++;
      //******************************
      //filter : updating when WB
      MOESI_SMPCache::filterUpdate_Store(addr, 1);
      // ******************************
    } else{ // tag ==0
      //******************************
      //filter : updating when miss
      MOESI_SMPCache::filterUpdate_Store(addr, 0);
      // ******************************
    }


    numInvalidatesSent++;

    //Fill the line with the new write
    fillLine(addr,MOESI_MODIFIED);

    
    //****************************** TODO
#ifdef debug
    MOESI_SMPCache::checkMOESI(addr);
    checkTCAM();
#endif
    //********************************

    return;

  }else if(st->getState() == MOESI_SHARED ||
           st->getState() == MOESI_EXCLUSIVE ||
           st->getState() == MOESI_OWNED 
           ){ //Coherence Miss
    
    numWriteMisses++;
    numWriteOnSharedMisses++;


    writeRemoteAction(addr); 
    
    numInvalidatesSent++;

    st->changeStateTo(MOESI_MODIFIED);

    //****************************** TODO
    //filter : updating when hit
    for(int i=0; i<NUM_TCAM_Line; i++){
      if(tcam_TAG[i]==addr){ // addr is in tcam
	for(int j=0; j<4; j++){
	  tcam_PB[i][j]   = false;
	}
	tcam_PB[i][this->getCPUId()]   = true;
      }
    }
    //*******************************    


    //****************************** TODO
#ifdef debug
    MOESI_SMPCache::checkMOESI(addr);
    checkTCAM();
#endif
    //********************************

    
    return;

  }else{ //Write Hit


    //****************************** TODO
#ifdef debug
    MOESI_SMPCache::checkMOESI(addr);
    checkTCAM();
#endif
    //********************************
    
    numWriteHits++;


    return;

  }

}

MOESI_SMPCache::~MOESI_SMPCache(){

}

char *MOESI_SMPCache::Identify(){
  return (char *)"MOESI Cache Coherence";
}


extern "C" SMPCache *Create(int num, std::vector<SMPCache*> *cvec, int csize, int casso, int bs, int addrble, const char *repl, bool skw){

  return new MOESI_SMPCache(num,cvec,csize,casso,bs,addrble,repl,skw);

}
