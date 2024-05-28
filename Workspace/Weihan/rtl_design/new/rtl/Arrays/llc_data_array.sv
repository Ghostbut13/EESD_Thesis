module llc_data_array
import llc_config_pkg::*;
import llc_common_pkg::*; 
(
    input logic clk,
    input logic [LLC_INDEX_WIDTH-1:0] i_index,
    input logic wr_en,
    input logic [LLC_DATA_WIDTH-1:0] i_data,
    output logic [LLC_DATA_WIDTH-1:0] o_data
);

    logic [LLC_DATA_WIDTH-1:0] data_array [LLC_SET_NUM-1:0]; 

    always_ff @(posedge clk) begin
        if (wr_en) begin
            data_array[i_index] <= i_data; 
            o_data <= i_data; //forwarding 
        end else begin 
            o_data <= data_array[i_index]; 
        end 
    end

endmodule 