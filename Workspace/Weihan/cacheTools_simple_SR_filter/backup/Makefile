LIBS:=-ldl -lpthread 



SIM_SOURCES:= CacheTestDriver.cpp MultiCacheSim.cpp SMPCache.cpp
#SIM_SOURCES:= MultiCacheSim_PinDriver.cpp MultiCacheSim.cpp SMPCache.cpp


MSI_SOURCES:= MSI_SMPCache.cpp SMPCache.cpp CacheCore.cpp Snippets.cpp nanassert.cpp
MESI_SOURCES:= MESI_SMPCache.cpp SMPCache.cpp CacheCore.cpp Snippets.cpp nanassert.cpp

SIM_DEPENDENCIES:=$(SIM_SOURCES:.cpp=.o)

MSI_DEPENDENCIES:=$(MSI_SOURCES:.cpp=.o)

MESI_DEPENDENCIES:=$(MESI_SOURCES:.cpp=.o)

SIM:=simulator
MSI:=msi
MESI:=mesi




#INCLUDEDIR = /home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified

# OBJDIR = /home/weihan/Workplace/masterThesis/MultiCacheSim-master-modified 

# TARGETS = msi.so mesi.so

# CXXFLAGS += -I. -g -O0 -Wno-deprecated     #-I$(INCLUDERDIR)

# pinall: $(TARGETS)

# %.so: %.cpp
# 	$(CXX) -fPIC -shared $(CXXFLAGS) $(PIN_CXXFLAGS) -o $@ $< SMPCache.o Snippets.o nanassert.o

BLDTYPE=PIN



# header about pintool
EXTRA = /home/weihan/Workplace/masterThesis/pintool/pin-3.30-gcc-linux/extras
TOO  = /home/weihan/Workplace/masterThesis/pintool/pin-3.30-gcc-linux/source/




all: $(SIM) $(MSI) $(MESI)

$(SIM): $(SIM_DEPENDENCIES) $(SIM_HEADERS)
	g++ -Wl,-rpath=$(CURDIR) -g -o $@ $(SIM_DEPENDENCIES) $(LIBS) 

$(MSI): $(MSI_DEPENDENCIES)
	g++ -Wl,-rpath=$(CURDIR) -fPIC -shared -g -o $@.so $(MSI_DEPENDENCIES) 

$(MESI): $(MESI_DEPENDENCIES)
	g++ -Wl,-rpath=$(CURDIR) -fPIC -shared -g -o $@.so $(MESI_DEPENDENCIES) 

%.o: %.cpp
	g++ -fPIC -g -c -o $@ $< #-I$(TOO)/include/pin/ -I$(EXTRA)/xed-intel64/include/xed -I$(EXTRA)/crt/include/ -I$(EXTRA)/crt/include/kernel/uapi/  -I$(EXTRA)/components/include/ -I$(TOO)/include/pin/gen/




run: $(SIM)
#	./$(SIM) $(MSI).so > sim.log
	./$(SIM) $(MSI).so

clean:
	rm $(SIM) *.o *.so

one:
	clear
	make clean
	make all
	make run
