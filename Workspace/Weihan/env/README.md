1. the make -f Makefile contains the g++ command for **no-pin-tools** simulation

2. ./runMESI_nopin.sh can run Makefile to get the .o and .so and result of MESI

3. the make -f makefile contains the g++ command for **pin-tools** simulation

4. ./runMESI_pin.sh can run makefile to get of  the .o and .so in ./obj-intel64. mcs.o is driver

5. **Attention**: the PIN_ROOT in ./runMESI_pin.sh should be set by you. That is the location of pintools.

5. **Attention**: MESI has no filter; MSI has simple SR filter but it has some small warnings. Those warnings will be error when make -f makefile becasue compile in pintools is strong WERROR

6. if ./runMESI_pin.sh works well, go to the ocation of pintools,and run :        
   ./pin -mt -t /PATH_OF_THE_obj-intel64/mcs.so -protos /PATH_OF_THE_obj-intel64/MESI_SMPCache.so -csize 32768 -bsize 64 -assoc 2 -numcaches 2  -- /bin/clear
   
7. Now it works : should dynamically link the global symbol, rather than local one.
   
   how : in source/include/pin/pintool.ver, in "global" tag, add new line "Create"
   or see the my pintool_file : it has pintool.ver we need
