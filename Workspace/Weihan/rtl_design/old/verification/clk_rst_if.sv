import llc_hn_sim_pkg::*; 

interface clk_rst_interface; 

    logic clk; 
    logic arst_n; 

    // generate clock 
    initial begin 
        clk = 0; 
        forever begin 
            #HALF_CLK_P; 
            clk = ~clk; 
        end 
    end 

    // generate reset
    initial begin 
        arst_n = 0; 
        #HALF_CLK_P;
        arst_n = 1; 
    end 

endinterface: clk_rst_interface
