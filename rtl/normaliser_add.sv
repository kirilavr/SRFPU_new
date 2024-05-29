module normaliser_add #(parameter num_round_bits, parameter mant_width, parameter exp_width, parameter signed min_exp)
(
    input logic       [mant_width+num_round_bits+1:0] unnorm_mant,
    input logic signed[exp_width+1:0] unnorm_exp,
    input logic       [exp_width+1:0] lz,

    output logic signed[mant_width+num_round_bits+1:0] unrounded_mant, 
    output logic signed[exp_width+1:0] unrounded_exp
);

    always_comb 
    begin 

        if(unnorm_mant[mant_width+num_round_bits+1])
        begin 
            unrounded_mant = unnorm_mant>>1;
            unrounded_exp  = unnorm_exp + 1;
        end

        else if(unnorm_mant[mant_width+num_round_bits])
        begin 
            unrounded_mant = unnorm_mant;
            unrounded_exp  = unnorm_exp;
        end

        else 
        begin 
            if(lz < (unnorm_exp - min_exp))
            begin
                unrounded_mant = unnorm_mant<<(lz+1);
                unrounded_exp  = unnorm_exp-(lz+1);
            end 
            else 
            begin 
                unrounded_mant = unnorm_mant<<(unnorm_exp - min_exp);
                unrounded_exp  = min_exp-1;
            end
        end 
    end 

endmodule;