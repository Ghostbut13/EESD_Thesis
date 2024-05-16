#include "MOESI_SMPCache.h"
#include <iostream>                                                 
#include <bitset>  

#ifndef NUM_SR
#define NUM_SR 4
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
// uint16_t hamming_d[4][4]   =
//   {0,0,0,0,
//    0,0,0,0,
//    0,0,0,0,
//    0,0,0,0};


MOESI_SMPCache::MOESI_SMPCache(int cpuid, std::vector<SMPCache * > * cacheVector,
			       int csize, int cassoc, int cbsize, int caddressable, const char * repPol, bool cskew) : 
  SMPCache(cpuid,cacheVector){
  fprintf(stderr,"Making a MESI cache with cpuid %d\n",cpuid);
  CacheGeneric<MOESI_SMPCacheState> *c = CacheGeneric<MOESI_SMPCacheState>::create(csize, cassoc, cbsize, caddressable, repPol, cskew);
  cache = (CacheGeneric<StateGeneric<> >*)c; 

}

void MOESI_SMPCache::fillLine(uint32_t addr, uint32_t moesi_state){
  MOESI_SMPCacheState *st = (MOESI_SMPCacheState *)cache->findLine2Replace(addr); //this gets the contents of whateverline this would go into
  if(st==0){
    return;
  }
  st->setTag(cache->calcTag(addr));
  st->changeStateTo((MOESIState_t)moesi_state);
  return;
    
}


//***********no used in design; cannot delete*******************
// filter design
void MOESI_SMPCache::filterAddr(uint32_t addr, MOESI_SMPCache *otherCache){

}
//******************************


MOESI_SMPCache::RemoteReadService MOESI_SMPCache::readRemoteAction(uint32_t addr){//change cache state in this function

  std::vector<SMPCache * >::iterator cacheIter;
  std::vector<SMPCache * >::iterator lastCacheIter;
  for(cacheIter = this->getCacheVector()->begin(), lastCacheIter = this->getCacheVector()->end(); cacheIter != lastCacheIter; cacheIter++){
    MOESI_SMPCache *otherCache = (MOESI_SMPCache*)*cacheIter; 

    if(otherCache->getCPUId() == this->getCPUId()){
      continue;
    }
    
    for(int i=0; i<NUM_SR ; i++){
      //******************************
      //filter
      if(filter_initial_flag[otherCache->getCPUId()][i] == 1){ // initial
      }else{ // second
	// filtering
	if(!(filter_mask[otherCache->getCPUId()][i] == (filter_mask[otherCache->getCPUId()][i] & (filter_base[otherCache->getCPUId()][i] ^ addr ^ filter_mask[otherCache->getCPUId()][i])))){ // addr not matching

#ifdef filter
	  goto no_send_readshared;
#endif

	}
      }
    }
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
#ifdef filter
  no_send_readshared:
    continue;
#endif
  }// end forloop for 4 cores//done with other caches

  //fprintf(stderr,"Done with all caches\n");
  //This happens if everyone was MESI_INVALID
  // because inside forloop, we have "return"
  // if all returns fails, it means: all cache are MOESI_I
  /*If all other caches were MOESI_INVALID*/
  return MOESI_SMPCache::RemoteReadService(false,false);
}




