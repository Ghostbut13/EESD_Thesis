module llc_tag_array
import llc_config_pkg::*;
import llc_common_pkg::*; 
(
    input logic clk,
    input logic arst_n,  
    input logic [LLC_INDEX_WIDTH-1:0] rd_index,
    input logic [LLC_INDEX_WIDTH-1:0] wr_index, 
    input logic wr_en, 
    input logic rd_en,
    input logic [LLC_TAG_WIDTH-1:0] i_tag, 
    output logic [LLC_TAG_WIDTH-1:0] o_tag
);

    logic [LLC_TAG_WIDTH-1:0] tag_array [LLC_SET_NUM-1:0]; 

    always_ff @(posedge clk) begin
        if (wr_en) begin 
            tag_array[wr_index] <= i_tag; 
        end 
    end

    always_ff @(posedge clk) begin
        if (rd_en) begin 
            o_tag <= tag_array[rd_index]; 
        end
    end

    assert 
        property(
            @(posedge clk) disable iff(!arst_n)
            !(wr_en && rd_en && (rd_index == wr_index)) 
        );

endmodule 