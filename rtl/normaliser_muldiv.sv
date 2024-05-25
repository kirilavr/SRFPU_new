module normaliser_muldiv #(parameter num_round_bits, parameter mant_width, parameter exp_width)
(
    input logic       [mant_width*2+1:0] unnorm_mant,
    input logic signed[exp_width+1:0]    unnorm_exp,

    output logic       [mant_width+num_round_bits-1:0] unrounded_mant, 
    output logic signed[exp_width+1:0]                 unrounded_exp
);

    always_comb 
    begin
        if(unnorm_mant[mant_width*2+1])
        begin 
            unrounded_mant = unnorm_mant[mant_width*2:mant_width-num_round_bits+1];
            unrounded_exp  = unnorm_exp+1;
        end
        else
        begin
            unrounded_mant = unnorm_mant[mant_width*2-1:mant_width-num_round_bits];
            unrounded_exp  = unnorm_exp;
        end
    end 

endmodule;