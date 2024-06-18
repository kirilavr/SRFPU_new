module rng #(parameter num_round_bits) 
(
    input logic clk,
    input logic resetn,
    input logic get_next_val,

    output logic[num_round_bits-1:0] out
);

    localparam start_state = 32'hACE1ACE1;

    logic[31:0]                lfsr_next;
    logic[31:0]                lfsr;
    logic[5:0]                 idx; // Increase the index width to accommodate larger range

    logic feedback;

    always_ff @(posedge clk or negedge resetn)
    begin 
        if(~resetn)
        begin
            lfsr <= start_state;
        end 
        else
        begin 
            if(get_next_val)
            begin 
                lfsr <= lfsr_next;
            end
        end
    end 

    always_comb
    begin
        lfsr_next = lfsr;

        for(idx = 0; idx < num_round_bits; idx++)
        begin
            // Use taps for a 32-bit LFSR: bits 32, 22, 2, and 1 (positions 31, 21, 1, and 0 in 0-based index)
            feedback  = lfsr_next[31] ^ lfsr_next[21] ^ lfsr_next[1] ^ lfsr_next[0];
            lfsr_next = {feedback, lfsr_next[31:1]};
        end

        out = lfsr_next[31:32-num_round_bits]; 
    end

endmodule