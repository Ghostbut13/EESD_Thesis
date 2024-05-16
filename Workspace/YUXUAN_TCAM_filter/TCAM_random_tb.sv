`timescale 1ns / 1ps

module TCAM_tb;

    // Define parameters
    parameter WIDTH = 33;
    //parameter WIDTH = 33;
    parameter NUM_TESTS = 70;
    parameter NID_COUNT = 4;
    parameter opcode_COUNT=3;
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
    integer i;
    integer file;
    string line;
    logic [6:0] NID_values [NID_COUNT-1:0] = '{7'b0000_001, 7'b0000_010, 7'b0000_100, 7'b0001_000};
    logic [6:0] opcode_values [opcode_COUNT-1:0] = '{7'b0000_001, 7'b0000_111, 7'b0011_011};
    automatic int count = 0; // Explicitly declare count as automatic

    // Open the file for reading
    file = $fopen("33bit_numbers.txt", "r");
    if (file == 0) begin
        $display("Failed to open file 33bit_numbers.txt");
        $finish;
    end

    // Wait for a few clock cycles before applying inputs
    //#20;

    // Read lines from file and apply as tags
    while (!$feof(file) && count < NUM_TESTS) begin
        line = "";
        void'($fgets(line, file));

        // Remove newline characters if present
        if (line.len() > 0 && line[line.len()-1] == "\n") line = line.substr(0, line.len()-1);
        if (line.len() > 0 && line[line.len()-1] == "\r") line = line.substr(0, line.len()-1);

        // Convert the string to a 33-bit binary number
        tag = 'b0;
        for (i = 0; i < WIDTH; i = i + 1) begin
            if (line[i] == "1") begin
                tag[WIDTH-1-i] = 1'b1;
            end else begin
                tag[WIDTH-1-i] = 1'b0;
            end
        end

        opcode = opcode_values[$urandom % opcode_COUNT]; // Example opcode, adjust as needed
        NID = NID_values[$urandom % NID_COUNT]; // Randomly select one of the four NID values
        #30; // Wait for a few cycles before next test
        count++;
    end

    // Close the file
    $fclose(file);

    // Finish simulation after a while
    #1000;
    end
    // Monitor for displaying outputs
    always @(posedge clk) begin
        $display("tag = %h, opcode = %b, NID = %b, flag = %b", tag, opcode, NID, flag);
    end

endmodule