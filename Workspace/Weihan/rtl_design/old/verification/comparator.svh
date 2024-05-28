class comparator extends uvm_agent;

    `uvm_component_utils(comparator)

    uvm_tlm_analysis_fifo #(req_trans) predreqout_fifo;
    uvm_tlm_analysis_fifo #(rsp_trans) predrspout_fifo;
    uvm_tlm_analysis_fifo #(snp_trans) predsnpout_fifo;
    uvm_tlm_analysis_fifo #(dat_trans) preddatout_fifo;

    uvm_tlm_analysis_fifo #(req_trans) monreqout_fifo;
    uvm_tlm_analysis_fifo #(rsp_trans) monrspout_fifo;
    uvm_tlm_analysis_fifo #(snp_trans) monsnpout_fifo;
    uvm_tlm_analysis_fifo #(dat_trans) mondatout_fifo;

    int req_cnt; 
    int rsp_cnt; 
    int dat_cnt; 
    int snp_cnt; 

    function new (string name,
                uvm_component parent);
        super.new(name,parent);
    endfunction: new

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        predreqout_fifo    = new("predreqout_fifo",this);
        predrspout_fifo    = new("predrspout_fifo",this);
        predsnpout_fifo    = new("predsnpout_fifo",this);
        preddatout_fifo    = new("preddatout_fifo",this);

        monreqout_fifo    = new("monreqout_fifo",this);
        monrspout_fifo    = new("monrspout_fifo",this);
        monsnpout_fifo    = new("monsnpout_fifo",this);
        mondatout_fifo    = new("mondatout_fifo",this);
    endfunction: build_phase

    task run_phase(uvm_phase phase);
        `uvm_info (get_type_name(),{"run_phase comparator"},400);
        fork
              comp_req;
              comp_rsp;
              comp_snp;
              comp_dat;
        join
    endtask: run_phase

    task comp_req;
        req_trans predicted_req_out, actual_req_out;
        forever begin : run_loop

            monreqout_fifo.get(actual_req_out);
            `uvm_info(get_type_name(), actual_req_out.convert2string(),400);

            predreqout_fifo.get(predicted_req_out);
            `uvm_info(get_type_name(), predicted_req_out.convert2string(),400);

            if(actual_req_out.comp(predicted_req_out)) begin 
                req_cnt++; 
                `uvm_info(get_type_name(),
                              $psprintf("passed: %s",
                                        actual_req_out.convert2string()),500)
            end else begin 
              `uvm_fatal(get_type_name(),
                               $psprintf("ERROR REQ REFMODEL: %s \n DUT:%s",
                                         predicted_req_out.convert2string(),
                                         actual_req_out.convert2string()))
            end 
        end : run_loop;
    endtask

    task comp_rsp;
        rsp_trans predicted_rsp_out, actual_rsp_out;
        forever begin : run_loop

            monrspout_fifo.get(actual_rsp_out);
            `uvm_info(get_type_name(), actual_rsp_out.convert2string(),400);

            predrspout_fifo.get(predicted_rsp_out);
            `uvm_info(get_type_name(), predicted_rsp_out.convert2string(),400);

            if(actual_rsp_out.comp(predicted_rsp_out)) begin 
                rsp_cnt++; 
                `uvm_info(get_type_name(),
                              $psprintf("passed: %s",
                                        actual_rsp_out.convert2string()),500)
            end else begin 
              `uvm_fatal(get_type_name(),
                               $psprintf("ERROR RSP REFMODEL: %s \n DUT:%s",
                                         predicted_rsp_out.convert2string(),
                                         actual_rsp_out.convert2string()))
            end 
        end : run_loop;
    endtask

    task comp_snp;
        snp_trans predicted_snp_out, actual_snp_out;
        forever begin : run_loop

            monsnpout_fifo.get(actual_snp_out);
            `uvm_info(get_type_name(), actual_snp_out.convert2string(),400);

            predsnpout_fifo.get(predicted_snp_out);
            `uvm_info(get_type_name(), predicted_snp_out.convert2string(),400);

            if(actual_snp_out.comp(predicted_snp_out)) begin 
                snp_cnt++; 
                `uvm_info(get_type_name(),
                              $psprintf("passed: %s",
                                        actual_snp_out.convert2string()),500)
            end else begin 
              `uvm_fatal(get_type_name(),
                               $psprintf("ERROR SNP REFMODEL: %s \n DUT:%s",
                                         predicted_snp_out.convert2string(),
                                         actual_snp_out.convert2string()))
            end 
        end : run_loop;
    endtask

    task comp_dat;
        dat_trans predicted_dat_out, actual_dat_out;
        forever begin : run_loop

            mondatout_fifo.get(actual_dat_out);
            `uvm_info(get_type_name(), actual_dat_out.convert2string(),400);

            preddatout_fifo.get(predicted_dat_out);
            `uvm_info(get_type_name(), predicted_dat_out.convert2string(),400);

            if(actual_dat_out.comp(predicted_dat_out)) begin 
                dat_cnt++; 
              `uvm_info(get_type_name(),
                              $psprintf("passed: %s",
                                        actual_dat_out.convert2string()),500)
            end else begin 
              `uvm_fatal(get_type_name(),
                               $psprintf("ERROR DAT REFMODEL: %s \n DUT:%s",
                                         predicted_dat_out.convert2string(),
                                         actual_dat_out.convert2string()))
            end 
        end : run_loop;
    endtask
endclass: comparator
