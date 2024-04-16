LIBS:=-ldl -lpthread 

# no pintool
SIM_SOURCES:= CacheTestDriver.cpp MultiCacheSim.cpp SMPCache.cpp
MSI_SOURCES:= MSI_SMPCache.cpp SMPCache.cpp CacheCore.cpp Snippets.cpp nanassert.cpp
MESI_SOURCES:= MESI_SMPCache.cpp SMPCache.cpp CacheCore.cpp Snippets.cpp nanassert.cpp

SIM_DEPENDENCIES:=$(SIM_SOURCES:.cpp=.o)

MSI_DEPENDENCIES:=$(MSI_SOURCES:.cpp=.o)

MESI_DEPENDENCIES:=$(MESI_SOURCES:.cpp=.o)

SIM:=simulator
MSI:=msi
MESI:=mesi




all: $(SIM) $(MSI) $(MESI)

$(SIM): $(SIM_DEPENDENCIES) $(SIM_HEADERS)
	g++ -Wl,-rpath=$(CURDIR) -g -o $@ $(SIM_DEPENDENCIES) $(LIBS) 

$(MSI): $(MSI_DEPENDENCIES)
	g++ -Wl,-rpath=$(CURDIR) -fPIC -shared -g -o $@.so $(MSI_DEPENDENCIES) $(LDFLAGS)

$(MESI): $(MESI_DEPENDENCIES)
	g++ -Wl,-rpath=$(CURDIR) -fPIC -shared -g -o $@.so $(MESI_DEPENDENCIES) $(LDFLAGS) 

%.o: %.cpp
	g++ -fPIC -g -c -o $@ $< 




## now we test the MESI (without filter)
run: $(SIM)
	./$(SIM) $(MESI).so


clean:
	touch $(SIM) hello.o hello.so
	rm $(SIM) *.o *.so



