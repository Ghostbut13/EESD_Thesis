#!/bin/bash

clear

touch ./obj-intel64/hello
rm ./obj-intel64/*
#####################
echo ""
echo "delete old ones"
echo ""


#### PIN_ROOT IS THE LOCATION OF your pin



##make -f makefile PIN_ROOT=/home/weihan/Workplace/masterThesis/pintool/pin-3.30-gcc-linux  obj-intel64/MESI_SMPCache.so

make PIN_ROOT=/home/weihan/Workplace/masterThesis/pintool/pin-3.30-gcc-linux obj-intel64/MOESI_SMPCache.so

make -f makefile  PIN_ROOT=/home/weihan/Workplace/masterThesis/pintool/pin-3.30-gcc-linux  obj-intel64/mcs.so



