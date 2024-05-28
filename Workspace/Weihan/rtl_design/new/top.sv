//import uvm_pkg::*;
//import llc_hn_sim_pkg::*; 
import chi_package::*;
import llc_config_pkg::*; 
import llc_common_pkg::*; 
`timescale 1ns/10ps

module top;

    logic clk, rstn;
    chi_channel_inf #(request_flit_t)  req_noc2hn_if();
    chi_channel_inf #(response_flit_t) rsp_noc2hn_if();
    chi_channel_inf #(data_flit_t)     dat_noc2hn_if();
    chi_channel_inf #(request_flit_t)  req_hn2noc_if();
    chi_channel_inf #(response_flit_t) rsp_hn2noc_if();
    chi_channel_inf #(data_flit_t)     dat_hn2noc_if();
    chi_channel_inf #(snoop_flit_t)    snp_hn2noc_if();

    // Clock and reset generation
    initial begin
        clk = 1'b0;
        forever begin
            #10 clk = ~clk;
        end
    end

    initial begin
        rstn = 1'b1;
        #2 rstn = 1'b0;
        #4 rstn = 1'b1;
    end

    // DUT instantiation
    HN_controller HN(
        .clk(clk),
        .rstn(rstn),
        .rx_req(req_noc2hn_if.rx),
        .rx_rsp(rsp_noc2hn_if.rx),
        .rx_dat(dat_noc2hn_if.rx),
        .tx_req(req_hn2noc_if.tx), 
        .tx_rsp(rsp_hn2noc_if.tx), 
        .tx_dat(dat_hn2noc_if.tx),
        .tx_snp(snp_hn2noc_if.tx)
    );

    // Instantiate and run the driver
    driver drv;

    initial begin
        drv = new(req_noc2hn_if.rx, rsp_noc2hn_if.rx, dat_hn2noc_if.rx, clk);
        drv.run();
        #2000000 $stop;
    end

endmodule
