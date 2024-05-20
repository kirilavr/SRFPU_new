module hp_round #(parameter num_round_bits, parameter num_bits, parameter mant_width)
(
    input logic                                stochastic,
    input logic[mant_width+num_round_bits-1:0] mantissa_in,
    input logic[num_round_bits-1:0]            rand_in,
      
    output logic[mant_width-1:0] rounded
);

    logic [mant_width+num_round_bits-1:0] mantissa;

    assign rounded = mantissa[num_round_bits + mant_width - 1:num_round_bits];

    always_comb 
    begin
        mantissa = mantissa_in;

        if(stochastic)
        begin 
            mantissa  += {{mant_width{1'b0}}, rand_in};
        end 

        else 
        begin 
            mantissa += {{(mant_width){1'b0}}, 1'b1, {(num_round_bits-1){1'b0}}};
        end
    end 

endmodule;