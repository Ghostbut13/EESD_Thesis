class monitor extends uvm_monitor;
    `uvm_component_utils(monitor)

    uvm_analysis_port    #(req_trans) reqin_port;
    uvm_analysis_port    #(rsp_trans) rspin_port;
    uvm_analysis_port    #(dat_trans) datin_port;

    uvm_analysis_port    #(req_trans) reqout_port;
    uvm_analysis_port    #(rsp_trans) rspout_port;
    uvm_analysis_port    #(snp_trans) snpout_port;
    uvm_analysis_port    #(dat_trans) datout_port;

    virtual interface clk_rst_interface clk_rst_if;
    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   req_if_i;
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  rsp_if_i;
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      dat_if_i;

    virtual interface chi_channel_inf # (.DATA_T(request_flit_t))   req_if_o;
    virtual interface chi_channel_inf # (.DATA_T(response_flit_t))  rsp_if_o;
    virtual interface chi_channel_inf # (.DATA_T(data_flit_t))      dat_if_o;
    virtual interface chi_channel_inf # (.DATA_T(snoop_flit_t))     snp_if_o;

    function new(string name = "monitor",
                 uvm_component parent = null );
        super.new(name, parent);
    endfunction : new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        reqin_port      = new("reqin_port", this);
        rspin_port      = new("rspin_port", this);
        datin_port      = new("datin_port", this);

        reqout_port     = new("reqout_port", this);
        rspout_port     = new("rspout_port", this);
        snpout_port     = new("snpout_port", this);
        datout_port     = new("datout_port", this);

        clk_rst_if = llc_hn_sim_pkg::global_clk_rst_if;
        req_if_i = llc_hn_sim_pkg::global_req_noc2hn_if;
        rsp_if_i = llc_hn_sim_pkg::global_rsp_noc2hn_if;
        dat_if_i = llc_hn_sim_pkg::global_dat_noc2hn_if;

        req_if_o = llc_hn_sim_pkg::global_req_hn2noc_if;
        rsp_if_o = llc_hn_sim_pkg::global_rsp_hn2noc_if;
        dat_if_o = llc_hn_sim_pkg::global_dat_hn2noc_if;
        snp_if_o = llc_hn_sim_pkg::global_snp_hn2noc_if;
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        `uvm_info (get_type_name(),{"run_phase monitor"},400);
        fork
            load_reqin;
            load_rspin;
            load_datin;
            load_reqout;
            load_rspout;
            load_datout;
            load_snpout;
        join
    endtask

    task load_reqin;
        req_trans  req = new(), c_req;
        @(posedge clk_rst_if.arst_n);
        forever begin : req_loop
            @(posedge clk_rst_if.clk);
            if (req_if_i.rx.flit_v) begin
                req.load_flit(req_if_i.rx.flit);
                $cast(c_req, req.clone());
                `uvm_info (get_type_name(),{"got req", c_req.convert2string()},400);
                reqin_port.write(c_req);
            end else begin
                #1;
            end
        end : req_loop
    endtask: load_reqin

    task load_rspin;
        rsp_trans  rsp = new(), c_rsp;
        @(posedge clk_rst_if.arst_n);
        forever begin : rsp_loop
            @(posedge clk_rst_if.clk);
            if (rsp_if_i.rx.flit_v) begin
                rsp.load_flit(rsp_if_i.rx.flit);
                $cast(c_rsp, rsp.clone());
                `uvm_info (get_type_name(),{"got rsp", c_rsp.convert2string()},400);
                rspin_port.write(c_rsp);
            end else begin
                #1;
            end
        end : rsp_loop
    endtask: load_rspin

    task load_datin;
        dat_trans  dat = new(), c_dat;
        @(posedge clk_rst_if.arst_n);
        forever begin : dat_loop
            @(posedge clk_rst_if.clk);
            if (dat_if_i.rx.flit_v) begin
                dat.load_flit(dat_if_i.rx.flit);
                $cast(c_dat, dat.clone());
                `uvm_info (get_type_name(),{"got dat", c_dat.convert2string()},400);
                datin_port.write(c_dat);
            end else begin
                #1;
            end
        end : dat_loop
    endtask: load_datin

    task load_reqout;
        req_trans  req = new(), c_req;
        @(posedge clk_rst_if.arst_n);
        forever begin : req_loop
            @(posedge clk_rst_if.clk);
            if (req_if_o.rx.flit_v) begin
                req.load_flit(req_if_o.rx.flit);
                $cast(c_req, req.clone());
                `uvm_info (get_type_name(),{"got reqout", c_req.convert2string()},400);
                reqout_port.write(c_req);
            end else begin
                #1;
            end
        end : req_loop
    endtask: load_reqout

    task load_rspout;
        rsp_trans  rsp = new(), c_rsp;
        @(posedge clk_rst_if.arst_n);
        forever begin : rsp_loop
            @(posedge clk_rst_if.clk);
            if (rsp_if_o.rx.flit_v) begin
                rsp.load_flit(rsp_if_o.rx.flit);
                $cast(c_rsp, rsp.clone());
                `uvm_info (get_type_name(),{"got rspout", c_rsp.convert2string()},400);
                rspout_port.write(c_rsp);
            end else begin
                #1;
            end
        end : rsp_loop
    endtask: load_rspout

    task load_snpout;
        snp_trans  snp = new(), c_snp;
        @(posedge clk_rst_if.arst_n);
        forever begin : snp_loop
            @(posedge clk_rst_if.clk);
            if (snp_if_o.rx.flit_v) begin
                snp.load_flit(snp_if_o.rx.flit);
                $cast(c_snp, snp.clone());
                `uvm_info (get_type_name(),{"got snpout", c_snp.convert2string()},400);
                snpout_port.write(c_snp);
            end else begin
                #1;
            end
        end : snp_loop
    endtask: load_snpout

    task load_datout;
        dat_trans  dat = new(), c_dat;
        @(posedge clk_rst_if.arst_n);
        forever begin : dat_loop
            @(posedge clk_rst_if.clk);
            if (dat_if_o.rx.flit_v) begin
                dat.load_flit(dat_if_o.rx.flit);
                $cast(c_dat, dat.clone());
                `uvm_info (get_type_name(),{"got datout", c_dat.convert2string()},400);
                datout_port.write(c_dat);
            end else begin
                #1;
            end
        end : dat_loop
    endtask: load_datout

endclass : monitor
