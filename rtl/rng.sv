module rng #(parameter num_round_bits) 
(
    input logic clk,
    input logic reset,

    output logic[num_round_bits-1:0] out
);

    localparam start_state = 0'hACE1;

    logic[15:0]                lfsr_next;
    logic[15:0]                lfsr_inter;
    logic[15:0]                lfsr;
    logic[3:0]                 idx;

    logic feedback;

    always_ff @(posedge clk, posedge reset)
    begin 
        if(reset)
        begin
            lfsr <= start_state;
        end 
        else
        begin 
            lfsr <= lfsr_next;
        end
    end 


    always_comb
    begin
        lfsr_next = lfsr;

        for(idx = 0; idx<num_round_bits;idx++)
        begin
            feedback  = lfsr_next[15] ^ lfsr_next[13] ^ lfsr_next[12] ^ lfsr_next[10];
            lfsr_next = {feedback, lfsr_next[15:1]};
        end

        out = lfsr_next[15:16-num_round_bits]; 
    end
    

endmodule;



