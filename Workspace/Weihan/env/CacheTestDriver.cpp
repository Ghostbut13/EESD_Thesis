#include "MultiCacheSim.h"

#include <fstream>
#include <stdlib.h>
#include <ctime>
#include <iostream>
#include <dlfcn.h>
#include <stdio.h>

#define NUM_CACHES 4

std::vector<MultiCacheSim *>mcs;

unsigned long Testaddr[8] = {4000,100,3000,2000,200,800,4000,3000};
int idx=0;

unsigned long type_array[68]={0};
unsigned long addr_array[68]={0};



void *concurrent_accesses(void*np){
  unsigned long tid = *((unsigned long*)(np));
  unsigned long addr = Testaddr[idx]; //rand() % 32767; //32767/8/64=64 sets; 64*8=512 cache lines
  for(int i = 0; i < 1 ; i++){   // simple test
    unsigned long pc = rand() % 0xdeadbeff + 0xdeadbeef; // dont care 
    //unsigned long addr = rand() % 32767; //32767/8/64=64 sets; 64*8=512 cache lines
    unsigned long type = (rand()) % 2;//(tid*rand()) % 2; //load or store
    //unsigned long addr = addr_array[idx++]; //32767/8/64=64 sets; 64*8=512 cache lines
    //unsigned long type = type_array[idx++]; //load or store

    
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
    //    std::cout << type << " , " << addr << std::endl;
  }
  return nullptr;
}


int main(int argc, char** argv){
  srand(666);

  fprintf(stderr,"=================================\n");
  pthread_t tasks[NUM_CACHES];   //create thread

  //char *ct = strtok(argv[1],",");  // now the argv[1] is moesi.so -- protocol // and no gdb
  
  char *ct = strtok("moesi.so",","); // when using gbd 
    
  while(ct != NULL){
    void *chand = dlopen( ct, RTLD_LAZY | RTLD_LOCAL );
    if( chand == NULL ){
      //printf("Couldn't Load %s\n", argv[1]);
      printf("dlerror: %s\n", dlerror());
      exit(1);
    }

    CacheFactory cfac = (CacheFactory)dlsym(chand, "Create"); // coreect
    if( cfac == NULL ){
      printf("Couldn't get the Create function\n");
      printf("dlerror: %s\n", dlerror());
      exit(1);
    }
    
    MultiCacheSim *c = new MultiCacheSim(stdout, 32767, 8, 64, cfac); // cache organizion
    c->createNewCache();//CPU 1
    c->createNewCache();//CPU 2
    c->createNewCache();//CPU 3
    c->createNewCache();//CPU 4
    mcs.push_back(c);

    ct = strtok(NULL,",");
  } // cache initialization and instances


  // **************** read data from file

  std::ifstream inputFile("/home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified/Tests/cacheCo/type"); 

    if (!inputFile.is_open()) {
        std::cerr << "aaa" << std::endl;
        return 1;
    }

    unsigned long line;
    int n =0;
   
    while (inputFile >> line) {
      type_array[n++] = line;
    }
    inputFile.close(); //


    std::ifstream inputFile3("/home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified/Tests/cacheCo/addr"); 

    if (!inputFile3.is_open()) {
        std::cerr << "aaa" << std::endl;
        return 1;
    }

    unsigned long line3;
    int m =0;
    while (inputFile3 >> line3) {
      addr_array[m++] = line3;
    }
    
    inputFile3.close(); // 

  //**************************
  
  for(int round=0; round < 8; round++){ //round < 64 or 1
    for(int i = 0; i < NUM_CACHES; i++){
    gdb_b:
      pthread_create(&(tasks[i]), NULL, concurrent_accesses, (void*)(new long int(i)));
    }
  
    for(int i = 0; i < NUM_CACHES; i++){
      pthread_join(tasks[i], NULL);
    }
    idx++;
  }



  
  std::vector<MultiCacheSim *>::iterator i,e;
  for(i = mcs.begin(), e = mcs.end(); i != e; i++){ 
    
    fprintf(stderr,"%s \n",(*i)->Identify());    //calling member function in *i. *i is Multicachesim's object 
    fprintf(stderr,"--------------------------------\n");
    //(*i)->dumpStatsForAllCaches(0,"noPIN.log");
    fprintf(stderr,"********************************\n");
  }
  
}


