`timescale 1ns / 1ps

module TCAM_tb;

    // Define parameters
    parameter WIDTH = 33;
    
    // Inputs
    logic clk=1'b0;
    logic reset;
    logic [WIDTH-1:0] tag;
    logic [6:0] opcode;
    logic [6:0] NID;

    // Outputs
    logic [3:0] flag;

    // Instantiate the TCAM module
    TCAM #(WIDTH) dut (
        .clk(clk),
        .reset(reset),
        .tag(tag),
        .opcode(opcode),
        .NID(NID),
        .flag(flag)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Reset generation
    initial begin
        reset = 1'b1;
        #10 reset = 1'b0;
    end

    // Test stimulus
    initial begin
        // Wait for a few clock cycles before applying inputs
        #0;
        
        // Apply test vectors
        // Example test vectors, replace with your own test cases
        tag = 33'hABCDEFF;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_001; // RN1
        #20;
        
        tag = 33'h11223344;
        opcode = 7'b0000_111; // READ_UNIQUE
        NID = 7'b0000_010; // RN2
        #30;

        tag = 33'hABCDEFF;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_100; // RN3
        #30;
        // Add more test cases as needed
        tag = 33'h11223341;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_001; // RN3

        #30;
        tag = 33'h11223341;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0001_000; // RN3
        #30;

        tag = 33'h11223314;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_100; // RN3
        #30;

        tag = 33'h11223144;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_100; // RN3
        #30;
        tag = 33'h00000001;
        opcode = 7'b0000_001; // READ_SHARED
        NID = 7'b0000_100; // RN3
        #30;
        // Finish simulation after a while
        #1000;
        
    end

    // Monitor for displaying outputs
    always @(posedge clk) begin
        $display("tag = %h, opcode = %b, NID = %b, flag = %b", tag, opcode, NID, flag);
    end

endmodule