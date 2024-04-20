#include "MultiCacheSim.h"
#include <stdlib.h>
#include <ctime>
#include <dlfcn.h>
#include <stdio.h>

#define NUM_CACHES 4

std::vector<MultiCacheSim *>mcs;

void *concurrent_accesses(void*np){
  unsigned long tid = *((unsigned long*)(np));
  for(int i = 0; i < 300000    ; i++){//300000
    unsigned long addr = rand() % 32767; //32767/8/32=128 sets; all lines = 128*8=1024
    unsigned long pc = rand() % 0xdeadbeff + 0xdeadbeef; 
    unsigned long type = rand() % 2;//load or store
    if(type == 0){
      std::vector<MultiCacheSim *>::iterator i,e;
      for(i = mcs.begin(), e = mcs.end(); i != e; i++){ 
        (*i)->readLine(tid, pc, addr); // "readLine"in MultiCacheSim.cpp, where calling the samename method in MSI(MESI)_SMPCache.cpp
      }
    }else{
      std::vector<MultiCacheSim *>::iterator i,e;
      for(i = mcs.begin(), e = mcs.end(); i != e; i++){ 
        (*i)->writeLine(tid, pc, addr);
      }
    }
  }
}


int main(int argc, char** argv){
  srand(666);

  pthread_t tasks[NUM_CACHES];   //create thread

  char *ct = strtok(argv[1],",");  // now the argv[1] is msi.so -- protocol

 
  while(ct != NULL){
    void *chand = dlopen( ct, RTLD_LAZY | RTLD_LOCAL );
    if( chand == NULL ){
      printf("Couldn't Load %s\n", argv[1]);
      printf("dlerror: %s\n", dlerror());
      exit(1);
    }

    CacheFactory cfac = (CacheFactory)dlsym(chand, "Create"); // coreect
    if( cfac == NULL ){
      printf("Couldn't get the Create function\n");
      printf("dlerror: %s\n", dlerror());
      exit(1);
    }
  
    MultiCacheSim *c = new MultiCacheSim(stdout, 32767, 8, 32, cfac); // cache organizion
    c->createNewCache();//CPU 1
    c->createNewCache();//CPU 2
    c->createNewCache();//CPU 3
    c->createNewCache();//CPU 4
    mcs.push_back(c);

    ct = strtok(NULL,",");
  } // cache initialization and instances

  for(int i = 0; i < NUM_CACHES; i++){
    pthread_create(&(tasks[i]), NULL, concurrent_accesses, (void*)(new int(i)));
  }
  
  for(int i = 0; i < NUM_CACHES; i++){
    pthread_join(tasks[i], NULL);
  }

  std::vector<MultiCacheSim *>::iterator i,e;
  for(i = mcs.begin(), e = mcs.end(); i != e; i++){ 
    fprintf(stderr,"%s",(*i)->Identify());    //calling member function in *i. *i is Multicachesim's object 
    fprintf(stderr,"--------------------------------\n");
    (*i)->dumpStatsForAllCaches(0);
    fprintf(stderr,"********************************\n");
  }


  
}


