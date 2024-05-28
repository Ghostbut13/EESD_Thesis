class dut_driver extends uvm_agent; 
    `uvm_component_utils(dut_driver)

    localparam int MAX_LCRDT = 16;

    virtual interface clk_rst_interface clk_rst_if; 
        
    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   req_noc2hn_if; 
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  rsp_noc2hn_if; 
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      dat_noc2hn_if; 

    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   req_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  rsp_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      dat_hn2noc_if; 
    virtual interface chi_channel_inf # (.DATA_T(snoop_flit_t))     snp_hn2noc_if; 

    uvm_get_port #(req_trans) req_noc2hn_port_i; 
    uvm_get_port #(rsp_trans) rsp_noc2hn_port_i; 
    uvm_get_port #(dat_trans) dat_noc2hn_port_i; 

    uvm_put_port #(req_trans) req_hn2noc_port_o; 
    uvm_put_port #(rsp_trans) rsp_hn2noc_port_o; 
    uvm_put_port #(dat_trans) dat_hn2noc_port_o; 
    uvm_put_port #(snp_trans) snp_hn2noc_port_o; 

    req_trans req_from_noc; 
    rsp_trans rsp_from_noc; 
    dat_trans dat_from_noc;

    req_trans req_from_hn; 
    rsp_trans rsp_from_hn; 
    dat_trans dat_from_hn; 
    snp_trans snp_from_hn; 

    // ----- credit counters, noc side
    int crdts_req = 0; 
    int crdts_rsp = 0;
    int crdts_dat = 0;

    semaphore sema_crdts_req = new(1);
    semaphore sema_crdts_rsp = new(1);
    semaphore sema_crdts_dat = new(1);

    function new (string name, uvm_component parent);
        super.new(name,parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        req_noc2hn_port_i = new("req_noc2hn_port_i", this);
        rsp_noc2hn_port_i = new("rsp_noc2hn_port_i", this);
        dat_noc2hn_port_i = new("dat_noc2hn_port_i", this);
        req_hn2noc_port_o = new("req_hn2noc_port_o", this);
        rsp_hn2noc_port_o = new("rsp_hn2noc_port_o", this);
        dat_hn2noc_port_o = new("dat_hn2noc_port_o", this);
        snp_hn2noc_port_o = new("snp_hn2noc_port_o", this);

        clk_rst_if      = llc_hn_sim_pkg::global_clk_rst_if;  
        req_noc2hn_if  = llc_hn_sim_pkg::global_req_noc2hn_if; 
        rsp_noc2hn_if  = llc_hn_sim_pkg::global_rsp_noc2hn_if; 
        dat_noc2hn_if  = llc_hn_sim_pkg::global_dat_noc2hn_if; 
        req_hn2noc_if  = llc_hn_sim_pkg::global_req_hn2noc_if;
        rsp_hn2noc_if  = llc_hn_sim_pkg::global_rsp_hn2noc_if; 
        dat_hn2noc_if  = llc_hn_sim_pkg::global_dat_hn2noc_if; 
        snp_hn2noc_if  = llc_hn_sim_pkg::global_snp_hn2noc_if; 

        req_from_noc = new();
        rsp_from_noc = new();  
        dat_from_noc = new();  
        req_from_hn  = new(); 
        rsp_from_hn  = new(); 
        dat_from_hn  = new(); 
        snp_from_hn  = new(); 
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        fork 
            update_crdt_cnt_req;
            update_crdt_cnt_rsp;
            update_crdt_cnt_dat;
            get_req_from_noc; 
            get_rsp_from_noc; 
            get_dat_from_noc;
            get_req_from_hn; 
            get_rsp_from_hn; 
            get_dat_from_hn; 
            get_snp_from_hn; 
        join 
    endtask: run_phase

    //====================== link credit update =============================

    task update_crdt_cnt_req; 
        //@(posedge clk_rst_if.arst_n);
        forever begin 
            @(posedge clk_rst_if.clk); 
            if (req_noc2hn_if.tx.lcrd_v && crdts_req<MAX_LCRDT) begin 
                // increase credits at posedge clk (here)
                // reduce   credits at negedge clk (at get_req_from_noc)
                sema_crdts_req.get(); 
                    crdts_req++;  
                sema_crdts_req.put(); 
            end 
        end
    endtask: update_crdt_cnt_req

    task update_crdt_cnt_rsp; 
        @(posedge clk_rst_if.arst_n);
        forever begin 
            @(posedge clk_rst_if.clk); 
            if (rsp_noc2hn_if.tx.lcrd_v && crdts_rsp<MAX_LCRDT) begin 
                // increase credits at posedge clk (here)
                // reduce   credits at negedge clk (at get_rsp_from_noc)
                sema_crdts_rsp.get(); 
                    crdts_rsp++;  
                sema_crdts_rsp.put(); 
            end 
        end
    endtask: update_crdt_cnt_rsp

    task update_crdt_cnt_dat; 
        @(posedge clk_rst_if.arst_n);
        forever begin 
            @(posedge clk_rst_if.clk); 
            if (dat_noc2hn_if.tx.lcrd_v && crdts_dat<MAX_LCRDT) begin 
                // increase credits at posedge clk (here)
                // reduce   credits at negedge clk (at get_dat_from_noc)
                sema_crdts_dat.get(); 
                    crdts_dat++;  
                sema_crdts_dat.put(); 
            end 
        end
    endtask: update_crdt_cnt_dat
        

     //====================== handle NoC flits =============================

    task get_req_from_noc; 
        req_noc2hn_if.tx.flit_v = 0; 
        @(posedge clk_rst_if.arst_n); 
        @(posedge clk_rst_if.clk); 
        forever begin 
            if (req_noc2hn_port_i.try_get(req_from_noc)) begin // 1- wait for a new req from NoC
                `uvm_info(get_type_name(), {": REQ From NoC Received: ", req_from_noc.convert2string()},500);
                `uvm_info(get_type_name(), $psprintf(": Current Crdt Count: %d",  crdts_req),500);
                wait(crdts_req>0); // 2- wait for link credit from llc 
                @(negedge clk_rst_if.clk); 
                `uvm_info(get_type_name(), {": Sending REQ NoC2LLC: ", req_from_noc.convert2string()},500);
                req_from_noc.offload_flit(req_noc2hn_if.tx.flit); 
                req_noc2hn_if.tx.flit_v = 1; 
                sema_crdts_req.get(); 
                    crdts_req--; 
                sema_crdts_req.put(); 
                @(posedge clk_rst_if.clk); 
                #1 
                req_noc2hn_if.tx.flit_v = 0; 
            end else begin 
                #1; 
            end  
        end 
    endtask: get_req_from_noc

    task get_rsp_from_noc; 
        rsp_noc2hn_if.tx.flit_v = 0; 
        @(posedge clk_rst_if.arst_n); 
        @(posedge clk_rst_if.clk); 
        forever begin 
            if (rsp_noc2hn_port_i.try_get(rsp_from_noc)) begin // 1- wait for a new rsp from NoC
                `uvm_info(get_type_name(), {": RSP From NoC Received: ", rsp_from_noc.convert2string()},500);
                wait(crdts_rsp>0); // 2- wait for link credit from llc 
                @(negedge clk_rst_if.clk); 
                `uvm_info(get_type_name(), {": Sending RSP NoC2LLC: ", rsp_from_noc.convert2string()},500);
                rsp_from_noc.offload_flit(rsp_noc2hn_if.tx.flit);
                rsp_noc2hn_if.tx.flit_v = 1; 
                sema_crdts_rsp.get(); 
                    crdts_rsp--; 
                sema_crdts_rsp.put(); 
                @(posedge clk_rst_if.clk); 
                #1 
                rsp_noc2hn_if.tx.flit_v = 0; 
            end else begin 
                #1; 
            end 
        end 
    endtask: get_rsp_from_noc

    task get_dat_from_noc; 
        dat_noc2hn_if.tx.flit_v = 0; 
        @(posedge clk_rst_if.arst_n); 
        @(posedge clk_rst_if.clk); 
        forever begin 
            if (dat_noc2hn_port_i.try_get(dat_from_noc)) begin // 1- wait for a new dat from NoC
                `uvm_info(get_type_name(), {": DAT From NoC Received: ", dat_from_noc.convert2string()},500);
                wait(crdts_dat>0); // 2- wait for link credit from llc 
                @(negedge clk_rst_if.clk); 
                `uvm_info(get_type_name(), {": Sending DAT NoC2LLC: ", dat_from_noc.convert2string()},500);
                dat_from_noc.offload_flit(dat_noc2hn_if.tx.flit); 
                dat_noc2hn_if.tx.flit_v = 1; 
                sema_crdts_dat.get(); 
                    crdts_dat--; 
                sema_crdts_dat.put(); 
                @(posedge clk_rst_if.clk); 
                #1 
                dat_noc2hn_if.tx.flit_v = 0; 
            end else begin 
                #1; 
            end 
        end 
    endtask: get_dat_from_noc

     //====================== handle LLC flits =============================

    task get_req_from_hn; 
        @(posedge clk_rst_if.arst_n); 
        req_hn2noc_if.rx.lcrd_v = 1; 
        @(posedge clk_rst_if.clk); 
        forever begin             
            @(posedge clk_rst_if.clk)
            #1; 
            if (req_hn2noc_if.rx.flit_v) begin 
                req_from_hn.load_flit(req_hn2noc_if.rx.flit);
                req_hn2noc_port_o.put(req_from_hn); 
                `uvm_info(get_type_name(), {": REQ LLC2NOC: ", req_from_hn.convert2string()},500);
            end 
        end 
    endtask: get_req_from_hn

    task get_rsp_from_hn; 
        @(posedge clk_rst_if.arst_n); 
        rsp_hn2noc_if.rx.lcrd_v = 1;
        @(posedge clk_rst_if.clk); 
        forever begin 
            @(posedge clk_rst_if.clk)
            #1; 
            if (rsp_hn2noc_if.rx.flit_v) begin 
                rsp_from_hn.load_flit(rsp_hn2noc_if.rx.flit);
                rsp_hn2noc_port_o.put(rsp_from_hn); 
                `uvm_info(get_type_name(), {": RSP LLC2NOC: ", rsp_from_hn.convert2string()},500);
            end
        end 
    endtask: get_rsp_from_hn

    task get_dat_from_hn; 
        @(posedge clk_rst_if.arst_n); 
        dat_hn2noc_if.rx.lcrd_v = 1;
        @(posedge clk_rst_if.clk); 
        forever begin              
            @(posedge clk_rst_if.clk)
            #1; 
            if (dat_hn2noc_if.rx.flit_v) begin 
                dat_from_hn.load_flit(dat_hn2noc_if.rx.flit);
                dat_hn2noc_port_o.put(dat_from_hn); 
                `uvm_info(get_type_name(), {": DAT LLC2NOC: ", dat_from_hn.convert2string()},500);
            end
        end 
    endtask: get_dat_from_hn

    task get_snp_from_hn; 
        @(posedge clk_rst_if.arst_n); 
        snp_hn2noc_if.rx.lcrd_v = 1;
        @(posedge clk_rst_if.clk); 
        forever begin 
            @(posedge clk_rst_if.clk)
            #1; 
            if (snp_hn2noc_if.rx.flit_v) begin 
                snp_from_hn.load_flit(snp_hn2noc_if.rx.flit);
                snp_hn2noc_port_o.put(snp_from_hn); 
                `uvm_info(get_type_name(), {": SNP LLC2NOC: ", snp_from_hn.convert2string()},500);
            end
        end 
    endtask: get_snp_from_hn


endclass: dut_driver