void MOESI_SMPCache::readLine(uint32_t rdPC, uint32_t addr){
  MOESI_SMPCacheState *st = (MOESI_SMPCacheState *)cache->findLine(addr);    
  //fprintf(stderr,"In MESI ReadLine\n");
  if(!st || (st && !(st->isValid())) ){//Read Miss -- i need to look in other peoples' caches for this data
    numReadMisses++;
    if(st){
      numReadOnInvalidMisses++;
    }

    
    //******************************
    uint16_t min_d=0;
    uint16_t i_update = 0;
    
    //filter : updating
    for (int i=0; i<NUM_SR; i++){
      if(filter_initial_flag[this->getCPUId()][i] == 1){ // ---------has initial SR
	filter_initial_flag[this->getCPUId()][i] = 0;
	filter_mask[this->getCPUId()][i] = 0xFFFF;//3ff
	filter_base[this->getCPUId()][i] = addr;
	filter_ctr[this->getCPUId()][i]  = 1;
	i_update = i;
	break;
      }
      else{
	if(!(filter_mask[this->getCPUId()][i] == (filter_mask[this->getCPUId()][i] & (filter_base[this->getCPUId()][i] ^ addr ^ filter_mask[this->getCPUId()][i])))){ 	// addr not matching
	  // calculate the hamming distance
	  if(i==0){
	    uint16_t tmp0 = 0;
	    uint16_t tmp1 = 0;
	    tmp0 = filter_base[this->getCPUId()][i] ^ addr;
	    while(tmp0){
	      tmp0 = tmp0 & (tmp0 - 1);
	      tmp1++;
	    }
	    min_d = tmp1;	    
	  }
	  else{
	    uint16_t tmp0 = 0;
	    uint16_t tmp1 = 0;
	    tmp0 = filter_base[this->getCPUId()][i] ^ addr;
	    while(tmp0){
	      tmp0 = tmp0 & (tmp0 - 1);
	      tmp1++;
	    }
	    if(tmp1 <= min_d) {
	      min_d = tmp1;
	      i_update = i;
	    }
	  }
	}
	else{ // addr matching
	  i_update = i;
	  break;
	}
      }
    }
    //------updating
    filter_mask[this->getCPUId()][i_update] = filter_mask[this->getCPUId()][i_update] & (filter_base[this->getCPUId()][i_update] ^ addr ^ filter_mask[this->getCPUId()][i_update]);
    filter_ctr[this->getCPUId()][i_update] = filter_ctr[this->getCPUId()][i_update] +1;// counter	
    filter_base[this->getCPUId()][i_update] = addr;    

    
    // if(1){
    //   for(int i=0; i<NUM_SR ; i++){
    // 	if(filter_mask[this->getCPUId()][i] != 0){
    // 	  std::cout << "(bin)base + mask + cpuID: "<< std::bitset<16>(filter_base[this->getCPUId()][i]) << " "<< std::bitset<16>(filter_mask[this->getCPUId()][i]) << ",   " << this->getCPUId() << std::endl;
    // 	  printf("(de)base + mask + ctr + cpuID:  %d  %d   %d,  %d\n",filter_base[this->getCPUId()][i],filter_mask[this->getCPUId()][i],filter_ctr[this->getCPUId()][i],this->getCPUId());
    // 	}
    //   }
    // }
  
    //******************************



  
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
    //Fill the line
    //fprintf(stderr,"MESI ReadLine: Miss -- calling fill line\n");
    fillLine(addr,newMoesiState); 

      
  }else{ //Read Hit

    numReadHits++; 
    return; 

  }
}


