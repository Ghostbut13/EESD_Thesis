#!/bin/bash


# compile
vlib work 
vlog -mfcu -f compile.f


# dump
## work.MODULENAME_isNOT_svNAME \
## work.test_WHATEVER.log \
## -do test.do  :  /xxx/xxx/test.do 

vsim -c work.top \
     -l work.HNController.log \
     -L work \
     -voptargs=+acc \
     -wlf work.HNController.wlf \
     -do signalShow.do \
     -do "exit"


# C-C C-X : RUN it in emacs 

# Then, "vsim -view dcd=work.CCC.wlf -do DDD.do" in
# viewave.sh
