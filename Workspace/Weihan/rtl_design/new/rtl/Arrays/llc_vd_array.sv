module llc_vd_array
import llc_config_pkg::*;
import llc_common_pkg::*; 
(
    input logic clk,
    input logic arst_n, 
    input logic [LLC_INDEX_WIDTH-1:0] rd_index,
    input logic [LLC_INDEX_WIDTH-1:0] wr_index, 
    input logic wr_en, 
    input logic rd_en, 
    input logic [1:0] i_vd, 
    output logic [1:0] o_vd
);
    
    logic [1:0] vd_array [LLC_SET_NUM-1:0]; 

    always_ff @(posedge clk or negedge arst_n) begin
        if (!arst_n) begin 
            vd_array <= '{default:2'b00};
        end else if (wr_en) begin 
            vd_array[wr_index] <= i_vd; 
        end 
    end

    always_ff @(posedge clk) begin
        if (rd_en) begin 
            o_vd <= vd_array[rd_index]; 
        end
    end

    // =============== Assertions =============== 

    assert 
        property(
            @(posedge clk) disable iff(!arst_n)
            !(wr_en && rd_en && (rd_index == wr_index))
        );

endmodule 