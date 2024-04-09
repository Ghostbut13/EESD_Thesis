#!/bin/bash

#------------

WORK=work
TOP=I2C_master_tb
## relative path of here(Work)
PKG=./pkg
SRC=./src
SIM=./testbench
SCR=./scr
RESULT=./result

#-----------
vsim -view i2c=$RESULT/dump/$TOP.wlf -do $SCR/i2c.do 
