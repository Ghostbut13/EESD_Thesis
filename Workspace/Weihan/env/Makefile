LIBS:=-ldl -lpthread

SIM_HEADERS:=
SIM_SOURCES:= CacheTestDriver.cpp MultiCacheSim.cpp SMPCache.cpp

MOESI_SOURCES:= MOESI_SMPCache.cpp SMPCache.cpp CacheCore.cpp Snippets.cpp nanassert.cpp
SIM_DEPENDENCIES:=$(SIM_SOURCES:.cpp=.o)

MOESI_DEPENDENCIES:=$(MOESI_SOURCES:.cpp=.o)


SIM:=simulator
MSI:=msi
MESI:=mesi
MOESI:=moesi


all: $(MOESI)

$(SIM): $(SIM_DEPENDENCIES) $(SIM_HEADERS)
	g++ -Wl,-rpath=$(CURDIR) -g -o $@ $(SIM_DEPENDENCIES) $(LIBS)


$(MOESI): $(MOESI_DEPENDENCIES)
	g++ -Wl,-rpath=$(CURDIR) -fPIC -shared -g -o $@.so $(MOESI_DEPENDENCIES)
%.o: %.cpp
	g++ -fPIC -g -c -D filter  -o $@ $<

run: $(SIM)
	./$(SIM) $(MOESI).so


clean:
	touch $(SIM) hello.o hello.so
	rm $(SIM) *.o *.so