MOESI_SMPCache::InvalidateReply MOESI_SMPCache::writeRemoteAction(uint32_t addr){
    
  bool empty = true;
  std::vector<SMPCache * >::iterator cacheIter;
  std::vector<SMPCache * >::iterator lastCacheIter;
  for(cacheIter = this->getCacheVector()->begin(), lastCacheIter = this->getCacheVector()->end(); cacheIter != lastCacheIter; cacheIter++){
    MOESI_SMPCache *otherCache = (MOESI_SMPCache*)*cacheIter; 
    if(otherCache->getCPUId() == this->getCPUId()){
      continue;
    }


    //******************************
    //filter
    for(int i=0; i<NUM_SR; i++){
      if(filter_initial_flag[otherCache->getCPUId()][i] == 1){ // initial
      }else{ // second
	// filtering
	if(!(filter_mask[otherCache->getCPUId()][i] == (filter_mask[otherCache->getCPUId()][i] & (filter_base[otherCache->getCPUId()][i] ^ addr ^ filter_mask[otherCache->getCPUId()][i])))){ // addr not matching

#ifdef filter
	  goto no_sent;
#endif

	}
      }
    }
    //******************************

    
    //Get the line from the current other cache 
    MOESI_SMPCacheState* otherState;
    otherState= (MOESI_SMPCacheState *)otherCache->cache->findLine(addr);

    //if it was actually in the other cache:
    if(otherState && otherState->isValid()){
      /*Invalidate the line, cause we're writing*/
      otherState->invalidate();
      //----------------------- SR hit ----
      for(int i=0; i<NUM_SR; i++){
	if((filter_base[otherCache->getCPUId()][i] | addr) == filter_mask[otherCache->getCPUId()][i]){ // SR hit
	  filter_ctr[otherCache->getCPUId()][i] = filter_ctr[otherCache->getCPUId()][i] -1;    /// SR is counting down
	  if(filter_ctr[otherCache->getCPUId()][i] ==  0){ /// if SR_ctr ==0 --> reset it
	    filter_initial_flag[otherCache->getCPUId()][i] = 1; // reset flag (or initial flag)
	  }
	}
      }
      empty = false;
    }

    //******************************
    else{
      EmptyLookUp++;
    }
    //******************************
#ifdef filter
  no_sent:
    continue;
#endif
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
  
    if(st){
      numWriteOnInvalidMisses++;
    }

    
    //******************************
    uint16_t min_d=0;
    uint16_t i_update = 0;
    
    //filter : updating
    for (int i=0; i<NUM_SR; i++){
      if(filter_initial_flag[this->getCPUId()][i] == 1){ // ---------has initial SR
	filter_initial_flag[this->getCPUId()][i] = 0;
	filter_mask[this->getCPUId()][i] = 0xFFFF;//3ff
	filter_base[this->getCPUId()][i] = addr;
	filter_ctr[this->getCPUId()][i]  = 1;
	i_update = i;
	break;
      }
      else{
	if(!(filter_mask[this->getCPUId()][i] == (filter_mask[this->getCPUId()][i] & (filter_base[this->getCPUId()][i] ^ addr ^ filter_mask[this->getCPUId()][i])))){ 	// addr not matching
	  // calculate the hamming distance
	  if(i==0){
	    uint16_t tmp0 = 0;
	    uint16_t tmp1 = 0;
	    tmp0 = filter_base[this->getCPUId()][i] ^ addr;
	    while(tmp0){
	      tmp0 = tmp0 & (tmp0 - 1);
	      tmp1++;
	    }
	    min_d = tmp1;	    
	  }
	  else{
	    uint16_t tmp0 = 0;
	    uint16_t tmp1 = 0;
	    tmp0 = filter_base[this->getCPUId()][i] ^ addr;
	    while(tmp0){
	      tmp0 = tmp0 & (tmp0 - 1);
	      tmp1++;
	    }
	    if(tmp1 <= min_d) {
	      min_d = tmp1;
	      i_update = i;
	    }
	  }
	}
	else{ // addr matching
	  i_update = i;
	  break;
	}
      }
    }
    //------updating
    filter_mask[this->getCPUId()][i_update] = filter_mask[this->getCPUId()][i_update] & (filter_base[this->getCPUId()][i_update] ^ addr ^ filter_mask[this->getCPUId()][i_update]);
    filter_ctr[this->getCPUId()][i_update] = filter_ctr[this->getCPUId()][i_update] +1;// counter	
    filter_base[this->getCPUId()][i_update] = addr;    


    // if(1){
    //   for(int i=0; i<NUM_SR ; i++){
    // 	if(filter_mask[this->getCPUId()][i] != 0){
    // 	  std::cout << "(bin)base + mask + cpuID: "<< std::bitset<16>(filter_base[this->getCPUId()][i]) << " "<< std::bitset<16>(filter_mask[this->getCPUId()][i]) << ",   " << this->getCPUId() << std::endl;
    // 	  printf("(de)base + mask + ctr + cpuID:  %d  %d   %d,  %d\n",filter_base[this->getCPUId()][i],filter_mask[this->getCPUId()][i],filter_ctr[this->getCPUId()][i],this->getCPUId());
    // 	}
    //   }
    // }

    //******************************


    
    //MOESI_SMPCache::InvalidateReply inv_ack = writeRemoteAction(addr);
    numInvalidatesSent++;

    //Fill the line with the new write
    fillLine(addr,MOESI_MODIFIED);
    return;

  }else if(st->getState() == MOESI_SHARED ||
           st->getState() == MOESI_EXCLUSIVE ||
           st->getState() == MOESI_OWNED                        ///////////todo
           ){ //Coherence Miss
    
    numWriteMisses++;
    numWriteOnSharedMisses++;


    //MOESI_SMPCache::InvalidateReply inv_ack = writeRemoteAction(addr);
    numInvalidatesSent++;

    st->changeStateTo(MOESI_MODIFIED);
    return;

  }else{ //Write Hit

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
