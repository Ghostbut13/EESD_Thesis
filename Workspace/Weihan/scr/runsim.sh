#!/bin/bash

#------------
touch e.log
rm *.log

touch e.wlf
rm *.wlf
#------------

WORK=work
TOP=I2C_master_tb
## relative path of here(Work)
PKG=./pkg
SRC=./src
SIM=./testbench
SCR=./scr
RESULT=./result

#------------
vdel -all -lib $WORK
vlib $WORK 
vcom $PKG/config_state_package.vhdl $PKG/i2c_type_package.vhdl $SRC/ADC_Configuration_Flow_Controller.vhdl $SRC/I2C_Interface.vhdl $SIM/I2C_master_tb.vhdl

vsim -c $WORK.$TOP \
     -l $RESULT/log/$TOP.log \
     -L $WORK \
     -voptargs=+acc \
     -wlf $RESULT/dump/$TOP.wlf \
     -do $SCR/i2c.do \
     -do "exit"


#-----------
# vsim -view i2c=$TOP.wlf -do $SCR/i2c.do 
