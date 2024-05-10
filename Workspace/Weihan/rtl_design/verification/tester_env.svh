// =============================================================================
//
//            Copyright (c) 2019 CHALMERS University of Technology
//                             All rights reserved
//
// This file contains CHALMERS proprietary and confidential information 
// and has been developed by CHALMERS within the EPI-SGA1 Project (GA 826647). 
// The permission rights for this file are governed by the EPI Grant Agreement 
// and the EPI Consortium Agreement.
//
// ===============================[ INFORMATION ]===============================
//
// Author(s)  : Bhavishya Goel and Madhavan Manivannan
// Contact(s) : goelb@chalmers.se, madhavan@chalmers.se
//
// Summary    : UVM tester environment for HN verification
// Created    : 14/10/2019
// Modified   : 29/08/2022
//
// ===============================[ DESCRIPTION ]===============================
//
// Defines all the UVM agents used in the HN verification framework and
// connects them together
//
// =============================================================================

class tester_env extends uvm_env;
    `uvm_component_utils(tester_env)

    driver drv[NUM_SIM_CORES-1:0];

   `ifdef refmodel
    monitor mon;
    predictor pred;
    comparator cmp;
    `endif

    uvm_sequencer #(l1_req) seqr[NUM_SIM_CORES-1:0];

    uvm_tlm_fifo #(l1_input) l1in_drv2l1_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(l1_output) l1out_l12drv_fifo[NUM_SIM_CORES-1:0];

    //RN <-> NoC
    uvm_tlm_fifo #(req_trans) req_rn2noc_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(rsp_trans) rsp_noc2rn_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(rsp_trans) rsp_rn2noc_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(snp_trans) snp_noc2rn_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(dat_trans) dat_noc2rn_fifo[NUM_SIM_CORES-1:0];
    uvm_tlm_fifo #(dat_trans) dat_rn2noc_fifo[NUM_SIM_CORES-1:0];

    //HN <-> NoC
    uvm_tlm_fifo #(req_trans) req_noc2hn_fifo;
    uvm_tlm_fifo #(req_trans) req_hn2noc_fifo;
    uvm_tlm_fifo #(rsp_trans) rsp_hn2noc_fifo;
    uvm_tlm_fifo #(rsp_trans) rsp_noc2hn_fifo;
    uvm_tlm_fifo #(snp_trans) snp_hn2noc_fifo;
    uvm_tlm_fifo #(dat_trans) dat_noc2hn_fifo;
    uvm_tlm_fifo #(dat_trans) dat_hn2noc_fifo;

    //SN <-> NoC
    uvm_tlm_fifo #(req_trans) req_noc2sn_fifo;
    uvm_tlm_fifo #(rsp_trans) rsp_sn2noc_fifo;
    uvm_tlm_fifo #(dat_trans) dat_noc2sn_fifo;
    uvm_tlm_fifo #(dat_trans) dat_sn2noc_fifo;

    rnf_model 		rn_model[NUM_SIM_CORES-1:0];
    dut_driver 		l2hn_driver;
    noc_ref_model 	noc_model;
    sn_model 		snmodel;

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new;

    function void build_phase(uvm_phase phase);
        for(int i=0;i<NUM_SIM_CORES;i++) begin
            drv[i]  = new($psprintf("drv_%0d", i),this, i);
            seqr[i] = new($psprintf("seqr_%0d",i),this);
        end

        l2hn_driver  = dut_driver::type_id::create("l2hn_driver",this);
        noc_model  = noc_ref_model::type_id::create("noc_model",this);
        snmodel = sn_model::type_id::create("snmodel", this);


        //HN <-> NoC FIFOs
        req_noc2hn_fifo = new("req_noc2hn_fifo",this,16);
        req_hn2noc_fifo = new("req_hn2noc_fifo",this,16);
        rsp_hn2noc_fifo = new("rsp_hn2noc_fifo",this,16*NUM_SIM_CORES);
        rsp_noc2hn_fifo = new("rsp_noc2hn_fifo",this,16);
        dat_noc2hn_fifo = new("dat_noc2hn_fifo",this,16);
        dat_hn2noc_fifo = new("dat_hn2noc_fifo",this,16);
        snp_hn2noc_fifo = new("snp_hn2noc_fifo",this,16*NUM_SIM_CORES);

        //SN <-> NoC FIFOs
        req_noc2sn_fifo = new("req_noc2sn_fifo",this,16);
        rsp_sn2noc_fifo = new("rsp_sn2noc_fifo",this,16);
        dat_noc2sn_fifo = new("dat_noc2sn_fifo",this,16);
        dat_sn2noc_fifo = new("dat_sn2noc_fifo",this,16);

        for(int i=0;i<NUM_SIM_CORES;i++) begin
            rn_model[i]  = rnf_model::type_id::create($psprintf("rn_model_%0d", i),this);
            l1in_drv2l1_fifo[i] = new($psprintf("l1in_drv2l1_fifo_%0d", i));
            l1out_l12drv_fifo[i] = new($psprintf("l1out_l12drv_fifo_%0d", i));

            //RN <-> NoC FIFOs
            req_rn2noc_fifo[i] = new($psprintf("req_rn2noc_fifo_%0d", i), this, 16);
            rsp_noc2rn_fifo[i] = new($psprintf("rsp_noc2rn_fifo_%0d", i), this, 16);
            rsp_rn2noc_fifo[i] = new($psprintf("rsp_rn2noc_fifo_%0d", i), this, 16);
            snp_noc2rn_fifo[i] = new($psprintf("snp_noc2rn_fifo_%0d", i), this, 16);
            dat_noc2rn_fifo[i] = new($psprintf("dat_noc2rn_fifo_%0d", i), this, 16);
            dat_rn2noc_fifo[i] = new($psprintf("dat_rn2noc_fifo_%0d", i), this, 16);
        end

        `ifdef refmodel
        mon  = monitor::type_id::create("mon",this);
        pred = predictor::type_id::create("pred",this);
        cmp  =  comparator::type_id::create("cmp",this);
        `endif

    endfunction
   
    function void connect_phase(uvm_phase phase);
        for(int i=0;i<NUM_SIM_CORES;i++) begin
            drv[i].seq_item_port.connect(seqr[i].seq_item_export);
        end

        //NoC2HN port connections in HN
        l2hn_driver.req_noc2hn_port_i.connect(req_noc2hn_fifo.get_export);
        l2hn_driver.rsp_noc2hn_port_i.connect(rsp_noc2hn_fifo.get_export);
        l2hn_driver.dat_noc2hn_port_i.connect(dat_noc2hn_fifo.get_export);

        //NoC2HN port connections in NoC
        noc_model.req_noc2hn_port_o.connect(req_noc2hn_fifo.put_export);
        noc_model.rsp_noc2hn_port_o.connect(rsp_noc2hn_fifo.put_export);
        noc_model.dat_noc2hn_port_o.connect(dat_noc2hn_fifo.put_export);

        //HN2NOC port connections in HN
        l2hn_driver.req_hn2noc_port_o.connect(req_hn2noc_fifo.put_export);
        l2hn_driver.rsp_hn2noc_port_o.connect(rsp_hn2noc_fifo.put_export);
        l2hn_driver.snp_hn2noc_port_o.connect(snp_hn2noc_fifo.put_export);
        l2hn_driver.dat_hn2noc_port_o.connect(dat_hn2noc_fifo.put_export);

        //HN2NOC port connections in NoC
        noc_model.req_hn2noc_port_i.connect(req_hn2noc_fifo.get_export);
        noc_model.rsp_hn2noc_port_i.connect(rsp_hn2noc_fifo.get_export);
        noc_model.dat_hn2noc_port_i.connect(dat_hn2noc_fifo.get_export);
        noc_model.snp_hn2noc_port_i.connect(snp_hn2noc_fifo.get_export);

        //NoC2SN port connections in SN
        snmodel.req_noc2sn_port_i.connect(req_noc2sn_fifo.get_export);
        snmodel.dat_noc2sn_port_i.connect(dat_noc2sn_fifo.get_export);

        //NoC2SN port connections in NoC
        noc_model.req_noc2sn_port_o.connect(req_noc2sn_fifo.put_export);
        noc_model.dat_noc2sn_port_o.connect(dat_noc2sn_fifo.put_export);
        
        //SN2NoC port connections in SN
        snmodel.rsp_sn2noc_port_o.connect(rsp_sn2noc_fifo.put_export);
        snmodel.dat_sn2noc_port_o.connect(dat_sn2noc_fifo.put_export);

        //SN2NoC port connections in NoC
        noc_model.rsp_sn2noc_port_i.connect(rsp_sn2noc_fifo.get_export);
        noc_model.dat_sn2noc_port_i.connect(dat_sn2noc_fifo.get_export);

        for(int i=0;i<NUM_SIM_CORES;i++) begin
            //L1<->driver connections
            drv[i].l1_in_port.connect(l1in_drv2l1_fifo[i].put_export);
            drv[i].l1_out_port.connect(l1out_l12drv_fifo[i].get_export);
            rn_model[i].l1_in_port.connect(l1in_drv2l1_fifo[i].get_export);
            rn_model[i].l1_out_port.connect(l1out_l12drv_fifo[i].put_export);

            //NoC2RN port connections in RN
            rn_model[i].rsp_noc2rn_port_i.connect(rsp_noc2rn_fifo[i].get_export);
            rn_model[i].snp_noc2rn_port_i.connect(snp_noc2rn_fifo[i].get_export);
            rn_model[i].dat_noc2rn_port_i.connect(dat_noc2rn_fifo[i].get_export);

            //NoC2RN port connections in NoC
            noc_model.rsp_noc2rn_port_o[i].connect(rsp_noc2rn_fifo[i].put_export);
            noc_model.snp_noc2rn_port_o[i].connect(snp_noc2rn_fifo[i].put_export);
            noc_model.dat_noc2rn_port_o[i].connect(dat_noc2rn_fifo[i].put_export);

            //RN2NoC port connections in RN
            rn_model[i].req_rn2noc_port_o.connect(req_rn2noc_fifo[i].put_export);
            rn_model[i].rsp_rn2noc_port_o.connect(rsp_rn2noc_fifo[i].put_export);
            rn_model[i].dat_rn2noc_port_o.connect(dat_rn2noc_fifo[i].put_export);

            //RN2NoC port connections in NoC
            noc_model.delay_model[i].req_rn2nocdelay_port_i.connect(req_rn2noc_fifo[i].get_export);
            noc_model.rsp_rn2noc_port_i[i].connect(rsp_rn2noc_fifo[i].get_export);
            noc_model.dat_rn2noc_port_i[i].connect(dat_rn2noc_fifo[i].get_export);
        end

        `ifdef refmodel
        mon.reqin_port.connect(pred.reqin_fifo.analysis_export);
        mon.rspin_port.connect(pred.rspin_fifo.analysis_export);
        mon.datin_port.connect(pred.datin_fifo.analysis_export);

        mon.reqout_port.connect(cmp.monreqout_fifo.analysis_export);
        mon.rspout_port.connect(cmp.monrspout_fifo.analysis_export);
        mon.snpout_port.connect(cmp.monsnpout_fifo.analysis_export);
        mon.datout_port.connect(cmp.mondatout_fifo.analysis_export);

        pred.reqout_port.connect(cmp.predreqout_fifo.analysis_export);
        pred.rspout_port.connect(cmp.predrspout_fifo.analysis_export);
        pred.snpout_port.connect(cmp.predsnpout_fifo.analysis_export);
        pred.datout_port.connect(cmp.preddatout_fifo.analysis_export);
        `endif

    endfunction : connect_phase

    `ifdef refmodel
        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info(get_type_name(), {$psprintf("Num Passed REQ compares: %d", cmp.req_cnt)},100);
            `uvm_info(get_type_name(), {$psprintf("Num Passed RSP compares: %d", cmp.rsp_cnt)},100);
            `uvm_info(get_type_name(), {$psprintf("Num Passed DAT compares: %d", cmp.dat_cnt)},100);
            `uvm_info(get_type_name(), {$psprintf("Num Passed SNP compares: %d", cmp.snp_cnt)},100);
        endfunction : report_phase 
    `endif 
    
endclass : tester_env
