#!/bin/bash

##vsim -view dcd=work.test_decoder.wlf -do test.do 
vsim -view HN_wave=work.HNController.wlf -do signalShow.do 
