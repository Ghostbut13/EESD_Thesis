variable refmodel ""
variable debug ""
variable verbosity "100"

if [file exists work] {vdel -all}
vlib work

if {($argc < 1)} {
    echo "sequence name (SEQi) not specified!"
    exit; 
} else {
    if {($argc == 3) && (($2) == "refmodel") && (($3) == "debug")} {
        set refmodel 1
        set debug 1
    } elseif {($argc > 1) && (($2) == "refmodel")} {
        set refmodel 1
        set debug 0
    } else {
        set refmodel 0
        set debug 0
    }
}


echo "Sequence:"
echo $1
echo "REFMODEL:"
echo $refmodel
echo "DEBUG:"
echo $debug


if {$refmodel == 1} {

    vlog -mfcu -f compile.f +define+refmodel +define+$1
    if {$debug == 1} {
        sccom -g -DMTI_BIND_SC_MEMBER_FUNCTION verification/hnf_refmodel/refmodel_sc.cpp verification/hnf_refmodel/hnf_refmodel.cpp -std=c++11 -DDEBUGMSG_REF_MODEL --verbose
    } else {
        sccom -g -DMTI_BIND_SC_MEMBER_FUNCTION verification/hnf_refmodel/refmodel_sc.cpp verification/hnf_refmodel/hnf_refmodel.cpp -std=c++11
    }
    sccom -link
    vsim top refmodel_sc -t ns +UVM_TESTNAME=test_i + +UVM_VERBOSITY=$verbosity +UVM_TIMEOUT=5000000000  -voptargs="+acc" -onfinish stop;

} else {

    vlog -mfcu -f compile.f +define+$1
    vsim top -t ns +UVM_TESTNAME=test_i +UVM_VERBOSITY=$verbosity +UVM_TIMEOUT=5000000000  -voptargs="+acc" -onfinish stop;

}

run -all
exit;
