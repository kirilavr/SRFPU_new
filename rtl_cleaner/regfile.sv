//`timescale 1ns / 1ps

module regfile #(parameter num_bits) (
    input logic clk,                // Clock signal
    input logic rst,                // Reset signal
    input logic [4:0] read_addr1,   // Read address for port 1
    input logic [4:0] read_addr2,   // Read address for port 2
    input logic [4:0] write_addr,   // Write address
    input logic [num_bits-1:0] write_data,  // Data to write
    input logic write_enable,       // Write enable signal
    output logic [num_bits-1:0] read_data1, // Data read from port 1
    output logic [num_bits-1:0] read_data2  // Data read from port 2
);

    // 32 registers, each 32 bits wide
    logic [num_bits-1:0] reg_array [31:0];

    // Combinatorial read logic
    assign read_data1 = reg_array[read_addr1];
    assign read_data2 = reg_array[read_addr2];

    // Synchronous write logic
    always_ff @(posedge clk) begin
        if (write_enable) begin
            reg_array[write_addr] <= write_data;
        end
    end

    final 
    begin 
        $writememh("./testing/fpu_reg_dump.hex", reg_array);
    end


endmodule;